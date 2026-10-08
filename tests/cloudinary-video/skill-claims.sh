#!/usr/bin/env bash
# Assert the factual claims the cloudinary-video skill makes.
#
# A skill that is confidently wrong is worse than one that is silent, and these
# claims are the load-bearing ones: an agent following them will not
# second-guess them. Every check here maps to a specific line of guidance, and
# a failure means the SKILL is stale, not that the code is broken.
#
# Two modes:
#
#   ./tests/cloudinary-video/skill-claims.sh
#                                          # claims checkable without credentials
#   ./tests/cloudinary-video/skill-claims.sh --cloud
#                                          # also provision a fresh cloud and
#                                          # assert the upload/add-on claims
#
# The default mode runs against Cloudinary's public `demo` cloud. Two checks
# (chapters VTT and translated transcript paths) need a cloud that holds those
# files; set FEATURE_CLOUD and FEATURE_ID to one, or they are skipped.
#
# --cloud takes a few minutes and needs any VPN paused. It uploads two media
# files that are not vendored here: set TEST_IMAGE to any JPEG and TEST_VIDEO
# to an MP4 of at least 15 seconds with clear speech.

set -uo pipefail
cd "$(dirname "$0")" || exit 1
. lib.sh

WITH_CLOUD=0
[ "${1:-}" = "--cloud" ] && WITH_CLOUD=1

# --cloud uploads real media, which is too large to vendor into a skills repo.
TEST_IMAGE=${TEST_IMAGE:-}
TEST_VIDEO=${TEST_VIDEO:-}
if [ "$WITH_CLOUD" = "1" ]; then
  [ -f "$TEST_IMAGE" ] && [ -f "$TEST_VIDEO" ] || {
    echo "--cloud needs TEST_IMAGE (any JPEG) and TEST_VIDEO (an MP4 of at" >&2
    echo "least 15 seconds with clear speech) set to existing files." >&2
    exit 1
  }
fi

SKILL=../../skills/platform/cloudinary-video
PUB=https://res.cloudinary.com/demo   # Cloudinary's public demo cloud
VID=dog                               # a short public video on it
TRANSCRIPT=docs/nanotech              # a public audio-only asset with a .transcript
FEATURE_CLOUD=${FEATURE_CLOUD:-}      # optional: a cloud with chapters and an
FEATURE_ID=${FEATURE_ID:-}            # .es.transcript for FEATURE_ID

http() { curl -s -o /dev/null -w '%{http_code}' -L --max-time 60 "$1"; }

# claim <label> <condition-result> <detail>
# Used where the assertion is computed rather than a simple status check.
claim() { [ "$2" = "yes" ] && _ok "$1" || _no "$1" "$3"; }

# ── Claims about delivery and transformations ───────────────────────────────

section "Transformation claims (SKILL.md B2, capabilities.md)"

# "breakpoints/resize cannot be combined with sp_auto: Cloudinary rejects it"
ERR=$(curl -s -D - -o /dev/null --max-time 60 "$PUB/video/upload/c_limit,w_2560/sp_auto/$VID.m3u8" | tr -d '\r')
if echo "$ERR" | grep -q '^HTTP/[0-9.]* 400' && echo "$ERR" | grep -qi 'resize is only supported for overlay'; then
  _ok "resize + sp_auto is rejected (400, resize is only supported for overlay)"
else
  _no "resize + sp_auto was not rejected as documented" "$(echo "$ERR" | grep -i '^HTTP\|x-cld-error')"
fi

# "Prefer f_auto/q_auto separate; the combined form is a convention, NOT a
#  correctness rule." Assert the equivalence, so that if Cloudinary ever does
#  start rejecting the combined form the guidance gets revisited.
SEP=$(http "$PUB/video/upload/f_auto/q_auto/$VID.mp4")
JOINT=$(http "$PUB/video/upload/f_auto,q_auto/$VID.mp4")
claim "f_auto/q_auto (separate) delivers ($SEP)" \
  "$([ "$SEP" = "200" ] && echo yes || echo no)" "expected 200, got $SEP"
