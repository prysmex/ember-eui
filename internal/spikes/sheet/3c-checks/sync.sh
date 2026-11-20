#!/usr/bin/env bash
# Copies the repo's changes under packages/sheet and this folder to the
# Linux copy (the repo's node_modules are macOS-only), deletions too, then
# checks that src/ and tests/ are the same in both.
#   sync.sh <repo root> <linux copy root> <base ref>
set -eu
R=${1:?repo}; L=${2:?linux copy}; BASE=${3:?base ref}
cd "$R"
{ git diff --name-only "$BASE" -- packages/sheet internal/spikes/sheet/3c-checks
  git ls-files --others --exclude-standard -- packages/sheet internal/spikes/sheet/3c-checks; } | sort -u |
while read -r f; do
  if [ -e "$R/$f" ]; then mkdir -p "$(dirname "$L/$f")"; cp "$R/$f" "$L/$f"; echo "copied $f"
  elif [ -e "$L/$f" ]; then rm "$L/$f"; echo "removed $f"; fi
done
diff -rq "$R/packages/sheet/src" "$L/packages/sheet/src"
diff -rq "$R/packages/sheet/tests" "$L/packages/sheet/tests"
echo "sync: src and tests are the same"
