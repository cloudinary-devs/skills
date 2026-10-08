# Shared assertion helpers. Sourced by the test scripts.

PASS=0; FAIL=0; SKIP=0

_ok()   { PASS=$((PASS+1)); printf '  \033[32m✓\033[0m %s\n' "$1"; }
_no()   { FAIL=$((FAIL+1)); printf '  \033[31m✗\033[0m %s\n' "$1"; [ -n "$2" ] && printf '      %s\n' "$2"; }
_skip() { SKIP=$((SKIP+1)); printf '  \033[33m-\033[0m %s (skipped)\n' "$1"; [ -n "${2:-}" ] && printf '      %s\n' "$2"; }

section() { printf '\n\033[1m%s\033[0m\n' "$1"; }

# status <label> <url> [expected]   : assert an HTTP status
status() {
  local label=$1 url=$2 want=${3:-200} got
  got=$(curl -s -o /dev/null -w '%{http_code}' -L --max-time 60 "$url")
  [ "$got" = "$want" ] && _ok "$label" || _no "$label" "want $want, got $got: $url"
}

# body_has <label> <url> <substring>   : assert response contains text
body_has() {
  local label=$1 url=$2 needle=$3
  if curl -s -L --max-time 60 "$url" | grep -q -- "$needle"; then
    _ok "$label"
  else
    _no "$label" "missing '$needle': $url"
  fi
}

# file_has <label> <path> <substring>
file_has() {
  local label=$1 path=$2 needle=$3
  if [ -f "$path" ] && grep -q -- "$needle" "$path"; then
    _ok "$label"
  else
    _no "$label" "missing '$needle' in $path"
  fi
}

# json_field <label> <url> <python-expr on `d`> <expected>
json_field() {
  local label=$1 url=$2 expr=$3 want=$4 got
  got=$(curl -s -L --max-time 60 "$url" | python3 -c "
import sys,json
try: d=json.load(sys.stdin)
except Exception: print('<not json>'); raise SystemExit
try: print($expr)
except Exception as e: print(f'<{e}>')
" 2>/dev/null)
  [ "$got" = "$want" ] && _ok "$label" || _no "$label" "want $want, got $got"
}

# summary: print the tally and EXIT. Always exits, so it doubles as the
# early-return for a script that has hit a blocking condition (no cloud, no
# credentials) and cannot meaningfully continue.
summary() {
  printf '\n%s passed, %s failed, %s skipped\n' "$PASS" "$FAIL" "$SKIP"
  [ "$FAIL" -eq 0 ] && exit 0 || exit 1
}