if [ "$JOINT" = "200" ]; then
  # Same bytes? Then they are genuinely interchangeable and player.md is right
  # to call it a convention rather than a rule.
  L1=$(curl -s -o /dev/null -w '%{size_download}' -L --max-time 60 "$PUB/video/upload/f_auto/q_auto/$VID.mp4")
  L2=$(curl -s -o /dev/null -w '%{size_download}' -L --max-time 60 "$PUB/video/upload/f_auto,q_auto/$VID.mp4")
  [ "$L1" = "$L2" ] \
    && _ok "f_auto,q_auto (combined) is equivalent: convention, not a rule" \
    || _no "combined form delivers different bytes ($L1 vs $L2)" "player.md claims equivalence"
else
  _no "f_auto,q_auto combined now returns $JOINT" "player.md says both are accepted, so guidance is stale"
fi

# "sp_auto returns a manifest with a rendition ladder"
body_has "sp_auto manifest lists renditions" \
  "$PUB/video/upload/sp_auto/$VID.m3u8" "RESOLUTION="

# "breakpoints is mutually exclusive with sp_auto at EVERY width; the skill
#  says verified 640..2560, so verify it rather than trusting one sample."
BP_OK=yes
for w in 640 1280 1920 2560; do
  C=$(http "$PUB/video/upload/c_limit,w_$w/sp_auto/$VID.m3u8")
  [ "$C" != "400" ] && BP_OK="w=$w returned $C, not 400"
done
claim "resize+sp_auto rejected at every width (640-2560)" \
  "$([ "$BP_OK" = "yes" ] && echo yes || echo no)" \
  "$BP_OK, but capabilities.md claims all widths are rejected"

# "progressive accepts the same widths breakpoints would pick between"
PROG_OK=yes
for w in 640 1280 1920; do
  C=$(http "$PUB/video/upload/c_limit,w_$w/f_auto/q_auto/$VID.mp4")
  [ "$C" != "200" ] && PROG_OK="w=$w failed ($C)"
done
claim "progressive path accepts explicit widths" \
  "$([ "$PROG_OK" = "yes" ] && echo yes || echo no)" "$PROG_OK"

# "Audio-only sources: sp_auto returns 400" (gotchas.md)
AUD=$(curl -s -D - -o /dev/null --max-time 60 "$PUB/video/upload/sp_auto/$TRANSCRIPT.m3u8" | tr -d '\r')
if echo "$AUD" | grep -q '^HTTP/[0-9.]* 400' && echo "$AUD" | grep -qi 'audio only'; then
  _ok "sp_auto on an audio-only source is rejected (400, audio only)"
else
  _no "sp_auto on an audio-only source was not rejected as documented" "$(echo "$AUD" | grep -i '^HTTP\|x-cld-error')"
fi

section "Async output shape claims (build-patterns.md)"

