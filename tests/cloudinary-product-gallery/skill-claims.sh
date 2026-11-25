#!/usr/bin/env bash
# Assert the factual claims the cloudinary-product-gallery skill makes, and
# exercise its preview script. A failure on a docs or CDN check means the SKILL
# is stale, not that the code is broken.
#
#   ./tests/cloudinary-product-gallery/skill-claims.sh
#
# Runs against Cloudinary's public `demo` cloud and needs no credentials.
# Needs curl, python3 and Node 18 or later.

set -uo pipefail
cd "$(dirname "$0")" || exit 1
. lib.sh

SKILL=../../skills/use-cases/cloudinary-product-gallery
DEMO=https://res.cloudinary.com/demo
DOCS=https://cloudinary.com/documentation
TAG=electric_car_product_gallery_demo
SPIN=electric_car_360_product_gallery_demo

# doc_has <label> <url> <substring>: like body_has, but downloads the page first.
# lib.sh's doc_has pipes curl into grep -q, which under pipefail reports failure
# on a large page because grep exits early and curl gets SIGPIPE.
doc_has() {
  local label=$1 url=$2 needle=$3 f
  f=$(mktemp); curl -sL --max-time 60 "$url" -o "$f"
  if grep -qF -- "$needle" "$f"; then _ok "$label"; else _no "$label" "missing '$needle': $url"; fi
  rm -f "$f"
}

section "Widget distribution (SKILL.md defaults)"
# The skill says to pin the newest stable (non-beta) release from the changelog. The pinned example in the
# guide must be a real, served release.
VERSION=$(curl -sL "$DOCS/product_gallery_changelog.md" | grep -oE '^### v[0-9]+\.[0-9]+\.[0-9]+$' | head -1 | sed 's/### v//')
[ -n "$VERSION" ] && _ok "changelog lists a latest release ($VERSION)" || _no "changelog lists a latest release" "no '### vX.Y.Z' heading found"
status "v2 script embed is served for $VERSION" "https://product-gallery-v2.cloudinary.com/${VERSION:-0.0.0}/all.js"
doc_has "guide names the v2 domain" "$DOCS/product_gallery.md" "product-gallery-v2.cloudinary.com"
doc_has "guide says the old domain serves v1" "$DOCS/product_gallery.md" "continues to serve v1"
doc_has "guide says not to use latest in production" "$DOCS/product_gallery.md" "don't do this in production"

section "Tag lists the widget reads (SKILL.md prerequisites, media-preparation.md)"
status "image tag list returns 200" "$DEMO/image/list/$TAG.json"
status "video tag list returns 200" "$DEMO/video/list/$TAG.json"
status "spin tag list returns 200" "$DEMO/image/list/$SPIN.json"
status "unknown tag list returns 404" "$DEMO/image/list/no_such_tag_for_skill_test.json" 404
# Spin frames sort alphanumerically by public ID, which is why the skill says to zero-pad.
doc_has "docs: spin frames sorted by public ID" "$DOCS/product_gallery.md" "sorted alphanumerically by their public ID"

section "Media types (SKILL.md table)"
doc_has "docs: mediaType spin" "$DOCS/product_gallery.md" 'mediaType: "spin"'
doc_has "docs: mediaType 3d" "$DOCS/product_gallery.md" 'mediaType: "3d"'
doc_has "docs: 3D is GLB only" "$DOCS/product_gallery.md" "only supports 3D models in the GLB format"
doc_has "docs: 3D upload as image resource type" "$DOCS/upload_parameters.md" "set \`resource_type\` to \`image\`"
doc_has "docs: default video duration cap" "$DOCS/product_gallery.md" "duration: 30"
doc_has "docs: default crop is pad" "$DOCS/product_gallery.md" 'crop: "pad"'
doc_has "reference: ar3dProps.showAR" "$DOCS/product_gallery_reference.md" "showAR"
doc_has "reference: viewerWidthHint" "$DOCS/product_gallery_reference.md" "viewerWidthHint"
doc_has "reference: accessibilityProps mediaAltSource" "$DOCS/product_gallery_reference.md" "mediaAltSource"

section "PLP delivery URLs (plp-patterns.md)"
for t in "c_fill,ar_3:4,g_auto,w_400/f_auto/q_auto/sample" "c_pad,ar_3:4,w_400,b_white/f_auto/q_auto/sample"; do
  status "PLP URL serves: $t" "$DEMO/image/upload/$t"
done
got=$(curl -s -o /dev/null -w '%{content_type}' -H 'Accept: image/avif,image/webp' "$DEMO/image/upload/c_fill,ar_3:4,g_auto,w_400/f_auto/q_auto/sample")
[ "$got" = "image/avif" ] && _ok "f_auto negotiates AVIF for a browser that accepts it" || _no "f_auto negotiates AVIF" "got $got"

