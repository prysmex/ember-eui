# Memory-leak audit: the test suite as a leak detector (leak-harness)

Branch `eui-leak/leak-harness`, base `master` (v16.0.0). Dynamic approach: the
core test suite (2072 tests at the time of the run) runs in an instrumented
"leak mode". Every listener, observer, timer, portal and rendered root is
attributed to the test that created it, and after teardown anything still
alive is reported. A final step forces `gc()` and checks WeakRefs.

## How to run

From `packages/core` (needs `google-chrome` on PATH; in this sandbox that is the
Playwright Chromium wrapper, see the brief):

```sh
scripts/leaks.sh                       # whole suite, ~8 min, prints the summary
scripts/leaks.sh "EuiPopover"          # a QUnit filter
scripts/leaks.sh "Leak | growth" "&growthCycles=400"   # longer growth runs
SNAPSHOT=/tmp/x.heapsnapshot scripts/leaks.sh "eui-badge" && \
  node scripts/heap-retainers.mjs /tmp/x.heapsnapshot   # who retains survivors
```

`scripts/leaks.sh` builds with `EUI_LEAKS=1` (adds source maps), drives Chrome
over CDP (`scripts/leak-cdp.mjs`), writes `leak-report.json` and prints
`scripts/leak-report.mjs`'s summary, with stacks mapped back to `src/…`.

The testem route works as well:
`EUI_LEAKS=1 NODE_OPTIONS=--max-old-space-size=4096 vite build --mode=development --out-dir dist-tests && EUI_LEAKS=1 testem --file testem.cjs ci`
(`EUI_LEAKS_FILTER=…` filters the run). The report lands in `leak-report.json`
through a testem middleware. Last full run: 2074 tests, 0 failures, 2 todo,
494 s. Without `EUI_LEAKS` nothing changes: `testem.cjs` keeps its old flags
and test page, `vite.config.mjs` builds no source maps, and
`tests/leak-detector.ts` patches nothing unless the page has `?leaks`.

### What the instrumentation does (`tests/leak-detector.ts`)

- Loaded by the first `<script type="module">` in `tests/index.html`, so it
  patches globals before Ember, QUnit, focus-trap or any component module
  runs. Hooks are installed from `tests/test-helper.ts` (`installLeakHooks`).
- `EventTarget.prototype.add/removeEventListener` (every target, with
  `signal` support) records the stack at add time. After teardown it reports
  listeners still attached to window, document, `<html>`, `<body>`,
  visualViewport or a MediaQueryList, and to connected elements outside the
  QUnit UI.
- Resize/Mutation/IntersectionObserver are subclassed to track observe,
  unobserve and disconnect.
- setTimeout/setInterval/rAF/rIC and their clears are wrapped. Callbacks
  inherit the test that scheduled them, so a timer or rAF chain that still
  runs after its test finished is attributed back to that test. This is how
  the polling rAF loops were found.
- `@ember/runloop` timers: `_backburner.hasTimers()` after teardown. It was
  always 0, because `teardownContext()` awaits `settled()`, which drains
  `later`/`debounce`/`throttle`. A run-loop timer could only show up from a
  test using `waitForSettled: false`.
- focus-trap: there is no handle on its trap stack, but `activate()` adds
  document listeners and `deactivate()` removes them. Their stacks contain
  `focus-trap`, so a trap left active would be reported with the category
  `focus-trap`. No such trap appeared.
- `<body>` children other than `#qunit`/`#qunit-fixture` (portals), head
  growth, and CSS rule counts.
- WeakRefs to each test's owner and `#ember-testing` root, taken right after
  the test body and before `setupRenderingTest`'s teardown (the test callback
  is wrapped at `testStart`). The detached root retains its whole subtree, so
  any retained node keeps it alive. The report test calls `gc()` ten times,
  lists the survivors, and tags them with `LeakTag` objects so that
  `scripts/heap-retainers.mjs` can print the shortest retaining path. That
  path correctly handles WeakMap ephemerons. Component instances are not
  tracked: on Ember 7, `render()` uses `renderComponent`'s strict renderer,
  and `captureRenderTree(owner)` does not see its tree.
