# Memory-leak audit: docs-site crawl (leak-site)

Branch `eui-leak/leak-site`, base `master` 52e1af5d (v16.0.0). Date 2026-10-14.
Crawler: `site/tests/leak/` (README there has run instructions).

## Method

- Built core (`rollup --config`), changeset-form, flatpickr and pikaday dists in this worktree, then `vite build --mode development` of the site.
- **`scripts/sync-injected.mjs` was NOT run.** It calls pnpm's `syncInjectedDeps`, which writes into `node_modules/.pnpm/...`. In this worktree `node_modules` and `site/node_modules` are symlinks into the main checkout, so it would have changed the main checkout's injected copies. Instead I replaced the worktree's `site/node_modules` symlink with a local directory (untracked). It symlinks every entry of the main checkout's `site/node_modules`, except that `@ember-eui/{core,changeset-form,flatpickr,pikaday}` point at this worktree's packages, and `.vite`/`.embroider` caches stay local. `@ember-eui/validated-form` still points at the main checkout's injected copy. The main checkout was clean at the same commit.
- Served `site/dist` with `serve.mjs` on 127.0.0.1:4791. Drove Playwright's Chromium 130 over raw CDP (no playwright package is installed). Navigation used `router.transitionTo`, through the owner exposed by `globalThis.emberInspectorApps`, so the app stayed alive.
- "Exercise" means: click every visible, enabled button or `[role=button|switch]` in each `.docfy-demo__example`, at most 25 per page, with a pointer/mouse event sequence. Each click is followed by a real CDP Escape key press. Then the crawler navigates away.
- Metrics after 3 forced GCs (`HeapProfiler.collectGarbage`): JS heap, Nodes, JSEventListeners, Documents, attached elements, `<style>` count and CSS rules. An injected script (`instrument.js`) also counts listeners on window/document/html/body, intervals, pending timeouts and rAFs, and live Resize/Mutation/Intersection observers (observe() without a later disconnect()/unobserve()). It records the creation stack of each live one.
- Per-route bisection: warm the route once, measure, then visit the route and go away N times, GC, and measure again. Heap snapshots were diffed with `analyze.mjs`. Snapshot node ids are stable within a session, so the diff gives new surviving objects, net growth per constructor and shortest retainer paths.

### Environment problems hit (and fixed in the crawler)
- `/dev/shm` is 64MB, so lazy route chunks failed with `ERR_INSUFFICIENT_RESOURCES`. Fixed with `--disable-dev-shm-usage`.
- Kernel pages here are 16K (aarch64). Any forced GC killed the renderer: `FATAL page_allocator_internals_posix.h(357)`, mprotect errno ≠ ENOMEM. `--js-flags=--no-decommit-pooled-pages` avoids it. Natural GCs were fine.
- `Runtime.enable` makes DevTools keep every console-logged object. My first runs showed ~2,200 retained DOM nodes per visit of drag-and-drop. The cause was `@atlaskit` auto-scroll's `console.warn("Auto scrolling has been attached to an element that appears not to be scrollable", {element})`, 176 warnings in 11 visits, held by `(Global handles) / DevTools console`. The crawler now calls `Runtime.discardConsoleEntries` before each measurement. After that change, drag-and-drop shows 24 extra nodes in 10 visits, all of them style tags.
- The VM was sometimes suspended or heavily loaded: other agents' testem Chromiums, plus orphaned Chromiums from my own crawler runs that had timed out (now killed on exit). That caused CDP timeouts with no route in particular. Re-running each affected route on its own showed no hang (data-grid/grouping ×10, schema-and-columns ×10).
- The build is `--mode development` (Ember DEBUG). debugRenderTree WeakMaps and non-speedy emotion (one `<style>` per rule) add memory that a production build doesn't have.

## Results

### Whole-site passes (143 routes)

Run 1 measured warm-up and 2 passes; pass 3 hit a CDP timeout. Run 1 predates the console-entry fix, so its `nodes` include objects held by the DevTools console. Run 2 was cut off at the coordinator's request after the baseline. Only its warm-up numbers exist, and they match run 1.

| Point (after GC, on /docs/introduction) | JS heap MB | Nodes | JSEventListeners | Documents | attached els | `<style>`/CSS rules | root listeners | live RO | live MO |
|---|---|---|---|---|---|---|---|---|---|
| initial load | 14.2 | 6,464 | 160 | 11 | 1,261 | 472 / 637 | 7 | 0 | 127 |
| warm-up 1 (navigate only) | 82.4–84.6 | 34.8k–38.5k* | 168 | 12 | 10,985 | 9,780 / 9,588 | 9 | 28 | 127 |
| warm-up 2 (exercise) | 83.6–85.7 | 45.5k–52.9k* | 168 | 12 | 13,407 | 12,202 / 11,843 | 9 | 67 | 127 |
| pass 1 (exercise), run 1 | 88.2 | 56,607* | 168 | 12 | 13,429 | – / 11,865 | 9 | 106 | 127 |
| pass 2 (exercise), run 1 | 88.6 | 60,317* | 168 | 12 | 13,435 | – / 11,871 | 9 | 145 | 127 |
| pass 3 | not measured (timeout in run 1; run 2 stopped) | | | | | | | | |

