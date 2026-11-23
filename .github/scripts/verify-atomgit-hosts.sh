#!/bin/bash
# A/B verification inside the OHOS CI container: pin api.atomgit.com and
# file.atomgit.com to 159.138.147.37 and check where brew's network traffic
# actually goes. Verification-only; restores /etc/hosts on exit.
set -uo pipefail
source "$(dirname "$0")/lib.sh"

IP=159.138.147.37
FORMULA=${VERIFY_FORMULA:-social4hyq/core/claude-code}

say() { echo "$@" | tee -a "$GITHUB_STEP_SUMMARY"; }
hr()  { say ""; say "---"; say ""; }

cexec "cp /etc/hosts /etc/hosts.ab-orig"
trap 'cexec "cp /etc/hosts.ab-orig /etc/hosts" >/dev/null 2>&1 || true' EXIT

say "## atomgit hosts A/B verification"
say ""
say "Candidate entries under test:"
say '```'
say "159.138.147.37 api.atomgit.com"
say "159.138.147.37 file.atomgit.com"
say '```'

hr
say "### 1. Baseline — public DNS, from inside the OHOS container"
for h in api.atomgit.com file.atomgit.com file-cdn.gitcode.com atomgit.com harmonybrew.atomgit.com; do
  out=$(cexec "curl -sS -o /dev/null -w '%{remote_ip} %{http_code} %{time_total}s' --max-time 15 https://$h/ 2>&1 || true")
  say "- \`$h\` -> \`$out\`"
done

hr
say "### 2. Apply the hosts pin and re-resolve"
cexec "printf '%s\n' '$IP api.atomgit.com' '$IP file.atomgit.com' >> /etc/hosts"
say '```'
cexec "grep -E 'atomgit|159\.138' /etc/hosts || true"
say '```'
for h in api.atomgit.com file.atomgit.com; do
  out=$(cexec "curl -sS -o /dev/null -w '%{remote_ip} %{http_code} %{time_total}s' --max-time 15 https://$h/ 2>&1 || true")
  say "- \`$h\` -> \`$out\`"
done

hr
say "### 3. brew update with pin applied"
t0=$(date +%s)
cbrew "update --quiet" >/dev/null 2>&1 || true
t1=$(date +%s)
say "- wall time: $((t1-t0))s (informational; run-to-run variance is high)"

hr
say "### 4. Bottle download — which host does brew actually contact?"
say "- formula: \`$FORMULA\`"
log=$(mktemp)
cexec "env HOMEBREW_CACHE=/tmp/hb-ab-cache2 HOMEBREW_NO_AUTO_UPDATE=1 brew fetch -v --bottle-tag=arm64_ohos $FORMULA" >"$log" 2>&1
rc=$?
say "- \`brew fetch\` exit: $rc"
say ""
say "URLs brew resolved for this fetch:"
{ grep -oE 'https://[^ ]+' "$log" || true; } | sed -E 's#(https://[^/]+).*#\1#' | sort -u | while read -r u; do say "- \`$u\`"; done
say ""
say "Raw fetch log (tail):"
say '```'
tail -30 "$log" || true
say '```'

hr
say "### 4b. Real bottle redirect chain (from the runner, with pin applied in container)"
ROOT=$(cexec "grep -m1 'root_url' $TAP_IN_CONTAINER/Formula/c/claude-code.rb | awk -F'\"' '{print \$2}'")
TAG=${ROOT##*/}
say "- root_url: \`$ROOT\`"
ASSET=$(curl -sS --max-time 30 "https://atomgit.com/api/v5/repos/social4hyq/homebrew-core/releases/tags/$TAG" 2>/dev/null | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next((a["name"] for a in d.get("assets",[]) if "bottle.tar.gz" in a["name"]), ""))' 2>/dev/null || true)
say "- asset: \`$ASSET\`"
if [ -n "$ASSET" ]; then
  BURL="$ROOT/$ASSET"
  say "- redirect Location:"
  curl -sSL -r 0-0 -D - -o /dev/null --max-time 40 "$BURL" 2>/dev/null | grep -i '^location:' | tail -1 | sed 's/^/  /' || true
  say "- final hop (default DNS):"
  curl -sSL -r 0-0 -o /dev/null --max-time 40 -w '  ip=%{remote_ip} code=%{http_code}\n' "$BURL" 2>/dev/null || true
  CDNHOST=$(curl -sSL -r 0-0 -D - -o /dev/null --max-time 40 "$BURL" 2>/dev/null | grep -i '^location:' | tail -1 | tr -d '\r' | awk '{print $2}' | sed -E 's#https://([^/]+)/.*#\1#')
  say "- CDN host actually used by the download: \`$CDNHOST\`"
  if [ -n "$CDNHOST" ]; then
    say "- same object pinned to 159.138.147.37 (HK) on that CDN host:"
    curl -sSL -r 0-0 -o /dev/null --max-time 40 --resolve "$CDNHOST:443:159.138.147.37" -w '  ip=%{remote_ip} code=%{http_code}\n' "$BURL" 2>/dev/null || true
  fi
fi

hr
say "### 5. Interpretation"
say "- If brew's download URLs contain neither \`api.atomgit.com\` nor \`file.atomgit.com\`, the two hosts entries cannot affect brew install."
say "- If the pinned hosts return a different IP but brew never contacts them, the pin is inert for brew."