- Each test is judged in the next test's global `beforeEach`, after a
  macrotask, a frame and another macrotask, so zero-delay cleanups from
  teardown are not reported. Every 100 tests it forces `gc()` and samples the
  heap.
- Growth: `tests/integration/leaks/growth-test.gts` (defined only in leak
  mode) mounts/unmounts or opens/closes the heavy components 100 times, after
  5 warm-up cycles. It samples `performance.memory.usedJSHeapSize` after
  `gc()` and the live counters at 0, 50 and 100 cycles.

### Environment notes, needed for the harness to work at all

- In this sandbox, forced `gc()` (and CDP `HeapProfiler.collectGarbage`)
  crashes the renderer under `--headless=new` once the page holds a few
  thousand DOM nodes (`FATAL:page_allocator_internals_posix.h(357) errno 12`;
  reproduced with a blank page and 30k divs). Leak mode therefore uses
  `--headless=old`.
- Old headless lets tests open windows. Some button/link tests click
  `target=_blank` links. Through testem the new window loaded the test page
  again and ran a second suite in parallel, which showed up as duplicated and
  timed-out tests. Old headless also throttles rAF once the page is
  backgrounded, so tests slowed down about 20×. Fixed with
  `--block-new-web-contents`, `--disable-background-timer-throttling`,
  `--disable-renderer-backgrounding` and
  `--disable-backgrounding-occluded-windows`, in leak mode only.
- A build with source maps needs `NODE_OPTIONS=--max-old-space-size=4096`.

## Findings

Counts: High 1 (LH-01, third-party, ember-source; it affects the test
suite, not EUI), Medium 2 leaks (LH-02, LH-03) plus 1 correctness issue
(LH-06), Low 3 (LH-04, LH-05, LH-07). Test artifacts and third-party noise
are classified at the end.

### LH-01: ember-source `renderComponent` keeps every test's owner and DOM alive (third-party; High for the test suite)

> **Fixed upstream** in ember-source 7.3.1 (emberjs/ember.js#21647), which the repo now uses.
> Leak mode no longer calls `_resetRenderers()`, and `?leaks=raw` is gone. See
> ember-render-component-leak-report.md.

- **Where:** `ember-source` 7.3.0
  `dist/dev/packages/shared-chunks/index-COgCjiy-.js:1243-1255` (module-level
  `renderers` array), `:1356-1363` (`RendererState.renderRoot` registers),
  `:1427`/`:1453` (deregister only on a render transaction or
  `clearAllRoots`), `:1511-1518` (`RENDERER_CACHE`, one strict renderer per
  owner). It is reached from `@ember/test-helpers` 5.5 `render()`, which
  uses `renderComponent` on Ember ≥ 6.8. All EUI tests are affected.
- **Mechanism:** the `renderers` array → `BaseRenderer` → `RendererState`.
  From there, `#roots` → `ComponentRootState` → `RenderResultImpl.bounds` →
  `#ember-testing` (the entire DOM of the test), and
  `#data.context.constants.componentDefinitionCache` → `CompilableTemplate.meta.owner`
  (the entire owner: services, component instances, caches). Destroying the
  owner destroys the render result, but the strict renderer is not a
  destroyable child of the owner. The destroyed root is pruned only during a
  later render transaction, which never comes, so the renderer stays
  registered forever.
- **Trigger:** every rendering test. In apps it happens whenever an owner
  that called `renderComponent` is destroyed (engines, app instances in
  tests and SSR).
- **Evidence (Confirmed):** a raw leak-mode run (`?leaks=raw`) of 123
  "popover" tests: all 122 owners and roots survived 10× `gc()`. The heap
  after `gc()` was 533 MB at test 100 and 657 MB at the end. Retaining path
  from `scripts/heap-retainers.mjs`:
  `Window → (closure).context → Context.renderers → Array[7] → BaseRenderer.state → RendererState.#roots → Array[0] → ComponentRootState.#result → RenderResultImpl.bounds → AppendingBlockImpl.parent → #ember-testing`,
  and for the owner:
  `… renderers → Array[0] → BaseRenderer.state → RendererState.#data → Object.context → EvaluationContextImpl.constants → ConstantsImpl.componentDefinitionCache → WeakMap → (EuiBadge's value) → CompilableTemplateImpl.meta → Object.owner`.
  With the workaround below, the same 123 tests end at 47 MB with 0
  survivors.
- **Impact on the audit:** without a workaround every EUI leak would be
  masked, because everything survives. Leak mode calls
  `_resetRenderers()` (private, `@ember/-internals/glimmer`) after each
  test's teardown. `?leaks=raw` turns that off to reproduce this finding.
- **Proposed fix (upstream, ember-source):** make the strict renderer a
  destroyable child of its owner (`associateDestroyableChild(owner, renderer)`
  in `renderComponent`), or have `RendererState` prune destroyed roots and
  `deregister` itself from a destructor on the root. Until then, the test
  suite's memory grows by about 5 MB per test (it ran at more than 650 MB
  after 120 tests), and the `--headless=new` gc crash above makes this worse.

