#!/usr/bin/env bash
# Assert the factual claims the cloudinary-asset-migration skill makes.
#
# Every check maps to a specific line of guidance. A failure means the skill is
# stale (the docs changed under it), not that any code is broken.
#
#   ./tests/cloudinary-asset-migration/skill-claims.sh
#
# Needs network access to the public Cloudinary docs. No credentials, and
# nothing is uploaded.

set -uo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
SKILL="$HERE/../../skills/use-cases/cloudinary-asset-migration"
DOCS="https://cloudinary.com/documentation"

# shellcheck source=lib.sh
. "$HERE/lib.sh"

# doc_has <label> <page> <substring>   : assert a docs page (.md) contains text.
# Reads the whole page before matching: piping curl into `grep -q` fails under
# pipefail on large pages, because grep exits early and curl gets SIGPIPE.
doc_has() {
  local label=$1 page=$2 needle=$3 body
  body=$(curl -s -L --max-time 60 "$DOCS/$page.md")
  if grep -qF -- "$needle" <<<"$body"; then
    _ok "$label"
  else
    _no "$label" "missing '$needle': $DOCS/$page.md"
  fi
}

section "Methods (SKILL.md, Choose the migration method)"
doc_has "cld migrate takes an upload mapping and a URL file" \
  cloudinary_cli "migrate [[command options](#migrate_command_options)] [upload_mapping]"
doc_has "cld sync has a keep-unique flag (a push deletes otherwise)" \
  cloudinary_cli "-K, --keep-unique"
doc_has "cld clone doesn't copy structured metadata" \
  cloudinary_cli "doesn't support cloning structured metadata"
doc_has "cld clone copies tags and context only with -fi" \
  cloudinary_cli "Specify whether to copy tags and context"

section "Planning (SKILL.md, Plan the migration)"
doc_has "public ID is unique per resource_type and delivery type" \
  cloudinary_glossary "only required unique within a specific \`resource_type\` and \`type\`"
doc_has "upload response flags an existing asset" \
  upload_images '"existing": true'
doc_has "metadata CSV import is capped at 10,000 assets" \
  dam_admin_structured_metadata "up to 10,000 assets in a single import"
doc_has "cloud name can change only under 1000 assets" \
  migration "less than 1000 assets"
doc_has "private storage can be an upload source" \
  upload_parameters "Upload from a private storage URL"

section "Images (SKILL.md, Get the originals)"
doc_has "camera RAW support is ARW, CR2, and CR3" \
  image_format_support ".arw, .cr2, .cr3"

section "Source-platform claims (references/source-platforms.md)"
file_has "YouTube recorded as having no API path" \
  "$SKILL/references/source-platforms.md" "No API path"
file_has "Brightcove /sources trap is called out" \
  "$SKILL/references/source-platforms.md" "returns \*\*transcoded renditions\*\*"
file_has "Vimeo original field marked unverified" \
  "$SKILL/references/source-platforms.md" "does not state which field"

summary
