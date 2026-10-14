#!/usr/bin/env bash
# Leak mode, one command (run from packages/core):
#
#   scripts/leaks.sh [qunit filter] [extra query, e.g. '&growthCycles=400']
#
# Builds the tests with source maps (EUI_LEAKS=1), runs them in headless
# Chrome with ?leaks (tests/leak-detector.ts) over CDP, writes
# leak-report.json and prints the summary (scripts/leak-report.mjs).
# Set SNAPSHOT=file.heapsnapshot to also save a heap snapshot at the end, then
# `node scripts/heap-retainers.mjs file.heapsnapshot` explains survivors.
set -euo pipefail
cd "$(dirname "$0")/.."

filter="${1:-}"
extra="${2:-}"

EUI_LEAKS=1 NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=4096}" \
  ./node_modules/.bin/vite build --mode=development --out-dir dist-tests >/dev/null

args=(--out leak-report.json --timeout 60 --stuck 180)
[ -n "$filter" ] && args+=(--filter "$filter")
[ -n "$extra" ] && args+=(--extra "$extra")
[ -n "${SNAPSHOT:-}" ] && args+=(--snapshot "$SNAPSHOT")

node scripts/leak-cdp.mjs "${args[@]}" | grep -v '^\[progress\]' || true
node scripts/leak-report.mjs leak-report.json
