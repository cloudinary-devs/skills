#!/usr/bin/env bash
# Any skill whose content changed between BASE and HEAD must bump
# metadata.version in its SKILL.md. Pure moves/renames (identical content) do
# not count as changes. New skills pass. Usage: scripts/check-versions.sh BASE HEAD
set -u
base="${1:?base ref}"; head="${2:?head ref}"

version_at() { # <ref> <path> -> version string or empty
  git show "$1:$2" 2>/dev/null | sed -nE "s/^  version: *['\"]?([^'\"]+)['\"]?[[:space:]]*$/\1/p" | head -1
}
skill_name_of() { # <ref> <path> -> name of the skill (dir holding nearest SKILL.md), or empty
  local d; d=$(dirname "$2")
  while [ "$d" != "." ] && [ "$d" != "skills" ]; do
    if git cat-file -e "$1:$d/SKILL.md" 2>/dev/null; then basename "$d"; return; fi
    d=$(dirname "$d")
  done
}
skill_md_in() { # <ref> <name> -> path of that skill's SKILL.md in ref, or empty
  git ls-tree -r --name-only "$1" -- skills | grep -E "(^|/)$2/SKILL\.md$" | head -1
}

# Collect the names of skills touched by non-identical changes.
changed_names() {
  git diff --name-status -M100% "$base" "$head" -- skills | while read -r status p1 p2; do
    case "$status" in
      (R100) continue ;;                     # pure move, identical content
      (D)    skill_name_of "$base" "$p1" ;;  # deletion: file lived in base
      (R*)   skill_name_of "$head" "$p2" ;;
      (*)    skill_name_of "$head" "$p1" ;;
    esac
  done | sort -u
}
names=$(changed_names)

if [ -z "$names" ]; then
  echo "No skill content changed."
  exit 0
fi

fail=0
for name in $names; do
  head_md=$(skill_md_in "$head" "$name")
  base_md=$(skill_md_in "$base" "$name")
  if [ -z "$head_md" ]; then echo "skip $name: removed"; continue; fi
  hv=$(version_at "$head" "$head_md")
  if [ -z "$base_md" ]; then echo "ok   $name: new skill ($hv)"; continue; fi
  bv=$(version_at "$base" "$base_md")
  if [ -z "$hv" ]; then
    echo "::error file=$head_md::$name has no metadata.version"; fail=1; continue
  fi
  if [ "$bv" = "$hv" ]; then
    echo "::error file=$head_md,line=7::$name changed but metadata.version is still $hv. Bump it (see CONTRIBUTING.md, Versioning)."
    fail=1
  else
    echo "ok   $name: $bv -> $hv"
  fi
done
exit $fail
