// k6 load & adversarial test for ArabiLogia
// Run with: k6 run -e SUPABASE_ANON_KEY=your_key loadtest.js
//
// Modes:
//   k6 run loadtest.js                          (default: leaderboard + auth spam)
//   k6 run -e TEST_MODE=signup loadtest.js       (mass account registration)
//   k6 run -e TEST_MODE=login loadtest.js        (credential stuffing)
//   k6 run -e TEST_MODE=results loadtest.js      (fake exam submission spam)
//   k6 run -e TEST_MODE=idor loadtest.js         (IDOR data scraping)
//   k6 run -e TEST_MODE=all loadtest.js          (everything above)

import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend } from 'k6/metrics';
import { randomString } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';

const SUPABASE_URL = 'https://bpqagpspfaevdxsmsubv.supabase.co';
const ANON_KEY = __ENV.SUPABASE_ANON_KEY || '';
const TEST_MODE = __ENV.TEST_MODE || 'default';

const failureRate = new Rate('request_failures');
const responseTime = new Trend('request_duration');

export const options = {
  stages: TEST_MODE === 'default' ? [
    { duration: '30s', target: 20 },
    { duration: '1m', target: 100 },
    { duration: '2m', target: 100 },
    { duration: '30s', target: 0 },
  ] : [
    { duration: '10s', target: 5 },    // quick ramp
    { duration: '30s', target: 20 },   // hold
    { duration: '10s', target: 0 },
  ],
  thresholds: {
    request_failures: ['rate<0.10'],
    http_req_duration: ['p(99)<8000'],
  },
};

function track(res, name) {
  responseTime.add(res.timings.duration, { name });
  failureRate.add(res.status !== 200, { name });
  check(res, {
    [`${name} status`]: (r) => true, // track all statuses
  });
}

// ─── Attack: Mass Signup ─────────────────────────────────────────────
function attackSignup() {
  group('mass signup', () => {
    const email = `bot-${randomString(8)}@attacker.tld`;
    const res = http.post(`${SUPABASE_URL}/auth/v1/signup`, JSON.stringify({
      email: email,
      password: 'BotTest123!',
      data: { full_name: 'Bot Attacker', username: `bot_${randomString(6)}`, grade: 10 },
    }), {
      headers: {
        'apikey': ANON_KEY,
        'Content-Type': 'application/json',
      },
    });
    track(res, 'signup');
    // 429 = rate limited => good (attack blocked)
    // 200 = user created => vulnerable
    check(res, {
      'signup blocked (429)': (r) => r.status === 429,
      'signup rejected (422)': (r) => r.status === 422,
    });
  });
}

// ─── Attack: Credential Stuffing ─────────────────────────────────────
function attackLogin() {
  group('credential stuffing', () => {
    const email = `fake-${randomString(6)}@test.com`;
    const res = http.post(`${SUPABASE_URL}/auth/v1/token?grant_type=password`, JSON.stringify({
      email: email,
      password: randomString(12),
    }), {
      headers: {
        'apikey': ANON_KEY,
        'Content-Type': 'application/json',
      },
    });
    track(res, 'login');
    check(res, {
      'login blocked (429)': (r) => r.status === 429,
      'login rejected (400)': (r) => r.status === 400,
    });
  });
}

// ─── Attack: Fake Exam Results ───────────────────────────────────────
function attackResults() {
  group('fake exam results', () => {
    const res = http.post(`${SUPABASE_URL}/rest/v1/exam_results`, JSON.stringify({
      user_id: '00000000-0000-0000-0000-000000000000',
      exam_id: `nahw-${Math.floor(Math.random() * 10)}`,
      score: 100,
      subject: 'nahw',
      status: 'completed',
      points: 1000,
    }), {
      headers: {
        'apikey': ANON_KEY,
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      },
    });
    track(res, 'exam_results');
    check(res, {
      'results rejected (401/403)': (r) => r.status === 401 || r.status === 403,
      'results blocked (429)': (r) => r.status === 429,
    });
  });
}

// ─── Attack: IDOR Data Scraping ──────────────────────────────────────
function attackIdor() {
  group('IDOR scraping', () => {
    const endpoints = [
      { path: '/rest/v1/profiles?select=id,full_name,username,role,email', name: 'profiles' },
      { path: '/rest/v1/exam_results?select=*', name: 'exam_results' },
      { path: '/rest/v1/reports?select=*', name: 'reports' },
      { path: '/rest/v1/exams?select=id,title,data', name: 'exams' },
    ];
    for (const ep of endpoints) {
      const res = http.get(`${SUPABASE_URL}${ep.path}`, {
        headers: {
          'apikey': ANON_KEY,
          'Accept': 'application/json',
        },
      });
      track(res, ep.name);
      let leaked = 0;
      try { leaked = JSON.parse(res.body).length; } catch {}
      check(res, {
        [`${ep.name} blocked (empty)`]: (r) => leaked === 0,
      });
    }
  });
}

export default function () {
  switch (TEST_MODE) {
    case 'signup':
      attackSignup();
      break;
    case 'login':
      attackLogin();
      break;
    case 'results':
      attackResults();
      break;
    case 'idor':
      attackIdor();
      break;
    case 'all':
      attackSignup();
      attackLogin();
      attackResults();
      attackIdor();
      break;
    default:
      // Original leaderboard test + light auth spam
      const period = ['all', 'week', 'month'][Math.floor(Math.random() * 3)];
      const payload = JSON.stringify({ period_filter: period });
      const res = http.post(`${SUPABASE_URL}/rest/v1/rpc/get_leaderboard_by_period`, payload, {
        headers: {
          'Content-Type': 'application/json',
          'apikey': ANON_KEY,
          'Authorization': `Bearer ${ANON_KEY}`,
        },
      });
      track(res, `leaderboard_${period}`);
      break;
  }

  sleep(Math.random() * 1.8 + 0.2);
}