### LH-02: `resize-observer` modifier creates a new ResizeObserver on every `modify()` and disconnects only the last one (Medium)

- **Where:** `packages/core/src/modifiers/resize-observer.ts:91-101`
  (`modify` calls `_setup()` and `registerDestructor` on every run),
  `:116` (`this.observer = makeResizeObserver(...)` overwrites the previous
  observer), `:136` (`_teardown` disconnects only `this.observer`). Used by
  EuiInputPopover (`eui-input-popover.gts:261`), EuiResizableContainer
  (`:419`), EuiMarkdownEditor drop zone (`:301`), EuiCodeBlock (`:744`) and
  EuiContextMenuPanel (`:378`). It is also exported publicly.
- **Mechanism:** each re-run of `modify()` (ember-modifier runs it again
  whenever an arg it consumed changes) builds a new observer on the same
  element without disconnecting the previous one. It also adds one more
  destructor, and every destructor disconnects the same latest observer.
  The orphaned observers keep firing (`setSize` → `onResize`) for as long as
  the element lives. After unmount they stay undisconnected, holding the
  modifier, its `named` args and the caller's `onResize` closure until the
  element itself is collected.
- **Trigger:** any change to a consumed arg while mounted. `modify` consumes
  `positional[0]` on every run. It consumes `onResize` and anything
  `onResize` reads during the synchronous first `setSize` call only when the
  size differs from the cached one. The orphaned observers grow by one per
  re-run, which makes this Medium. In the suite: 155 tests (EuiInputPopover
  users: combo box, color palette picker, super select, search bar hint,
  EuiSuggest, EuiRange/DualRange inputs, markdown footer) ended with an
  undisconnected observer, and 20 RO callbacks ran after their test had
  finished.
- **Evidence (Confirmed):** `Leak | regressions: resize-observer modifier: re-running modify() 50 times keeps one observer, and unmount disconnects all`
  (`tests/integration/leaks/leak-regressions-test.gts`, `test.todo`) gives
  `observers live while mounted: actual 51, expected 1` and `no observer left
  after unmount: actual 50, expected 0`.
- **Proposed fix:** in `modify`, call `this.observer?.disconnect()` before
  `_setup()`, and register the destructor once (in the constructor, or
  behind a flag). Better still, only re-observe when the element changes,
  and read `named`/`positional` lazily inside the callback.

### LH-03: `field_value_selection` filter schedules a new cache-reset timer on every load, even on a cache hit, and clears only the last one (Medium)

