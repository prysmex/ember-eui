#!/usr/bin/env bash
# A production docs build with the harness-only page "Sheet perf (harness)"
# (large-page/, the d08 demo sized from the URL) into <out-dir>, never
# site/dist. The page is copied into packages/sheet/docs for the build and
# removed again (also on failure). Build the packages first (`pnpm build` in
# packages/sheet; packages/core already built).
#   ./build-large.sh <out-dir>
# Serve: (cd site && npx vite preview --port 4197 --strictPort --host 127.0.0.1 --outDir <out-dir>)
# The page: http://127.0.0.1:4197/docs/sheet/docs/perf-large?rows=100000
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../../../.." && pwd)"
out="$(realpath -m "${1:?out-dir}")"
case "$out" in "$repo/site/dist"|"$repo/site/dist/"*) echo "not site/dist" >&2; exit 2;; esac
docs="$repo/packages/sheet/docs"
cleanup() {
  rm -rf "$docs/perf-large.md" "$docs/perf-large-demo"
  # the generated page templates hold the page now: regenerate them clean
  rm -rf "$repo/site/app/templates/docs"
}
trap cleanup EXIT
cp "$here/large-page/perf-large.md" "$docs/"
cp -r "$here/large-page/perf-large-demo" "$docs/"
export NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=6144}"
cd "$repo/site"
pnpm clean:docfy
node ../scripts/sync-injected.mjs
npx vite build --outDir "$out" --emptyOutDir
echo "built $out"