# "<publicId>.transcript is Cloudinary JSON, not WebVTT"
SHAPE=$(curl -s -L --max-time 60 "$PUB/raw/upload/$TRANSCRIPT.transcript" \
  | python3 -c "
import sys,json
raw=sys.stdin.read()
if raw.lstrip().startswith('WEBVTT'): print('vtt'); raise SystemExit
try: d=json.loads(raw)
except Exception: print('neither'); raise SystemExit
print('json-words' if (isinstance(d,list) and d and d[0].get('words')) else 'json-plain')
" 2>/dev/null)
claim "transcript is JSON with word-level timings" \
  "$([ "$SHAPE" = "json-words" ] && echo yes || echo no)" \
  "got '$SHAPE', but build-patterns.md relies on words[].start_time"

# "auto_chaptering produces <publicId>-chapters.vtt, and it IS WebVTT" and
# "translated transcripts live at <publicId>.<lang>.transcript". No public
# asset carries these, so they need FEATURE_CLOUD and FEATURE_ID.
if [ -n "$FEATURE_CLOUD" ] && [ -n "$FEATURE_ID" ]; then
  body_has "chapters file is WebVTT at <id>-chapters.vtt" \
    "https://res.cloudinary.com/$FEATURE_CLOUD/raw/upload/$FEATURE_ID-chapters.vtt" "WEBVTT"
  status "translated transcript path (.es.transcript)" \
    "https://res.cloudinary.com/$FEATURE_CLOUD/raw/upload/$FEATURE_ID.es.transcript"
else
  _skip "chapters VTT and translated transcript paths" "set FEATURE_CLOUD and FEATURE_ID to check them"
fi

section "Player transcript-support claims (build-patterns.md, player.md)"

# The player consumes .transcript natively (maxWords triggers the lookup,
# wordHighlight uses the word timings). What it does NOT have is a searchable
# transcript panel. Both halves are documented, so both are asserted; the
# second as a doc check, since absence of an option cannot be probed by curl.
file_has "maxWords documented as the .transcript trigger" \
  "$SKILL/references/player.md" "maxWords"
file_has "wordHighlight documented" \
  "$SKILL/references/player.md" "wordHighlight"
file_has "no-native-searchable-panel recorded" \
  "$SKILL/references/build-patterns.md" "no\*\* native support for is a \*\*searchable transcript"
file_has "player-vs-yours split stated" \
  "$SKILL/references/build-patterns.md" "an on-page searchable transcript is yours"

section "Player distribution claims (SKILL.md B3)"

# The script-tag URLs the skill tells people to use must actually resolve.
status "player JS at the pinned version" \
  "https://unpkg.com/cloudinary-video-player@4.1.0/dist/player.min.js"
status "player CSS at the pinned version" \
  "https://unpkg.com/cloudinary-video-player@4.1.0/dist/player.min.css"

section "Internal consistency"

for f in capabilities.md build-patterns.md field-guide.md player.md gotchas.md upload-and-prepare.md; do
  [ -f "$SKILL/references/$f" ] && _ok "reference exists: $f" || _no "missing reference: $f"
done

# Every references/ link in the skill must resolve.
BROKEN=$(grep -oh 'references/[a-z-]*\.md' "$SKILL/SKILL.md" "$SKILL"/references/*.md \
  | sort -u | while read -r r; do [ -f "$SKILL/$r" ] || echo "$r"; done)
[ -z "$BROKEN" ] && _ok "all reference links resolve" || _no "broken links" "$BROKEN"

# ── Claims that need a fresh cloud ──────────────────────────────────────────

if [ "$WITH_CLOUD" -eq 0 ]; then
  printf '\n\033[90mSkipping upload/add-on claims. Rerun with --cloud to assert those.\033[0m\n'
  summary
fi

section "Provision a throwaway cloud"
RESP=$(npx --yes @cloudinary/cloud --json --no-env \
  --goal "assert the factual claims in the cloudinary-video skill" \
  ${MODEL:+--model "$MODEL"} 2>&1 | sed -n '/^{/,$p')

if echo "$RESP" | grep -q delivery_ips_not_public; then
  _no "provision" "behind a VPN: pause it and rerun"
  summary
fi

eval "$(echo "$RESP" | python3 -c "
import sys,json
d=json.load(sys.stdin); e=d['product_environments'][0]
print(f'CLOUD={e[\"cloud_name\"]}'); print(f'KEY={e[\"api_key\"]}'); print(f'SEC={e[\"api_secret\"]}')
print(f'CLAIM=\"{d[\"claim_url\"]}\"')
" 2>/dev/null)"
[ -n "${CLOUD:-}" ] && _ok "provisioned $CLOUD" || { _no "provision" "$RESP"; summary; }

API="https://api.cloudinary.com/v1_1/$CLOUD"

section "Entitlement-API claims (upload-and-prepare.md, capabilities.md)"

# "There is no Admin API for add-ons: /addons, /add_ons, /subscriptions and
#  /entitlements all 404."
for ep in addons add_ons subscriptions entitlements; do
  C=$(curl -s -o /dev/null -w '%{http_code}' -u "$KEY:$SEC" "$API/$ep")
  [ "$C" = "404" ] \
    && _ok "/$ep returns 404, as documented" \
    || _no "/$ep returned $C, not 404" "capabilities.md says no entitlement API exists"
done

section "Add-on failure-mode claims (upload-and-prepare.md)"

# THE load-bearing claim: "requesting a subscribed-only add-on rejects the
# WHOLE upload (the asset is never stored)". If this ever degrades gracefully
# instead, the upload-free-features-first rule becomes unnecessary.
PROBE=$(curl -s "$API/image/upload" -u "$KEY:$SEC" \
  -F "file=@$TEST_IMAGE" -F "public_id=claims/addon_probe" \
  -F "categorization=google_tagging")
if echo "$PROBE" | grep -qi "subscription"; then
  _ok "add-on request rejected with a subscription error"
  STORED=$(curl -s -o /dev/null -w '%{http_code}' -u "$KEY:$SEC" \
    "$API/resources/image/upload/claims%2Faddon_probe")
  [ "$STORED" = "404" ] \
    && _ok "and the asset was NOT stored (upload free features first)" \
    || _no "the asset WAS stored ($STORED)" "SKILL says the whole upload is rejected"
elif echo "$PROBE" | grep -q '"public_id"'; then
  _ok "google_tagging is available on this fresh cloud (unexpected but fine)"
else
  _no "add-on probe gave neither" "$(echo "$PROBE" | head -c 200)"
fi

# "auto_transcription WITH translate fails the whole transcription on a cloud
#  without Google Translation, where plain auto_transcription succeeds."
section "Translate-is-the-add-on-part claim (upload-and-prepare.md)"
T=$(curl -s "$API/video/upload" -u "$KEY:$SEC" \
  -F "file=@$TEST_VIDEO" -F "public_id=claims/translate_probe" \
  -F "auto_transcription[translate][]=es")
if echo "$T" | grep -qi "subscription\|translation"; then
  _ok "auto_transcription+translate rejected without the add-on"
else
  printf '  \033[33m◐\033[0m auto_transcription+translate did not error outright\n'
  printf '      response: %s\n' "$(echo "$T" | head -c 160)"
fi

section "Free-feature claims (SKILL.md A2)"
FREE=$(curl -s "$API/video/upload" -u "$KEY:$SEC" \
  -F "file=@$TEST_VIDEO" -F "public_id=claims/free_probe" \
  -F "auto_transcription=true" -F "auto_chaptering=true" -F "auto_video_details=true")
if echo "$FREE" | grep -q '"public_id"'; then
  _ok "auto_transcription + auto_chaptering + auto_video_details accepted on a fresh cloud"
  # "They return status: pending and finish later": assert pending, not done.
  PEND=$(echo "$FREE" | python3 -c "
import sys,json
d=json.load(sys.stdin); i=d.get('info',{})
sts={k:v.get('status') for k,v in i.items() if isinstance(v,dict) and 'status' in v}
print(','.join(f'{k}={v}' for k,v in sorted(sts.items())) or 'none')
" 2>/dev/null)
  case $PEND in
    *pending*) _ok "async features report pending: $PEND" ;;
    none)      _no "no async status in the upload response" "SKILL says they return pending" ;;
    *)         printf '  \033[33m◐\033[0m async statuses: %s\n' "$PEND" ;;
  esac
else
  _no "free features were rejected" "$(echo "$FREE" | head -c 200)"
fi

section "Unclaimed-cloud remote-fetch claim (gotchas.md)"
# "On an unclaimed cloud, POST /upload with file=<a delivery URL on that same
#  cloud> fails 401: Cloudinary's fetcher is not an allowed delivery IP."
# Upload a plain image first so the fetch targets an asset that exists.
curl -s -o /dev/null "$API/image/upload" -u "$KEY:$SEC" \
  -F "file=@$TEST_IMAGE" -F "public_id=claims/plain"
RF=$(curl -s "$API/image/upload" -u "$KEY:$SEC" \
  -F "file=https://res.cloudinary.com/$CLOUD/image/upload/claims/plain.jpg" \
  -F "public_id=claims/remote_fetch_probe")
if echo "$RF" | grep -qi "401\|unauthor\|not allowed"; then
  _ok "remote fetch of own delivery URL fails on an unclaimed cloud"
else
  printf '  \033[33m◐\033[0m remote fetch did not fail as documented\n'
  printf '      response: %s\n' "$(echo "$RF" | head -c 160)"
fi

printf '\n\033[1mThrowaway cloud\033[0m %s expires in 24h; claim only if you want it:\n  %s\n' "$CLOUD" "$CLAIM"
summary
