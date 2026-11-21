#!/usr/bin/env bash
# Runs scale.js over builds and cases, interleaved: for each run, each build
# in turn, each case in turn (timings move 10-30 % between sessions here, so
# builds are compared within one session, run by run).
#   BUILDS="base:4197 new:4198" CASES="rows=10000 rows=100000,throttle=4" RUNS=3 \
#     ./run-scale.sh <out-dir>
# A case is scale.js's arguments joined by commas. Every RESULT line goes to
# <out-dir>/results.jsonl as {"build","run","args",...result}; logs next to it.
# Then: node median-scale.mjs <out-dir>
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
out="${1:?out-dir}"; mkdir -p "$out"
runs="${RUNS:-3}"
for run in $(seq "${RUN_FROM:-1}" "$runs"); do
  for b in ${BUILDS:?}; do
    label="${b%%:*}"; port="${b##*:}"
    for c in ${CASES:?}; do
      args="${c//,/ }"
      log="$out/$label-${c//[=,]/_}-$run.log"
      if PORT="$port" OUT="$out/prof" node "$here/scale.js" $args > "$log" 2>&1; then
        line="$(grep -a '^RESULT ' "$log" | sed 's/^RESULT //')"
        node -e 'const [b,r,a,j]=process.argv.slice(1);console.log(JSON.stringify({build:b,run:+r,args:a,...JSON.parse(j)}))' "$label" "$run" "$c" "$line" >> "$out/results.jsonl"
        echo "$label run $run $c ok"
      else
        echo "$label run $run $c FAILED (see $log)"
      fi
    done
  done
done