- **Where:** `packages/core/src/components/eui-search-bar/field-value-selection-filter.gts:147-154`
  (`if (cache != null && cache > 0) { this.cachedOptions = …; this.cacheTimeout = setTimeout(…, cache) }`
  runs after `this.cachedOptions ?? await options()`, so it also runs on a
  cache hit), and `:81` (`registerDestructor` clears only the latest
  `cacheTimeout`). Upstream starts the timer only after a real fetch.
- **Mechanism:** each popover open (each `loadOptions`) adds a `cache`-ms
  timer and overwrites the handle. All but the last are orphaned. Each one
  holds `this` (the filter component). After unmount the destructor clears
  one timer, and the rest keep the destroyed component alive for up to
  `cache` ms. In the suite that also kept the test's owner and
  `#ember-testing` DOM alive. The orphaned timers also reset the cache
  early: the first timer fires `cache` ms after the first load, not after
  the last fetch.
- **Trigger:** search bar `field_value_selection` filters with async
  `options` and `cache`. Every open adds a timer, which makes this Medium.
  The growth is bounded in time by `cache`.
- **Evidence (Confirmed):**
  `Leak | regressions: field_value_selection filter with cache: reopening 10 times leaves no cache timer behind after unmount`
  (`test.todo`) gives `pending: 10` while mounted and `actual 9, expected 0`
  after unmount. In the full run, `Borealis search bar :: field value
  selection filter…` left 8 pending 10 s timers. The regression test's
  owner and root were the only survivors of the whole run after `gc()`,
  because the 60 s timers retain the destroyed component.
- **Proposed fix:** set the timer only when options were actually fetched
  (move it inside the `cachedOptions == null` branch), and
  `clearTimeout(this.cacheTimeout)` before scheduling a new one.

### LH-04: `performOnFrame` rAF loop keeps running after the popover is destroyed (Low)

- **Where:** `packages/core/src/utils/transition.ts:73-91` (no cancel
  handle), called from `eui-popover.gts:878-884` (`onMutation`, through the
  `mutation-observer` modifier at `:1318`).
- **Mechanism:** after a mutation inside an open popover, it calls
  `positionPopoverFixed` on every frame for the CSS transition duration.
  `willDestroy` cannot cancel it, so frames keep running and keep the
  popover instance alive for up to the transition duration (typically
  250-350 ms). `positionPopover` returns early once `panel` is `null`.
- **Trigger:** closing or unmounting a popover right after its content
  changed. 33 tests ended with a pending frame, and 306 callbacks ran after
  their test had finished, across 15 tests.
- **Evidence (Confirmed, harness):** the `[pending-raf] onFrame @ src/utils/transition.ts:85`
  group in the full report. It is bounded by the transition duration and
  does no work after destroy, so it gets no regression test.
- **Proposed fix:** have `performOnFrame` return a cancel function, keep it
  in the popover and call it in `willDestroy`. Alternatively check
  `isDestroying` in the callback.

### LH-05: static `copy` listeners on `document` are never removed (Low, bounded)

- **Where:** `packages/core/src/components/eui-data-grid.gts:713,716`
  (`copyFocusedDataGridCell`, `onTabularCopy`) and
  `packages/core/src/components/eui-basic-table.gts:334` (`onTabularCopy`),
  added in the constructors.
- **Mechanism:** module-level functions, so the browser deduplicates them:
  at most 2 listeners for the whole app lifetime, and they retain no
  instance. They do run on every copy in the app after the first
  grid/table has mounted. Upstream (`OverrideCopiedTabularContent`)
  removes its listener on unmount.
- **Evidence (Confirmed):** a `document copy` listener from `new EuiDataGrid`
  / `new EuiBasicTable` was reported once per run. The global listener
  count stays flat through the growth runs (delta 0).
- **Proposed fix:** none needed for memory. For parity, ref-count the
  instances and remove the listeners when the last one unmounts.

### LH-06: `EuiComboBox` unmounted while its list is open trips an autotracking assertion (not a leak; Medium, correctness)