section "Preview script (preview-pgw.mjs)"
PREVIEW=$SKILL/scripts/preview-pgw.mjs
TMP=$(mktemp -d); trap 'rm -rf "$TMP"; [ -n "${SERVER_PID:-}" ] && kill "$SERVER_PID" 2>/dev/null' EXIT
cat > "$TMP/page.html" <<'H'
<!doctype html><html><head><meta charset="utf-8"></head><body><div id="gallery">old</div></body></html>
H

expect_fail() { # <label> <expected stderr substring> <args...>
  local label=$1 want=$2; shift 2
  local out; out=$(node "$PREVIEW" "$@" 2>&1); local rc=$?
  if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q -- "$want"; then _ok "$label"; else _no "$label" "rc=$rc out=$out"; fi
}
BASE=(--page "$TMP/page.html" --selector "#gallery" --cloud demo --tag x)
expect_fail "rejects version 'latest'" "pin an exact" "${BASE[@]}" --version latest
expect_fail "rejects a malformed version" "must look like" "${BASE[@]}" --version 2.0
expect_fail "rejects a selector with no match" 'no element with id="nope"' --page "$TMP/page.html" --selector "#nope" --cloud demo --tag x --version 2.0.3
expect_fail "rejects a missing page" "cannot read" --page "$TMP/none.html" --selector "#gallery" --cloud demo --tag x --version 2.0.3
expect_fail "rejects http allow origins" "only accepts https" "${BASE[@]}" --version 2.0.3 --allow http://example.com
expect_fail "requires at least one media source" "give at least one" --page "$TMP/page.html" --selector "#gallery" --cloud demo --version 2.0.3

PORT=$((20000 + RANDOM % 20000))
node "$PREVIEW" "${BASE[@]}" --version 2.0.3 --port "$PORT" >/dev/null 2>&1 &
SERVER_PID=$!
sleep 1
swapped=$(curl -s -D "$TMP/h" "http://127.0.0.1:$PORT/")
printf '%s' "$swapped" | grep -q 'pgw-preview' && _ok "serves the page with the widget swapped in" || _no "serves the swapped page" "no pgw-preview in body"
original=$(curl -s "http://127.0.0.1:$PORT/?original")
printf '%s' "$original" | grep -q 'pgw-preview' && _no "?original is untouched" "swap script present" || _ok "?original is untouched"
grep -qi "^content-security-policy: default-src 'self'" "$TMP/h" && _ok "sends a Content-Security-Policy header" || _no "sends a Content-Security-Policy header" "$(cat "$TMP/h")"
grep -i "^content-security-policy" "$TMP/h" | grep -q "google-analytics\|googletagmanager" && _no "policy excludes analytics hosts" "analytics host present" || _ok "policy excludes analytics hosts"
code=$(curl -s -o /dev/null -w '%{http_code}' --path-as-is "http://127.0.0.1:$PORT/../../etc/hosts")
[ "$code" != "200" ] && _ok "refuses paths outside the saved page folder ($code)" || _no "refuses path traversal" "got 200"

kill "$SERVER_PID" 2>/dev/null; sleep 0.5
PORT=$((20000 + RANDOM % 20000))
node "$PREVIEW" --page "$TMP/page.html" --selector "#gallery" --cloud demo --version 2.0.3 \
  --public-id id_one --public-id id_two --keep-order --secure-distribution images.example-store.com \
  --desktop-min-width 960 --columns 2 --spacing 3 --port "$PORT" >/dev/null 2>&1 &
SERVER_PID=$!
sleep 1
flagged=$(curl -s -D "$TMP/h2" "http://127.0.0.1:$PORT/")
for want in '"publicId":"id_one"' '"publicId":"id_two"' 'sort: "none"' 'secureDistribution: "images.example-store.com"' 'mode: "expanded"' 'matchMedia'; do
  printf '%s' "$flagged" | grep -qF -- "$want" && _ok "new flags: swap script contains $want" || _no "new flags: swap script contains $want" "missing"
done
grep -i "^content-security-policy" "$TMP/h2" | grep -q "https://images.example-store.com" && _ok "--secure-distribution host is allowed in the policy" || _no "--secure-distribution host is allowed in the policy" "$(grep -i '^content-security' "$TMP/h2")"
expect_fail "rejects a non-numeric --columns" "whole number" --page "$TMP/page.html" --selector "#gallery" --cloud demo --tag x --version 2.0.3 --columns two

summary
