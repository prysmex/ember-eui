# Docs-site memory-leak crawler

Drives Chromium over the DevTools Protocol through the built docs site, with
in-app (router service) navigation so the Ember app stays alive the way a
real app does, and measures what survives a forced GC. No dependencies: Node
>= 22 (built-in `WebSocket`) and a Chromium binary (Playwright's is found
automatically, or set `CHROME=/path/to/chrome`).

Findings from the 2026-10 audit: `internal/memory-leak-audit/leak-site.md`.

## Files

- `serve.mjs` static server for `site/dist` with an SPA fallback.
- `cdp.mjs` minimal CDP client and Chromium launcher.
- `instrument.js` injected before page scripts. Counts listeners on
  window/document/html/body, live intervals, pending timeouts and rAFs, and
  Resize/Mutation/Intersection observers that observe without being
  disconnected, with the creation stack of each live one (for attribution).
- `crawl.mjs` the crawler (modes below).
- `analyze.mjs` heap-snapshot diff: net growth per constructor, new surviving
  objects (node ids are stable within one session), detached DOM, and the
  shortest retainer path from the GC roots for samples.

## Run

```sh
# 1. build (core dist first: the site consumes it)
cd packages/core && ./node_modules/.bin/rollup --config
cd ../../site && rm -rf app/templates/docs && ./node_modules/.bin/vite build --mode development

# 2. serve
node tests/leak/serve.mjs dist 4791 &

# 3. crawl (NO_PROXY must cover 127.0.0.1 if a proxy is configured)
node tests/leak/crawl.mjs passes --passes=3 [--snapshots]         # whole-site passes
node tests/leak/crawl.mjs bisect --reps=3                         # every route, ranked by growth
node tests/leak/crawl.mjs routes --routes=/docs/core/docs/layout/modal --reps=20 --snapshots
node tests/leak/crawl.mjs css --routes=/docs/core/docs/display/toast --reps=8   # style-cache growth

# 4. analyse two snapshots of one session
node --max-old-space-size=4096 tests/leak/analyze.mjs diff before.heapsnapshot after.heapsnapshot \
  [--top=40] [--paths=3] [--groups=12] [--maxpath=40] [--match='Regex'] [--bysize=1]
```

Flags: `--out=<dir>` (JSON results and snapshots, default `tests/leak/results`,
which is git-ignored), `--no-exercise` (navigate only), `--away=<url>` (page
visited between repetitions, default `/docs/introduction`), `--skip=a,b`,
`--max-buttons=25`, `--settle=250` (ms after each transition), `--debug`.

"Exercise" clicks every visible, enabled button in each demo preview
(`.docfy-demo__example`), each followed by a real Escape key press, then
navigates away. `window.open`, `alert`, `confirm` and `print` are stubbed.

## Environment notes

- `--disable-dev-shm-usage`: a 64MB `/dev/shm` makes chunk loads fail with
  `ERR_INSUFFICIENT_RESOURCES`.
- `--js-flags=--no-decommit-pooled-pages`: on aarch64 with 16K kernel pages a
  forced (memory-reducing) GC crashes Chromium 130's renderer
  (`page_allocator_internals_posix.h:357`). Override with `JS_FLAGS=...`.
- `Runtime.enable` makes DevTools keep every console-logged object; the
  crawler discards console entries before each measurement, and records
  which routes log in `consoleLogs`.
- The site build is `--mode development` (Ember DEBUG): debugRenderTree and
  non-speedy emotion (one `<style>` per rule) add memory a production build
  doesn't have.
