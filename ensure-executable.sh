#!/bin/bash
# Mark scripts executable in the working tree (and git index when in a repo).
set -e
root="$(cd "$(dirname "$0")" && pwd)"
cd "$root"

mark_exec() {
  local f="$1"
  chmod +x "$f"
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git update-index --chmod=+x "$f" 2>/dev/null || true
  fi
}

while IFS= read -r -d '' f; do
  mark_exec "$f"
done < <(find . -type f ! -path './.git/*' \( -name '*.sh' -o -name '*.pl' \) -print0)

while IFS= read -r -d '' f; do
  if head -1 "$f" | grep -q '^#!'; then
    mark_exec "$f"
  fi
done < <(find . -type f ! -path './.git/*' \( -name '*.py' -o -name '*.awk' \) -print0)

echo "Executable bits set under $root"
