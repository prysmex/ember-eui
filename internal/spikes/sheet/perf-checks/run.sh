#!/usr/bin/env bash
# Median of N runs (default 3) of profile-scroll.js and count-tags.js, plain
# and frozen. Needs `vite preview` of site/dist on $PORT (default 4195).
#   PORT=4195 RUNS=3 CASES="plain frozen" ./run.sh <label> [profile|count|all]
# Logs and the medians go to $OUT (default $TMPDIR/sheet-perf/<label>).
# DIST: the served dist directory the counters instrument (default site/dist);
# RUN_IDS: the runs' numbers (default 1..RUNS), to interleave two builds
# (A/B: one run of each in turn, see README).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
label="${1:?label}"; what="${2:-all}"
runs="${RUNS:-3}"
export PORT="${PORT:-4195}"
export OUT="${OUT:-${TMPDIR:-/tmp}/sheet-perf}/$label"
mkdir -p "$OUT"
ids="${RUN_IDS:-$(seq 1 "$runs")}"
dist="${DIST:-}"
# a case: plain, frozen, selected (a cell clicked first) or frozen-selected
for c in ${CASES:-plain frozen}; do
  args="$(echo "$c" | sed 's/plain//; s/-/ /g')"
  if [[ "$what" == all || "$what" == profile ]]; then
    for i in $ids; do node "$here/profile-scroll.js" $args > "$OUT/profile-$c-$i.log" 2>&1; done
  fi
  if [[ "$what" == all || "$what" == count ]]; then
    node "$here/instrument.mjs" apply $dist
    trap 'node "$here/instrument.mjs" restore $dist' EXIT
    for i in $ids; do node "$here/count-tags.js" $args > "$OUT/count-$c-$i.log" 2>&1; done
    node "$here/instrument.mjs" restore $dist
    trap - EXIT
  fi
done
node "$here/median.mjs" "$OUT" | tee "$OUT/medians.txt"