\* includes DevTools-console retention (see above).

Reading:
- JS heap plateaus: +2.5 MB in pass 1, +0.4 MB in pass 2.
- JSEventListeners, Documents, root listeners, intervals and body children are flat: no portal, listener or interval accumulation across the whole site.
- Attached elements and CSS rules grow by about 6–20 per pass. That is the emotion style cache, which plateaus (see L3).
- **Live ResizeObservers grow by exactly +39 per pass.** All of them come from one modifier: L1.
- Nodes grew by about 3.7k per pass in run 1. That is console retention: route reruns after the fix show no DOM growth.

### Per-route bisection (exercise on, 3 visits per route, 143 routes; data-grid/grouping skipped in the batch and re-run alone)

Routes with any growth. All other routes were 0 on every counter.

| Route (core docs) | Δ nodes | Δ `<style>` | Δ live RO | Δ pending timeouts | Note |
|---|---|---|---|---|---|
| layout/drag-and-drop | 6,540 → 24 after console fix (10 visits) | 8 | 0 | 0 | console.warn retention only |
| tabular/data-grid/schema-and-columns | 4,536 → 51–87 (10 visits) | 17–29 | 0 | 0 | heap +0.4–0.6 MB/visit: JIT code, perf entries, WeakMap tables (see L4) |
| editors/markdown-editor/base-editor | 0 | 0 | **+27** | 0 | L1 (EuiToolTip in the toolbar); also TypeError `reading 'start'` |
| forms/form-layouts | 0 | 0 | **+15** | 0 | L1 |
| forms/super-select | 0 | 0 | **+12** | 0 | L1 (EuiInputPopover) |
| forms/super-date-picker | 0 | 0 | **+9** | 0 | L1 |
| forms/color-palette-picker | 0 | 0 | **+9** | 0 | L1 |
| display/comment-list | 0 | 0 | **+6** | 0 | L1; also TypeError `reading 'start'` |
| forms/search-bar | 0 | 0 | **+6** | **+12** | L1 + L2 |
| layout/popover, forms/form-controls/range | 0 | 0 | +6 each | 0 | L1 |
| layout/flyout, layout/modal, forms/selectable, forms/suggest, form-control-button | 0 | 0 | +3 each | 0 | L1 |
| validated-form | 0 | 0 | +6 | 0 | L1 (validated-form's own bundled copy of the modifier); also a tracking assertion |
| display/icons, data-grid/tree-expansion, display/avatar, toast, key-pad-menu, card, … | 3× Δstyle | 1–24 | 0 | 0 | emotion cache, plateaus (L3) |
| data-grid/grouping (10 visits, alone) | 6 | 2 | 0 | 0 | clean |

Not measured: none of the 144 routes was skipped in the end. Grouping was measured on its own. A 20-visit bisection with snapshots was done only for drag-and-drop, schema-and-columns and grouping, with 10 visits each.

## Findings

### L1 — `resize-observer` modifier creates a new ResizeObserver (and a new destructor) on every update without disconnecting the previous one. [Library, High, Confirmed]
- **Where:** `packages/core/src/modifiers/resize-observer.ts:89-99` (`modify` → `_setup()` + `registerDestructor`), and `_setup` at about line 102. Used by EuiToolTip (`eui-tool-tip.gts:771`), EuiInputPopover (`:261`), EuiContextMenuPanel (`:378`), EuiCodeBlock, EuiMarkdownEditor, EuiMarkdownEditorDropZone, EuiBottomBar, EuiResizableContainer and EuiTable sticky-scrollbar. validated-form ships the same code in its bundle.
- **Mechanism:** ember-modifier calls `modify()` on install and again whenever a tracked value it consumed changes. `_setup()` calls `setSize` synchronously, which runs `named.onResize(...)`. That consumes the component's tracked state, for example the tooltip position or the input-popover width, so the modifier re-runs whenever that state changes. Each run assigns `this.observer = new ResizeObserver(...)`, which orphans the previous observer while it is still observing the element, and calls `registerDestructor` again. Teardown disconnects only the last observer.
- **Evidence:** live-observer instrumentation. The creation stacks of every leaked observer are `s (resize-observer.js) < c._setup < c.modify < installModifier|updateModifier`. Counts: +39 per whole-site pass, exactly the sum of the per-route deltas above. Per route: base-editor +9 per visit, form-layouts +5, super-select +4, flyout/modal +1, and so on. 28 observers leak on navigation alone, without clicking.
- **Impact:** while the component is mounted, every update adds another observer and another destructor, so N callbacks fire per resize, each doing `getBoundingClientRect()`. After unmount the orphans are never disconnected. Route diffs showed no detached-DOM growth from them, so Chromium appears to collect an orphan once its target is detached. The retention is therefore bounded by the component's lifetime, but the observers and the CPU work accumulate within it. A long-lived tooltip or input popover in an app, such as a toolbar or a header, grows without bound.
- **Fix:** split install from update. Create the observer once (on first `modify`, or when `element` changes) and register the destructor once. On later `modify` calls, only refresh `this.named`/`this.positional`. Alternatively, disconnect `this.observer` at the top of `_setup()`. Also call `onResize` outside the tracking frame (e.g. `untrack`, or schedule it) so the modifier doesn't re-run on the component's own state.

### L2 — Search bar leaves long timers pending after the route is left. [Library, Medium, Suspected]
- **Where:** forms/search-bar demos (EuiSearchBar and its filters). Not attributed to a line: timer stacks were added to the instrumentation after the bisection ran.
- **Evidence:** pending `setTimeout`s went 12 → 24 after 3 visits, still pending ≥1 s after navigating away and 3 GCs. No other route left timers pending. Intervals were 0 site-wide.
- **Next step:** `node tests/leak/crawl.mjs routes --routes=/docs/core/docs/forms/search-bar --reps=5`. The `liveDiff` now lists `timeout(Nms) @ stack` for every timer of 500 ms or longer. Likely candidates are a debounce or `later` without cancel in a destructor, or an ember-concurrency `timeout` in a task that isn't cancelled.

### L3 — Emotion style cache grows on first use of each style variant, then plateaus. [Library, Low, Confirmed bounded]
- **Evidence:** `crawl.mjs css` with 8 visits per route. Icons added +45 rules on the first visit, then stayed flat at 1,473 rules. Avatar added 0. Toast stepped 1,581 → 1,587 → 1,595, from demo variants (random toast colours), and is bounded by the number of variants. Class names are content hashes such as `eui-spike-hrcvgb-euiIcon-xl-app`, with no per-instance values. 59–67 duplicate rule texts exist site-wide (same CSS under two keys), which is harmless.
- **Bound:** the number of distinct (component × props × theme) combinations. In dev mode each rule is its own `<style>` element. That accounts for the ~13k attached elements, which are style tags, not leaked DOM.

### L4 — data-grid pages: heap +0.4–0.6 MB per visit with no DOM growth. [Library/runtime, Low, Confirmed, mostly benign]
- **Evidence:** snapshot diff of schema-and-columns ×10, net growth per constructor: `(code)` +8.9k (+1.8 MB JIT), Performance entries (LayoutShift / LongAnimationFrame / EventTiming, bounded browser buffers), WeakMap backing tables (+3.9 MB) of `@glimmer/destroyable` and `debugRenderTree` (dev only), `system / Map` +194. No detached DOM: 4 → 4. Whole-site passes show the heap plateauing, so this is warm-up and table capacity, not a per-visit leak.

### S1 — `@atlaskit/pragmatic-drag-and-drop` auto-scroll warns with the element on every drag-and-drop render. [Third-party / demo, Low, Confirmed]
- `console.warn(..., {element})` fires about 16 times per visit to layout/drag-and-drop. When DevTools is open (and in any CDP/Playwright session), Chrome's console keeps every logged element: about 2,200 DOM nodes per visit here. The underlying cause is EuiDroppable registering auto-scroll on a non-scrollable element. Fix: only attach `autoScrollForElements` when the droppable is actually scrollable, or don't attach it.

### Site-only (docs app)
- No leaks found. `theme-manager` holds 2 static theme objects. `ApplicationRoute`/`ApplicationController` each add one `router.on('routeDidChange')` on singletons, which is bounded. `scrollToHash` makes at most 30 rAF retries. `DemoPlayground` shares one module-level manifest promise and checks `isDestroying`. Its `open()` removes the form it appends. `BorealisRoot` is template-only. Root listeners stayed at 9 across all passes.
- Non-leak errors seen while crawling, for whoever owns them:
  - `TypeError: Cannot read properties of undefined (reading 'start')` on comment-list and markdown-editor/base-editor when demo buttons are clicked: 20 occurrences.
  - validated-form: `Assertion Failed: You attempted to update isTouched … already been used previously in the same computation`.

## Checked and clean (whole site, with exercise)
- Listeners on window/document/html/body: 7 at load, 9 after warm-up, 9 after every pass. JSEventListeners total: 168, flat.
- `setInterval`: 0 live at every measurement. rAFs: 0 pending.
- MutationObservers: 127 live, constant across all passes (the app shell). IntersectionObservers: 0.
- Body children: 3, constant, so no portalled or appended DOM is left behind by modals, flyouts, popovers, tooltips, toasts, combo boxes, date pickers or the data-grid.
- Documents and frames: constant.
- Detached DOM after the console fix: none on any route re-measured with snapshots (drag-and-drop, schema-and-columns, grouping).
- Flyout-manager service (`containerObserver`): one at a time, bounded.
