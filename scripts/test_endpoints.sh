#!/usr/bin/env bash
#
# Single-region serverless integration test (run once per region/state).
# Requires: aws cli, curl, jq. Run from repo root.
#
# Usage (set test credentials explicitly via environment):
#   TEST_USERNAME=<your-test-email> TEST_PASSWORD=<your-test-password> ./scripts/test_endpoints.sh
#
set -e

for cmd in aws curl jq terraform; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Required: $cmd"; exit 1; }
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="$REPO_ROOT/terraform/environments/dev"
TARGET_REGION="${TEST_REGION:-us-east-1}"
TF_VAR_FILE="${TF_VAR_FILE:-}"
USERNAME="${TEST_USERNAME:-}"
PASSWORD="${TEST_PASSWORD:-}"

GREEN='\033[92m'
RED='\033[91m'
YELLOW='\033[93m'
CYAN='\033[96m'
BOLD='\033[1m'
RESET='\033[0m'

passed=0
total=0

call_and_check() {
  local label="$1"
  local url="$2"
  local token="$3"
  local expected_region="$4"
  local tmp
  tmp=$(mktemp)
  total=$((total + 1))

  local status body region ok=0
  local time_file
  if raw=$(curl -s -w "%{http_code}\n%{time_total}" -o "$tmp" \
    -H "Authorization: Bearer $token" \
    --connect-timeout 10 --max-time 20 \
    "$url" 2>/dev/null); then
    status=$(echo "$raw" | head -1)
    latency_ms=$(echo "$raw" | tail -1 | awk '{printf "%.0f", $1*1000}')
    body=$(cat "$tmp")
    region=$(echo "$body" | jq -r '.region // empty' 2>/dev/null || echo "")

    if [[ "$status" == "200" && "$region" == "$expected_region" ]]; then
      passed=$((passed + 1))
      ok=1
      echo -e "  ${GREEN}${BOLD}✓ $label${RESET}"
    else
      echo -e "  ${RED}${BOLD}✗ $label${RESET}"
    fi
    echo "    Status: $status  Latency: ${latency_ms}ms  region: $region"
    echo "    Response: $body"
  else
    echo -e "  ${RED}${BOLD}✗ $label${RESET}"
    echo "    Request failed"
  fi
  rm -f "$tmp"
  echo ""
  return $((1 - ok))
}

echo -e "\n${BOLD}${CYAN}═══ Serverless Integration Test (${TARGET_REGION}) ═══${RESET}\n"

echo -e "${BOLD}[1/4] Reading Terraform outputs …${RESET}"
cd "$TF_DIR"
client_id=$(terraform output -raw cognito_client_id)
greet_url=$(terraform output -raw api_primary_url)
dispatch_url="${greet_url/greet/dispatch}"
cd "$REPO_ROOT" >/dev/null

echo "  /greet    ${TARGET_REGION}  →  $greet_url"
echo "  /dispatch ${TARGET_REGION}  →  $dispatch_url"
echo ""

echo -e "${BOLD}[2/4] Authenticating with Cognito (${TARGET_REGION}) …${RESET}"
token=$(aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id "$client_id" \
  --auth-parameters "USERNAME=$USERNAME,PASSWORD=$PASSWORD" \
  --region "$TARGET_REGION" \
  --query 'AuthenticationResult.IdToken' --output text 2>/dev/null) || {
  echo -e "${RED}✗ Cognito auth failed. Check TEST_USERNAME/TEST_PASSWORD.${RESET}"
  exit 1
}
echo -e "  ${GREEN}✓ JWT obtained${RESET}"
echo ""

echo -e "${BOLD}[3/4] Calling /greet …${RESET}"
call_and_check "greet" "$greet_url" "$token" "$TARGET_REGION" || true

echo -e "${BOLD}[4/4] Calling /dispatch …${RESET}"
call_and_check "dispatch" "$dispatch_url" "$token" "$TARGET_REGION" || true

echo -e "${BOLD}${CYAN}═══ Summary ═══${RESET}"
if [[ $passed -eq $total ]]; then
  echo -e "  Tests passed : ${GREEN}$passed/$total${RESET}"
  exit 0
else
  echo -e "  Tests passed : ${RED}$passed/$total${RESET}"
  exit 1
fi
