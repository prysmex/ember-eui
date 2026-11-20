#!/usr/bin/env bash
# The grep and import gates of V03C-DESIGN.md 5 (checks 7 and 8), and the
# untouched-paths check (9).
#   gates.sh <repo root> <base ref>
# Exit 1 on any failure.
set -u
ROOT=${1:?repo root}
BASE=${2:?base ref}
DIR="$ROOT/packages/sheet/src/-private/sheet"
status=0

# 7. No `this` passed as a value in a module, except as the target of
# `later` and `debounce`; no `this.isDestroying` / `this.isDestroyed`.
if [ -d "$DIR" ]; then
  hits=$(grep -nE "[(,] ?this ?[,)]" "$DIR"/*.ts "$DIR"/*.gts 2>/dev/null | grep -vE "\b(later|debounce)\(this," || true)
  if [ -n "$hits" ]; then echo "FAIL owner gate: this passed as a value:"; echo "$hits"; status=1; fi
  hits=$(grep -nE "this\.(isDestroying|isDestroyed)\b" "$DIR"/*.ts "$DIR"/*.gts 2>/dev/null || true)
  if [ -n "$hits" ]; then echo "FAIL owner gate: this.isDestroying/isDestroyed:"; echo "$hits"; status=1; fi
  # 8. Every import of the component is `import type`.
  hits=$(grep -nE "from '\.\./\.\./components/eui-sheet\.gts'" "$DIR"/*.ts "$DIR"/*.gts 2>/dev/null | grep -vE ":\s*import type " || true)
  multi=$(grep -nzoE "import \{[^}]*\} from '\.\./\.\./components/eui-sheet\.gts'" "$DIR"/*.ts "$DIR"/*.gts 2>/dev/null | tr '\0' '\n' || true)
  if [ -n "$hits" ]; then echo "FAIL import gate: value import of the component:"; echo "$hits"; status=1; fi
  if [ -n "$multi" ]; then echo "FAIL import gate: multi-line value import of the component:"; echo "$multi"; status=1; fi
  echo "owner gate (grep): $(ls "$DIR" | wc -l) files checked"
  node "$(dirname "$0")/owner-gate.mjs" "$DIR"/*.ts $(ls "$DIR"/*.gts 2>/dev/null) 2>&1 | grep -vE "UNDICI|trace-warn" || true
  node "$(dirname "$0")/owner-gate.mjs" "$DIR"/*.ts $(ls "$DIR"/*.gts 2>/dev/null) >/dev/null 2>&1 || status=1
fi

# 9. Untouched paths since the base.
touched=$(git -C "$ROOT" diff --name-only "$BASE" -- \
  packages/sheet/tests packages/core packages/sheet/src/core \
  packages/sheet/src/types.ts packages/sheet/src/index.ts packages/sheet/src/search-ui)
untracked=$(git -C "$ROOT" ls-files --others --exclude-standard -- \
  packages/sheet/tests packages/core packages/sheet/src/core \
  packages/sheet/src/types.ts packages/sheet/src/index.ts packages/sheet/src/search-ui)
if [ -n "$touched$untracked" ]; then echo "FAIL untouched paths changed:"; echo "$touched$untracked"; status=1; fi
echo "untouched paths: $([ -z "$touched$untracked" ] && echo OK)"
[ $status -eq 0 ] && echo "gates: OK"
exit $status
