#!/usr/bin/env bash
# Every static check of a 3c stage (V03C-DESIGN.md 5): verbatim, gates,
# lint:types, the tests' ember-tsc against the baseline's 19 errors, eslint
# and prettier on the changed files, the API docs check.
#   check.sh <repo root> <linux copy root> <base ref> <baseline tests-tsc log>
# CHECKS_NODE_MODULES defaults to <linux copy>/node_modules.
# The suite runs separately (see V03C-RESULTS.md).
set -u
R=${1:?repo}; L=${2:?linux copy}; BASE=${3:?base ref}; TSC_BASE=${4:?baseline tests tsc log}
HERE=$(cd "$(dirname "$0")" && pwd)
export CHECKS_NODE_MODULES=${CHECKS_NODE_MODULES:-$L/node_modules}
export NODE_OPTIONS=--max-old-space-size=6144
quiet() { grep -vE "UNDICI|trace-warnings" || true; }
status=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "== verbatim"
git -C "$R" show "$BASE:packages/sheet/src/components/eui-sheet.gts" > "$tmp/eui-sheet.gts"
pairs=()
for f in $(git -C "$R" diff --name-only "$BASE" -- packages/sheet/src/-private | grep -v '/-private/sheet/' || true); do
  [ -e "$R/$f" ] || continue
  mkdir -p "$tmp/$(dirname "$f")"; git -C "$R" show "$BASE:$f" > "$tmp/$f"
  pairs+=(--pair "$tmp/$f::$R/$f")
done
D="$R/packages/sheet/src/-private/sheet"
node "$HERE/verbatim.mjs" --old "$tmp/eui-sheet.gts" --new "$R/packages/sheet/src/components/eui-sheet.gts" "$D"/*.ts $(ls "$D"/*.gts 2>/dev/null) "${pairs[@]}" 2>&1 | quiet
[ "${PIPESTATUS[0]}" -eq 0 ] || status=1

echo "== gates"
"$HERE/gates.sh" "$R" "$BASE" || status=1

cd "$L/packages/sheet"
echo "== lint:types"
pnpm lint:types 2>&1 | quiet | grep -v '^\$' ; [ "${PIPESTATUS[0]}" -eq 0 ] && echo "lint:types: OK" || { echo "lint:types: FAIL"; status=1; }

echo "== tests ember-tsc"
pnpm exec ember-tsc --noEmit -p tsconfig.eslint.json > "$tmp/tsc.log" 2>&1
grep "error TS" "$TSC_BASE" | sort > "$tmp/a"; grep "error TS" "$tmp/tsc.log" | sort > "$tmp/b"
if diff "$tmp/a" "$tmp/b"; then echo "tests ember-tsc: $(wc -l < "$tmp/b") errors, the baseline's"; else echo "tests ember-tsc: FAIL (differs from the baseline)"; status=1; fi

echo "== eslint, prettier (changed files)"
changed=$(cd "$R" && { git diff --name-only "$BASE" -- packages/sheet/src; git ls-files --others --exclude-standard -- packages/sheet/src; } | sort -u | while read -r f; do [ -e "$f" ] && echo "${f#packages/sheet/}"; done)
if [ -n "$changed" ]; then
  pnpm exec eslint $changed 2>&1 | quiet; [ "${PIPESTATUS[0]}" -eq 0 ] && echo "eslint: OK" || { echo "eslint: FAIL"; status=1; }
  pnpm exec prettier --check $changed 2>&1 | quiet; [ "${PIPESTATUS[0]}" -eq 0 ] || status=1
fi
( cd "$L/internal/spikes/sheet/3c-checks" 2>/dev/null && "$L/node_modules/.bin/prettier" --check . 2>&1 | quiet ) || true

echo "== api docs"
( cd "$L" && node scripts/generate-api-docs.mjs --check 2>&1 | quiet; exit "${PIPESTATUS[0]}" ) && echo "docs:api:check: OK" || { echo "docs:api:check: FAIL"; status=1; }

echo "== diff --stat of the protected paths"
git -C "$R" diff --stat "$BASE" -- packages/sheet/tests packages/sheet/src/core packages/sheet/src/types.ts packages/sheet/src/index.ts packages/core packages/sheet/src/search-ui
echo "(empty above: untouched)"

[ $status -eq 0 ] && echo "ALL STATIC CHECKS: OK" || echo "STATIC CHECKS: FAIL"
exit $status
