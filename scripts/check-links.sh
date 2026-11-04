#!/usr/bin/env bash
# Every cloudinary.com link to a .md page or llms.txt must carry the
# install_source and referrer query params so docs traffic from skills is
# attributable. Usage: scripts/check-links.sh [dir]   (default: skills)
set -u
dir="${1:-skills}"
url_re='https?://[A-Za-z0-9.-]*cloudinary\.com/[^[:space:])>"'"'"'`]*(\.md|/llms\.txt)([?#][^[:space:])>"'"'"'`]*)?'

fail=0
checked=0
while IFS= read -r hit; do
  checked=$((checked + 1))
  file="${hit%%:*}"; rest="${hit#*:}"; line="${rest%%:*}"; url="${rest#*:}"
  missing=""
  case "$url" in (*install_source=*) ;; (*) missing="install_source";; esac
  case "$url" in (*referrer=*) ;; (*) missing="${missing:+$missing, }referrer";; esac
  if [ -n "$missing" ]; then
    echo "::error file=$file,line=$line::Missing $missing on $url"
    fail=1
  fi
done < <(grep -rnoE "$url_re" "$dir" --include='*.md' --include='*.txt' --include='*.ts' --include='*.tsx' --include='*.js' | LC_ALL=C sort -u)

if [ "$checked" -eq 0 ]; then
  echo "::error::No cloudinary.com .md or llms.txt links found under '$dir'. The check matched nothing, so it cannot pass."
  exit 1
fi
if [ "$fail" -ne 0 ]; then
  echo "Add '?install_source=skillspack&referrer=<skill>-skill' to each link above (see CONTRIBUTING.md)."
  exit 1
fi
echo "All $checked .md and llms.txt links carry install_source and referrer."
