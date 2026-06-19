// k6 load test for ArabiLogia leaderboard
// Run with: k6 run -e SUPABASE_ANON_KEY=your_key loadtest.js
//
// Options:
//   k6 run loadtest.js                           (default: 50 virtual users)
//   k6 run -e SUPABASE_ANON_KEY=key loadtest.js   (with API key)
//   k6 run --vus 200 --duration 30s loadtest.js   (200 users for 30s)

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const SUPABASE_URL = 'https://bpqagpspfaevdxsmsubv.supabase.co';
const ANON_KEY = __ENV.SUPABASE_ANON_KEY || '';

const failureRate = new Rate('leaderboard_failures');
const responseTime = new Trend('leaderboard_duration');

export const options = {
  stages: [
    { duration: '30s', target: 20 },   // warm-up
    { duration: '1m', target: 100 },   // ramp to 100 concurrent
    { duration: '2m', target: 100 },   // hold at 100
    { duration: '30s', target: 0 },    // ramp down
  ],
  thresholds: {
    leaderboard_failures: ['rate<0.05'],        // < 5% errors
    leaderboard_duration: ['p(95)<3000'],       // 95% under 3s
    http_req_duration: ['p(99)<5000'],          // 99% under 5s
  },
};

function getLeaderboard(period) {
  const payload = JSON.stringify({ period_filter: period });
  const url = `${SUPABASE_URL}/rest/v1/rpc/get_leaderboard_by_period`;

  const res = http.post(url, payload, {
    headers: {
      'Content-Type': 'application/json',
      'apikey': ANON_KEY,
      'Authorization': `Bearer ${ANON_KEY}`,
      'Accept': 'application/json',
    },
    tags: { period },
  });

  responseTime.add(res.timings.duration);
  failureRate.add(res.status !== 200);

  check(res, {
    [`${period} status 200`]: (r) => r.status === 200,
    [`${period} body is array`]: (r) => {
      try {
        return Array.isArray(JSON.parse(r.body));
      } catch { return false; }
    },
  });

  return res;
}

export default function () {
  // Simulate different students hitting different leaderboard periods
  const period = ['all', 'week', 'month'][Math.floor(Math.random() * 3)];

  getLeaderboard(period);

  // Think time: simulate real user browsing (200ms-2s)
  sleep(Math.random() * 1.8 + 0.2);
}