- **Where:** EuiComboBox / ember-basic-dropdown (`_isOpen` on `BasicDropdown`).
- **Evidence (Confirmed, dev build):** the first version of the growth test
  (`click('.euiComboBox__inputWrap')` and then unmount) failed with
  `Assertion Failed: You attempted to update '_isOpen' on 'BasicDropdown', but
  it had already been used previously in the same computation`. The growth
  test now presses Escape before unmounting. This is reported for the
  component reviewers: teardown while open writes tracked state during
  render, so cleanup that depends on that path may not run.

### LH-07: the heap creeps by about 17 KB per test across the suite (Low; test artifact, not EUI)

- Heap after `gc()` went from 44 MB at test 100 to 70 MB at test 1500
  (79 MB at the end), with all counters flat, 0 survivors, and CSS rules
  constant at 110.
- **Evidence (Confirmed):** `scripts/heap-histogram.mjs` diff between a
  13-test snapshot (14.8 MB self size) and a full-suite snapshot (63.1 MB).
  The largest growth is *connected* DOM in QUnit's reporter: +47k `<span>`,
  +61k text nodes, +22k `<li>`, and about 2049 each of `<a>`, `<ol>`,
  `<p>`, `<strong>` (one per test result). It also includes +4.8k
  `PerformanceMark` / +2.4k `PerformanceMeasure` from QUnit and
  test-helpers, and about 5 MB of compiled code and feedback vectors as
  more components get exercised. No EUI class shows up in the growth.
- **Proposed fix:** none for EUI.

## Growth measurements

100 cycles after 5 warm-up cycles, `gc()` before each sample. The table
gives bytes per cycle from `usedJSHeapSize` (precise memory info). The
counter deltas cover global listeners, element listeners, observers, timers,
rAFs, body children, head children and CSS rules.

| scenario | B/cycle (0→100) | B/cycle (50→100) | counter deltas |
|---|---:|---:|---|
| control (plain div) | -495 | -113 | 0 |
| EuiDataGrid | 22451 | 2795 | 0 |
| EuiBasicTable | 3571 | -895 | 0 |
| EuiInMemoryTable | 2940 | -1226 | 0 |
| EuiComboBox (open list, Escape, unmount) | 7541 | 4243 | 0 |
| EuiSelectable | 27220 | -480 | 0 |
| EuiSuperDatePicker (quick menu opened) | -38299 | -92754 | 0 |
| EuiPopover (open/close, stays mounted) | 1646 | 2149 | 0 |
| EuiPopover (unmounted while open) | 2062 | 589 | 0 |
| EuiFlyout | 2739 | 481 | 0 |
| EuiModal | 1564 | 374 | 0 |
| EuiToolTip (hover, unmount) | 2178 | 1713 | 0 |
| EuiMarkdownEditor | 7679 | 3498 | 0 |
| EuiCodeBlock | 2411 | -384 | 0 |
| EuiTourStep (mounted open, unmount) | 1963 | -542 | 0 |
| EuiCollapsibleNav (open/close) | 1968 | 1085 | 0 |

