#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# ArabiLogia Bot Adversarial Testing Suite
# =============================================================================
# Usage:
#   export SUPABASE_ANON_KEY="your_anon_key"
#   ./scripts/bot-test.sh              # run all tests
#   ./scripts/bot-test.sh auth          # run only auth tests
#   ./scripts/bot-test.sh enum          # run only enumeration tests
#   ./scripts/bot-test.sh inject        # run only injection/schema tests
#   ./scripts/bot-test.sh spam          # run only spam/abuse tests
#   ./scripts/bot-test.sh scrape        # run only data scraping tests
#
# Each test prints:  PASS | FAIL | BLOCKED (meaning the app rejected the attack)
# =============================================================================

SUPABASE_URL="https://bpqagpspfaevdxsmsubv.supabase.co"
ANON_KEY="${SUPABASE_ANON_KEY:?Set SUPABASE_ANON_KEY}"

PASS=0
FAIL=0
BLOCKED=0

pass()   { echo "  ✅ PASS: $1";   ((PASS++)); }
fail()   { echo "  ❌ FAIL: $1";   ((FAIL++)); }
blocked(){ echo "  🛡️  BLOCKED: $1"; ((BLOCKED++)); }

header() { echo ""; echo "══════════════════════════════════════════════"; echo "  $1"; echo "══════════════════════════════════════════════"; }

# ─── Auth Tests ───────────────────────────────────────────────────────────

test_mass_signup() {
  header "MASS SIGNUP (5 rapid registrations)"
  local count=0
  for i in $(seq 1 5); do
    local email="bot-test-$(date +%s)-$i@tempmail.com"
    local code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$SUPABASE_URL/auth/v1/signup" \
      -H "apikey: $ANON_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"email\":\"$email\",\"password\":\"BotTest123!\"}")
    # 200 = user created (vulnerable), 4xx = blocked (protected)
    if [[ "$code" == "400" || "$code" == "401" || "$code" == "403" || "$code" == "422" || "$code" == "429" ]]; then
      ((count++))
    fi
  done
  [[ "$count" -ge 3 ]] && blocked "Mass signup — got $count blocks out of 5" || fail "Mass signup — only $count blocks out of 5"
}

test_credential_stuffing() {
  header "CREDENTIAL STUFFING (10 rapid failed logins)"
  local count=0
  for i in $(seq 1 10); do
    local code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
      -H "apikey: $ANON_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"email\":\"fake@bot-test-$i.com\",\"password\":\"WrongPass$i!\"}")
    [[ "$code" == "400" || "$code" == "401" || "$code" == "403" || "$code" == "429" ]] && ((count++))
  done
  [[ "$count" -ge 5 ]] && blocked "Credential stuffing — got $count blocks out of 10" || fail "Credential stuffing — only $count blocks out of 10"
}

test_invalid_email_signup() {
  header "INVALID EMAIL SIGNUP (SQLi attempt in email)"
  local body=$(curl -s -X POST "$SUPABASE_URL/auth/v1/signup" \
    -H "apikey: $ANON_KEY" \
    -H "Content-Type: application/json" \
    -d '{"email":"'\'' OR 1=1 --@test.com","password":"Test123!"}')
  local code=$(echo "$body" | python3 -c "import sys,json; print(json.load(sys.stdin).get('code', 400))" 2>/dev/null || echo "400")
  [[ "$code" -ge 400 ]] && blocked "SQLi in email rejected (code $code)" || fail "SQLi in email might have passed"
}

# ─── Enumeration Tests ────────────────────────────────────────────────────

test_user_enumeration() {
  header "USER ENUMERATION (check if emails can be guessed)"
  # Try signup with existing email — 422 means email exists
  local code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$SUPABASE_URL/auth/v1/signup" \
    -H "apikey: $ANON_KEY" \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@arabilogia.com","password":"Test123!"}')
  # 200 = user created (NOT vulnerable), 422 = email exists (vulnerable to enum)
  if [[ "$code" == "200" ]]; then
    pass "User enumeration — email not revealed (new user created)"
  elif [[ "$code" == "422" ]]; then
    fail "User enumeration — email existence revealed"
  else
    pass "User enumeration — got code $code (ambiguous)"
  fi
}

test_idor_profiles() {
  header "IDOR — LIST ALL PROFILES WITHOUT AUTH"
  local body=$(curl -s "$SUPABASE_URL/rest/v1/profiles?select=id,full_name,username,role" \
    -H "apikey: $ANON_KEY")
  local count=$(echo "$body" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d) if isinstance(d,list) else 0)" 2>/dev/null || echo "0")
  [[ "$count" -eq 0 ]] && blocked "IDOR — no profiles leaked without auth ($count returned)" || fail "IDOR — $count profiles leaked without auth!"
}

test_idor_exam_results() {
  header "IDOR — LIST ALL EXAM RESULTS WITHOUT AUTH"
  local body=$(curl -s "$SUPABASE_URL/rest/v1/exam_results?select=*" \
    -H "apikey: $ANON_KEY")
  local count=$(echo "$body" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d) if isinstance(d,list) else 0)" 2>/dev/null || echo "0")
  [[ "$count" -eq 0 ]] && blocked "IDOR — no exam results leaked ($count returned)" || fail "IDOR — $count exam results leaked!"
}

