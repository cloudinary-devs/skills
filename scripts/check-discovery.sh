#!/usr/bin/env bash
# Every SKILL.md under skills/ must be discovered by the skills CLI, by name.
# The CLI drops a skill silently (bad frontmatter, wrong depth, missing
# name/description) whenever at least one other skill is found, so a count
# alone is not enough. Usage: scripts/check-discovery.sh [dir]   (default: .)
set -u
dir="${1:-.}"

# Expected: the frontmatter name of every SKILL.md.
expected=$(find "$dir/skills" -name SKILL.md | while IFS= read -r f; do
  # First name: key inside the leading frontmatter block only.
  sed -nE '1,/^---$/{s/^name:[[:space:]]*['"'"'"]?([^'"'"'"]+)['"'"'"]?[[:space:]]*$/\1/p;}' "$f" | head -1
done | LC_ALL=C sort -u)

if [ -z "$expected" ]; then
  echo "::error::No SKILL.md with a name found under $dir/skills."
  exit 1
fi

output=$(INSTALL_INTERNAL_SKILLS=1 NO_COLOR=1 npx -y skills@latest add "$dir" --list 2>&1 || true)
# Strip ANSI escapes (the CLI colours output whenever CI is set), then keep
# the lines between "Available Skills" and the trailing hint. Skill names are
# printed alone on a line; descriptions are multi-word, so a line that is a
# single slug token is a skill name.
found=$(printf '%s\n' "$output" \
  | sed -E 's/\x1b\[[0-9;?]*[a-zA-Z]//g' \
  | sed -n '/Available Skills/,/Use --skill/p' \
  | sed -E 's/^[^[:alnum:]]*//; s/[[:space:]]+$//' \
  | grep -xE '[a-z0-9][a-z0-9._-]*' \
  | LC_ALL=C sort -u)

missing=$(comm -23 <(printf '%s\n' "$expected") <(printf '%s\n' "$found"))
extra=$(comm -13 <(printf '%s\n' "$expected") <(printf '%s\n' "$found"))

if [ -n "$missing" ] || [ -n "$extra" ]; then
  for n in $missing; do
    echo "::error::Skill '$n' has a SKILL.md but is not discovered by the skills CLI (bad frontmatter, wrong depth, or missing name/description)."
  done
  for n in $extra; do
    echo "::error::Skills CLI reports '$n' but no SKILL.md declares that name."
  done
  echo "--- expected ---"; printf '%s\n' "$expected"
  echo "--- found ---";    printf '%s\n' "$found"
  echo "--- cli output ---"; printf '%s\n' "$output"
  exit 1
fi

count=$(printf '%s\n' "$expected" | wc -l | tr -d ' ')
echo "All $count skills discovered by name:"
printf '  %s\n' $expected