A longer run (400 cycles, `&growthCycles=400`) for the components with the
largest first-half numbers settles at the control's noise level: control
1278/1283, DataGrid 9597/**-890**, ComboBox 4676/**1642**,
Selectable 9404/**-1341**, MarkdownEditor 3724/**1260** B/cycle (whole
run / second half). The first-half numbers are warm-up: JIT, lazily
compiled templates, first-use caches. **None of the 13 components grows
per mount/unmount or open/close, and every counter returns to baseline**
(listeners, observers, timers, rAFs, portals, CSS rules: delta 0 in every
scenario). The EuiInputPopover-based ResizeObserver issue (LH-02) does not
show in these scenarios because their args do not change while mounted.

## Classified noise: test artifacts and third-party

- **Third-party, `@atlaskit/pragmatic-drag-and-drop` honey-pot fix**
  (`honey-pot-fix/make-honey-pot-fix.js:220`): after a drop it leaves a
  `<div>` on `<body>` and 7 capture listeners on window (pointerdown,
  pointermove, focusin, focusout, dragstart, dragenter, dragover), which
  remove themselves on the next user interaction. 4 eui-drag-drop tests.
  This is by design and bounded to one at a time. Tests do not send the
  "next interaction".
- **Test artifact, the first test's `<iframe>`:** created during the first
  test only. It is not from EUI (`grep` finds no iframe creation in `src`),
  and ember-basic-dropdown's `getScrollLineHeight` iframe removes itself.
  Once per run.
- **Test artifact, `Leak | regressions` timers:** the 60 s timers come from
  the LH-03 regression test itself.
- **Test artifact, windows opened by tests:** `Borealis button empty/icon ::
  disabled and loading states for buttons and links` and `native state
  transitions preserve attributes, events and toggle semantics` click
  `target=_blank` links (see the environment notes).
- **Third-party, ember-source:** LH-01.
- ember-basic-dropdown, QUnit and `@ember/test-helpers`: nothing was left
  behind after teardown.

## Checked and found clean

Across the full run with the LH-01 workaround on, the following were clean.
After teardown, no test left a listener on window, document, `<html>`,
`<body>`, visualViewport or a MediaQueryList, other than LH-05 and the
pragmatic-drag-and-drop honey pot. No test left a listener on a connected
element outside the test root.

- **Focus traps:** no active focus-trap was left. Its document listeners were
  always removed. This covers modal, flyout, popover, collapsible nav, tour,
  data grid header cells, combo box options and the code block fullscreen.
- **Observers:** no MutationObserver or IntersectionObserver was left
  connected. ResizeObserver was clean apart from LH-02.
- **Timers:** no `setInterval` survived teardown. That includes the
  auto-refresh/refresh interval components, EuiSuperDatePicker's
  `@isAutoRefreshOnly` and the toasts. No `requestIdleCallback` survived.
  The pending setTimeouts were LH-03 only, and the pending rAFs LH-04 only.
- **Ember run loop:** 0 `later`/`debounce`/`throttle` timers after any
  teardown.
- **Portals:** no portalled DOM left on `<body>` by any EUI component
  (flyouts, modals, popovers, tooltips, toasts, `EuiPortal`, combo box and
  selectable lists, tours, bottom bar), except the pragmatic-drag-and-drop
  honey pot.
- **Retained objects:** after `gc()`, 0 of 1847 test owners and 0 of 2073
  test roots survived, apart from the LH-03 regression test's own owner and
  root, kept by its 60 s timers. So no EUI service, module-level registry
  or cache retains a destroyed component's owner or DOM across tests. This
  covers the emotion/`euiClass` caches, the focus-trap registry, the flyout
  manager, the toaster and the i18n and icon caches. Per-component instance
  retention inside one living owner was not measured by WeakRef (see the
  limitation above). The growth table covers it for the 13 heavy
  components.
- **CSS rules and head children:** flat across repeated mounts (emotion
  cache does not grow per instance in these scenarios).

## Files

- `packages/core/tests/leak-detector.ts`: the instrumentation.
- `packages/core/tests/index.html` and `tests/test-helper.ts`: opt-in wiring.
- `packages/core/testem.cjs` and `vite.config.mjs`: `EUI_LEAKS` switches.
- `packages/core/scripts/leaks.sh`: the one-command runner.
  `scripts/leak-cdp.mjs` drives CDP, `scripts/leak-report.mjs` prints the
  summary, `scripts/heap-retainers.mjs` explains retention and
  `scripts/heap-histogram.mjs` aggregates snapshots.
- `packages/core/tests/integration/leaks/growth-test.gts`: the growth runs.
- `packages/core/tests/integration/leaks/leak-regressions-test.gts`: LH-02
  and LH-03, `test.todo`.
- `packages/core/tests/helpers/leak-counters.ts`: self-contained counters
  for the regression tests, which also work outside leak mode.