test_idor_reports() {
  header "IDOR — LIST ALL REPORTS WITHOUT AUTH"
  local body=$(curl -s "$SUPABASE_URL/rest/v1/reports?select=*" \
    -H "apikey: $ANON_KEY")
  local count=$(echo "$body" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d) if isinstance(d,list) else 0)" 2>/dev/null || echo "0")
  [[ "$count" -eq 0 ]] && blocked "IDOR — no reports leaked ($count returned)" || fail "IDOR — $count reports leaked!"
}

# ─── Injection Tests ──────────────────────────────────────────────────────

test_sqli_rpc() {
  header "SQL INJECTION — RPC call with SQLi payload"
  local body=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/get_leaderboard_by_period" \
    -H "apikey: $ANON_KEY" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ANON_KEY" \
    -d '{"period_filter":"all; DROP TABLE profiles CASCADE --"}')
  local code=$(echo "$body" | python3 -c "import sys,json; print(json.load(sys.stdin).get('code', ''))" 2>/dev/null || echo "parse error")
  [[ "$code" == "400" || "$code" == "500" ]] && blocked "SQLi in RPC rejected (code $code)" || fail "SQLi in RPC might have passed: $(echo "$body" | head -c 100)"
}

test_json_injection_exam_results() {
  header "JSON INJECTION — exam_results with extra fields"
  local body=$(curl -s -X POST "$SUPABASE_URL/rest/v1/exam_results" \
    -H "apikey: $ANON_KEY" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=minimal" \
    -d '{"user_id":"00000000-0000-0000-0000-000000000000","exam_id":"__test__","score":100,"subject":"nahw","role":"admin"}')
  local code=$(echo "$body" | python3 -c "import sys,json; print(json.load(sys.stdin).get('code', '201'))" 2>/dev/null || echo "201")
  [[ "$code" -ge 400 ]] && blocked "Extra fields rejected (code $code)" || fail "Extra fields might have been accepted"
}

# ─── Spam / Abuse Tests ───────────────────────────────────────────────────

test_spam_leaderboard_rpc() {
  header "SPAM — RAPID LEADERBOARD CALLS (50 in parallel)"
  local start=$SECONDS
  local fail_count=0
  for i in $(seq 1 50); do
    local code=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
      "$SUPABASE_URL/rest/v1/rpc/get_leaderboard_by_period" \
      -H "apikey: $ANON_KEY" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $ANON_KEY" \
      -d '{"period_filter":"all"}' &
    )
    [[ "$code" != "200" ]] && ((fail_count++)) || true
  done
  wait
  local elapsed=$((SECONDS - start))
  [[ "$fail_count" -gt 10 ]] && blocked "Leaderboard spam — $fail_count failures out of 50 (possible rate limiting)" && return
  pass "Leaderboard spam — only $fail_count failures out of 50 (all $elapsed secs)"
}

# ─── Data Scraping Tests ──────────────────────────────────────────────────

test_scrape_exams() {
  header "SCRAPE — LIST ALL EXAMS WITHOUT AUTH"
  local body=$(curl -s "$SUPABASE_URL/rest/v1/exams?select=*" \
    -H "apikey: $ANON_KEY")
  local count=$(echo "$body" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d) if isinstance(d,list) else 0)" 2>/dev/null || echo "0")
  [[ "$count" -eq 0 ]] && blocked "Exams not exposed ($count returned)" || fail "Exams exposed! $count exams leaked"
}

test_scrape_categories() {
  header "SCRAPE — LIST CATEGORIES WITHOUT AUTH"
  local body=$(curl -s "$SUPABASE_URL/rest/v1/categories?select=*" \
    -H "apikey: $ANON_KEY")
  local count=$(echo "$body" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d) if isinstance(d,list) else 0)" 2>/dev/null || echo "0")
  [[ "$count" -eq 0 ]] && blocked "Categories not exposed ($count)" || fail "Categories exposed! $count leaked"
}

# ─── Main ──────────────────────────────────────────────────────────────────

run_all() {
  test_mass_signup
  test_credential_stuffing
  test_invalid_email_signup
  test_user_enumeration
  test_idor_profiles
  test_idor_exam_results
  test_idor_reports
  test_sqli_rpc
  test_json_injection_exam_results
  test_spam_leaderboard_rpc
  test_scrape_exams
  test_scrape_categories
}

# CLI mode selector
mode="${1:-all}"
case "$mode" in
  all)       run_all ;;
  auth)      test_mass_signup; test_credential_stuffing; test_invalid_email_signup ;;
  enum)      test_user_enumeration; test_idor_profiles; test_idor_exam_results; test_idor_reports ;;
  inject)    test_sqli_rpc; test_json_injection_exam_results ;;
  spam)      test_spam_leaderboard_rpc ;;
  scrape)    test_scrape_exams; test_scrape_categories ;;
  *)         echo "Usage: $0 [all|auth|enum|inject|spam|scrape]"; exit 1 ;;
esac

echo ""
echo "══════════════════════════════════════════════"
echo "  RESULTS:  ✅ $PASS passed | ❌ $FAIL failed | 🛡️  $BLOCKED blocked"
echo "══════════════════════════════════════════════"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
