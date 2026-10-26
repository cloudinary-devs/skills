#!/usr/bin/env bash
# Every SKILL.md must carry the version-check block rendered from
# templates/version-check.md, directly under its H1. {{name}} and
# {{version}} come from the frontmatter; {{referrer}} is the referrer its doc links already use, or
# <name without cloudinary->-skill if it has none.
# Usage: scripts/check-version-block.sh [--fix]   (--fix rewrites the blocks)
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
template="$root/templates/version-check.md"
fix=0; [ "${1:-}" = "--fix" ] && fix=1

render() { # <name> <referrer> <version> -> rendered block on stdout
  sed -e "s/{{name}}/$1/g" -e "s/{{referrer}}/$2/g" -e "s/{{version}}/$3/g" "$template"
}
strip_block() { # <file> -> file without the block (and the blank line after it)
  awk '/<!-- version-check:start/{skip=1; next}
    skip{if (/<!-- version-check:end -->/) {skip=0; drop=1}; next}
    drop{drop=0; if ($0 == "") next}
    {print}' "$1"
}
insert_block() { # <file without block> <block file> -> file with block after the H1
  awk -v blk="$2" 'BEGIN{done=0}
    {print}
    !done && /^# /{getline nxt; print ""; while ((getline l < blk) > 0) print l; print ""; if (nxt != "") print nxt; done=1}' "$1"
}

fail=0
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
while IFS= read -r md; do
  # Read both keys from the leading frontmatter only, at any indentation.
  name=$(sed -nE '1,/^---$/{s/^[[:space:]]*name:[[:space:]]*['"'"'"]?([^'"'"'"]+)['"'"'"]?[[:space:]]*$/\1/p;}' "$md" | head -1)
  version=$(sed -nE '1,/^---$/{s/^[[:space:]]+version:[[:space:]]*['"'"'"]?([^'"'"'"]+)['"'"'"]?[[:space:]]*$/\1/p;}' "$md" | head -1)
  if [ -z "$name" ] || [ -z "$version" ]; then
    echo "::error file=${md#"$root"/}::Could not read name or metadata.version from the frontmatter, so the version-check block can't be rendered."
    fail=1; continue
  fi
  dir=$(dirname "$md")
  referrer=$(grep -rhoE 'referrer=[A-Za-z0-9_-]+' "$dir" | sed 's/referrer=//' | sort | uniq -c | sort -rn | awk 'NR==1{print $2}')
  [ -n "$referrer" ] || referrer="${name#cloudinary-}-skill"

  render "$name" "$referrer" "$version" > "$tmp/block"
  strip_block "$md" > "$tmp/bare"
  insert_block "$tmp/bare" "$tmp/block" > "$tmp/want"

  if ! cmp -s "$md" "$tmp/want"; then
    if [ "$fix" -eq 1 ]; then
      cp "$tmp/want" "$md"; echo "fixed $name"
    else
      echo "::error file=${md#"$root"/}::$name's version-check block is missing, out of date (for example after a version bump), or not directly under the H1. Run scripts/check-version-block.sh --fix."
      fail=1
    fi
  else
    echo "ok   $name"
  fi
done < <(find "$root/skills" -name SKILL.md | LC_ALL=C sort)
exit $fail
