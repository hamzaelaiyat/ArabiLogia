#!/usr/bin/env node
/*
 * API integration test harness for ArabiLogia.
 * Runs read-only (plus a temporary points-adjustment cycle on test users)
 * checks against the live Supabase project using anon + test-user JWTs.
 *
 * Usage:
 *   node scripts/api-test.js [path-to-test-users.json]
 *
 * The test-users JSON must look like:
 *   [
 *     {"email":"...","password":"...","role":"student","grade":2},
 *     {"email":"...","password":"...","role":"admin"}
 *   ]
 *
 * .env is parsed for SUPABASE_URL and SUPABASE_ANON_KEY.
 */

import { readFileSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

function loadEnv() {
  const path = join(root, '.env');
  if (!existsSync(path)) {
    console.error('FATAL: .env not found. Cannot resolve API base url/key.');
    process.exit(1);
  }
  const env = {};
  for (const line of readFileSync(path, 'utf8').split('\n')) {
    const m = line.match(/^\s*([A-Za-z0-9_]+)\s*=\s*(.*)\s*$/);
    if (!m) continue;
    env[m[1]] = m[2].replace(/^["']|["']$/g, '');
  }
  return env;
}

const env = loadEnv();
const BASE = (env.SUPABASE_URL || '').replace(/\/$/, '');
const ANON_KEY = env.SUPABASE_ANON_KEY;

if (!BASE || !ANON_KEY) {
  console.error('FATAL: SUPABASE_URL / SUPABASE_ANON_KEY missing from .env');
  process.exit(1);
}

const usersArg = process.argv[2] || 'test-users.json';
const usersPath = existsSync(usersArg)
  ? usersArg
  : join(root, 'scripts', usersArg);
const TEST_USERS = JSON.parse(readFileSync(usersPath, 'utf8'));

let passed = 0;
let failed = 0;
const failures = [];

function ok(label) {
  passed++;
  console.log(`  PASS  ${label}`);
}

function bad(label, detail) {
  failed++;
  failures.push(label);
  console.log(`  FAIL  ${label}\n        ${String(detail).split('\n').join('\n        ')}`);
}

async function api(path, { method = 'GET', token, body } = {}) {
  const headers = {
    apikey: ANON_KEY,
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    Accept: 'application/json',
  };
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    json = text;
  }
  return { status: res.status, json };
}

async function login(user) {
  const { status, json } = await api('/auth/v1/token?grant_type=password', {
    method: 'POST',
    body: { email: user.email, password: user.password },
  });
  return { status, json };
}

const expectFailure = (status, json) =>
  status >= 400 || json?.code || json?.error || json?.message;

async function run() {
  console.log(`\nTarget: ${BASE}`);

  // ---- Anon (no token) ----
  console.log('\n[anon] public reads');
  {
    const r = await api('/rest/v1/grades?select=id,name,sort_order,is_active&order=sort_order');
    if (r.status !== 200 || !Array.isArray(r.json)) {
      bad('anon can read grades', `status=${r.status} body=${JSON.stringify(r.json)}`);
    } else {
      const ids = r.json.map((g) => g.id).sort();
      const gradesOk = JSON.stringify(ids) === JSON.stringify([1, 2, 3]);
      const namesOk = r.json.every((g) => typeof g.name === 'string' && g.name.length > 0);
      if (gradesOk && namesOk) {
        ok(`anon can read grades (ids=${ids.join(',')}, names present)`);
      } else {
        bad('anon grades content correct', `ids=${ids} namesOk=${namesOk}`);
      }
    }
  }
  for (const [table, filter] of [
    ['exams', 'select=id,title'],
    ['categories', 'select=id,name,is_active'],
    ['lectures', 'select=id,title,grade'],
  ]) {
    const r = await api(`/rest/v1/${table}?${filter}`);
    if (r.status === 200 && Array.isArray(r.json)) {
      ok(`anon can read ${table}`);
    } else {
      bad(`anon can read ${table}`, `status=${r.status} body=${JSON.stringify(r.json)}`);
    }
  }
  {
    const r = await api('/rest/v1/profiles?select=id,full_name,grade');
    const leak = r.status === 200 && Array.isArray(r.json) && r.json.length > 0;
    if (!leak) {
      ok('anon cannot list profiles (no leak)');
    } else {
      bad('anon cannot list profiles', `anon saw ${r.json.length} rows`);
    }
  }

  console.log('\n[anon] protected RPCs must be rejected');
  for (const [name, body] of [
    ['get_students_with_balances', { p_grade: 2 }],
    ['adjust_student_points', { p_user_id: '00000000-0000-0000-0000-000000000000', p_amount: 1, p_action: 'increment' }],
  ]) {
    const r = await api('/rest/v1/rpc/' + name, { method: 'POST', body });
    if (expectFailure(r.status, r.json)) {
      ok(`anon blocked from ${name} (status=${r.status})`);
    } else {
      bad(`anon blocked from ${name}`, `status=${r.status} body=${JSON.stringify(r.json)}`);
    }
  }

  // ---- Per-user authenticated checks ----
  const byRole = (role) => TEST_USERS.filter((u) => u.role === role);
  const students = byRole('student');
  const admins = byRole('admin');

  if (students.length < 1 || admins.length < 1) {
    console.error('\nFATAL: need at least one student and one admin test user');
    process.exit(2);
  }

  const student = students[0];
  const admin = admins[0];
  const sessions = {};

  console.log('\n[auth] login');
  for (const u of [student, ...admins]) {
    const { status, json } = await login(u);
    if (status === 200 && json?.access_token) {
      sessions[u.email] = json.access_token;
      sessions[u.email + ':uid'] = json.user?.id;
      const metaGrade = json.user?.user_metadata?.grade;
      if (u.role === 'student') {
        if (metaGrade === u.grade) {
          ok(`login ${u.email} (grade ${metaGrade})`);
        } else {
          bad(`login ${u.email} grade metadata`, `got ${metaGrade}`);
        }
      } else {
        ok(`login ${u.email} (${u.role})`);
      }
    } else {
      bad(`login ${u.email}`, `status=${status} body=${JSON.stringify(json)}`);
    }
  }
  const st = sessions[student.email];
  const stUid = sessions[student.email + ':uid'];
  const ad = sessions[admin.email];
  const adUid = sessions[admin.email + ':uid'];

  console.log('\n[student] own data');
  {
    const url = `/rest/v1/profiles?id=eq.${stUid}&select=id,full_name,grade,role`;
    const r = await api(url, { token: st });
    if (r.status === 200 && Array.isArray(r.json) && r.json.length === 1 && r.json[0].grade === student.grade) {
      ok(`student reads own profile (grade ${student.grade})`);
    } else {
      bad('student reads own profile', `status=${r.status} body=${JSON.stringify(r.json)}`);
    }
  }
  {
    const r = await api(`/rest/v1/exam_results?user_id=eq.${stUid}&select=id,score,status`);
    if (r.status === 200 && Array.isArray(r.json)) {
      ok(`student reads own exam_results (${r.json.length} rows)`);
    } else {
      bad('student reads own exam_results', `status=${r.status} body=${JSON.stringify(r.json)}`);
    }
  }
  {
    const otherUid = admins[0] && admins[0] === admin ? adUid : null;
    if (otherUid) {
      const r = await api(`/rest/v1/exam_results?user_id=eq.${otherUid}&select=id,score`);
      const leaked = r.status === 200 && Array.isArray(r.json) && r.json.length > 0;
      if (!leaked) {
        ok('student cannot read other users exam_results');
      } else {
        bad('student cannot read other users exam_results', `got ${r.json.length} rows`);
      }
    }
  }
  {
    const r = await api(`/rest/v1/points_adjustments?user_id=eq.${stUid}&select=id,amount`);
    if (r.status === 200 && Array.isArray(r.json)) {
      ok(`student reads own adjustments (${r.json.length} rows)`);
    } else {
      bad('student reads own adjustments', `status=${r.status} body=${JSON.stringify(r.json)}`);
    }
  }
  {
    const r = await api(`/rest/v1/lectures?grade=eq.${student.grade}&is_published=eq.true&select=id,title,grade`);
    if (r.status === 200 && Array.isArray(r.json) && r.json.every((l) => l.grade === student.grade)) {
      ok(`student reads published lectures for grade ${student.grade} (${r.json.length} rows)`);
    } else {
      bad('student reads published lectures', `status=${r.status} body=${JSON.stringify(r.json)}`);
    }
  }

  console.log('\n[student] protected RPCs must be rejected');
  for (const [name, body] of [
    ['get_students_with_balances', { p_grade: student.grade }],
    ['adjust_student_points', { p_user_id: stUid, p_amount: 5, p_action: 'increment' }],
  ]) {
    const r = await api('/rest/v1/rpc/' + name, { method: 'POST', token: st, body });
    if (expectFailure(r.status, r.json)) {
      ok(`student blocked from ${name} (status=${r.status})`);
    } else {
      bad(`student blocked from ${name}`, `status=${r.status} body=${JSON.stringify(r.json)}`);
    }
  }

  console.log('\n[get_all_user_results] ownership enforced');
  {
    const r = await api('/rest/v1/rpc/get_all_user_results', {
      method: 'POST', token: st, body: { p_user_id: stUid },
    });
    if (r.status === 200 && Array.isArray(r.json)) {
      ok('student reads own results via get_all_user_results');
    } else {
      bad('student reads own results via get_all_user_results', `status=${r.status} body=${JSON.stringify(r.json)}`);
    }
  }
  {
    const r = await api('/rest/v1/rpc/get_all_user_results', {
      method: 'POST', token: st, body: { p_user_id: adUid },
    });
    if (expectFailure(r.status, r.json)) {
      ok(`student blocked from another user results (status=${r.status})`);
    } else {
      bad('student blocked from another user results', `status=${r.status} body=${JSON.stringify(r.json)}`);
    }
  }
  {
    const r = await api('/rest/v1/rpc/get_all_user_results', {
      method: 'POST', body: { p_user_id: adUid },
    });
    if (expectFailure(r.status, r.json)) {
      ok(`anon blocked from get_all_user_results (status=${r.status})`);
    } else {
      bad('anon blocked from get_all_user_results', `status=${r.status} body=${JSON.stringify(r.json)}`);
    }
  }

  console.log('\n[admin] leaderboard');
  {
    const r = await api('/rest/v1/rpc/get_students_with_balances', {
      method: 'POST', token: ad, body: { p_grade: student.grade },
    });
    if (r.status === 200 && Array.isArray(r.json)) {
      const allMatch = r.json.every((row) => row.grade === student.grade);
      const hasTestUser = r.json.some((row) => row.user_id === stUid);
      if (allMatch && hasTestUser) {
        ok(`admin leaderboard filtered by grade ${student.grade} (${r.json.length} students)`);
      } else {
        bad('admin leaderboard grade filter', `allMatch=${allMatch} hasTestUser=${hasTestUser} rows=${r.json.length}`);
      }
    } else {
      bad('admin leaderboard', `status=${r.status} body=${JSON.stringify(r.json)}`);
    }
  }
  {
    const r = await api('/rest/v1/rpc/get_students_with_balances', {
      method: 'POST', token: ad, body: { p_grade: 0 },
    });
    if (r.status === 200 && Array.isArray(r.json) && r.json.length > 0) {
      ok('admin leaderboard all grades');
    } else {
      bad('admin leaderboard all grades', `status=${r.status} body=${JSON.stringify(r.json)}`);
    }
  }

  console.log('\n[admin] points adjustment cycle');
  let balance = null;
  {
    const r = await api('/rest/v1/rpc/adjust_student_points', {
      method: 'POST', token: ad,
      body: { p_user_id: stUid, p_amount: 10, p_action: 'increment' },
    });
    if (r.status === 200 && Array.isArray(r.json) && r.json[0]?.new_balance > 0) {
      balance = r.json[0].new_balance;
      ok(`admin increments points (new_balance=${balance})`);
    } else {
      bad('admin increments points', `status=${r.status} body=${JSON.stringify(r.json)}`);
    }
  }
  {
    const r = await api('/rest/v1/rpc/adjust_student_points', {
      method: 'POST', token: ad,
      body: { p_user_id: stUid, p_amount: 3, p_action: 'decrement' },
    });
    if (r.status === 200 && Array.isArray(r.json)) {
      const nb = r.json[0]?.new_balance;
      if (balance !== null && typeof nb === 'number' && nb === balance - 3) {
        ok(`admin decrements points (${balance} -> ${nb})`);
      } else {
        bad('admin decrements points', `expected ${balance}-3, got ${nb}`);
      }
    } else {
      bad('admin decrements points', `status=${r.status} body=${JSON.stringify(r.json)}`);
    }
  }
  {
    const r = await api('/rest/v1/rpc/adjust_student_points', {
      method: 'POST', token: ad,
      body: { p_user_id: stUid, p_amount: 0, p_action: 'reset' },
    });
    if (r.status === 200 && Array.isArray(r.json) && r.json[0]?.new_balance === 0) {
      ok('admin resets points (new_balance=0)');
    } else {
      bad('admin resets points', `status=${r.status} body=${JSON.stringify(r.json)}`);
    }
  }
  {
    const r = await api('/rest/v1/rpc/adjust_student_points', {
      method: 'POST', token: ad,
      body: {
        p_user_id: '00000000-0000-0000-0000-000000000000',
        p_amount: 1, p_action: 'increment',
      },
    });
    if (r.status === 400) {
      ok('admin adjustment rejected for missing student (status=400)');
    } else {
      bad('admin adjustment rejected for missing student', `status=${r.status} body=${JSON.stringify(r.json)}`);
    }
  }

  console.log('\n[edge functions]');
  {
    const r = await api('/functions/v1/hcaptcha-challenge');
    if (r.status === 200 && typeof r.json === 'string' && r.json.includes('h-captcha')) {
      ok('hcaptcha-challenge serves HTML');
    } else {
      bad('hcaptcha-challenge', `status=${r.status}`);
    }
  }
  {
    const r = await api('/functions/v1/auth-before-signup', { method: 'POST', body: { email: 'x@x.com' } });
    if (expectFailure(r.status, r.json)) {
      ok(`auth-before-signup rejects request without captcha token (status=${r.status})`);
    } else {
      bad('auth-before-signup rejects without captcha', `status=${r.status} body=${JSON.stringify(r.json)}`);
    }
  }

  console.log(`\n===== SUMMARY =====`);
  console.log(`passed: ${passed}   failed: ${failed}`);
  if (failures.length) {
    console.log('failed checks:');
    failures.forEach((f) => console.log(`  - ${f}`));
  }
  process.exit(failed === 0 ? 0 : 1);
}

run().catch((e) => {
  console.error('harness crashed:', e);
  process.exit(1);
});
