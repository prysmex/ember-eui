# Test coverage audit

Audited 2026-10-10 against the working tree, including the new controlled-tab
regression test. The suite has broad rendering coverage, but inconsistent
coverage of argument changes and state ownership. Those are the most valuable
places to invest to catch bugs like the missing controlled tab panel.

## Scope and measurement

This is a static inventory and a behavioral review of the stateful component
suites and their source. It is not a measured line or branch coverage report,
nor a claim that every public argument has been reviewed.

Counts below are static matches for `test(` in `*test.*` files. Comments and
examples can contribute matches, and imported framework checks can add runtime
tests. These are inventory estimates, not runner totals or scenario counts.

| Suite | Test files | Static test calls |
| --- | ---: | ---: |
| Core | 105 | 445 |
| Changeset form | 2 | 21 |
| Validated form | 3 | 22 |
| Flatpickr | 1 | 7 |
| Pikaday | 1 | 6 |
| Documentation site | 2 | 10 |
| Total | 114 | 511 |

Core has 100 component integration test files with 431 static test calls, one
private integration test file, and four unit test files. Of 273 `.gts`
component modules, 202 appear in direct component import references in core
tests and 71 do not. **This is an import inventory, not 74% execution coverage.**
Many remaining modules are exercised through their parents or yielded
components, including range parts, combo-box parts, and draggable/droppable
components. Type-only imports can also appear in this inventory.

26 core test files use `@tracked`; 16 invoke `triggerKeyEvent`. These are search
signals for review, not proof of reactive or keyboard coverage. For example,
some tracked values exist only in a test owner callback and do not verify an
independent external argument update.

No configured coverage instrumentation or thresholds were found in the package
scripts, Vite configuration, or CI. No `test.skip` or `test.todo` registrations
were found in the searched test sources.

Runtime verification was initially blocked: `pnpm` was absent, the installed
Vite binary lacked `@rollup/rollup-linux-arm64-gnu`, and the environment ran Node
22 while the workspace requires Node 24. The follow-up installed temporary
Node 24/native tooling and a compatible Chromium binary outside the repository
to run the existing Vite/Testem suite. CI installs Node 24 and dependencies from
the frozen lockfile.

## What already protects us

- `.github/workflows/ci.yml` runs builds, lint/types, API documentation checks,
  and all package/site tests via `pnpm turbo test --continue`. Tests are not
  cached by Turbo and run in headless Chrome.
- Core's `tests/index.html` eagerly discovers test modules. Existing tests
  check actual templates, accessibility attributes, and interactions.
- `eui-super-date-picker-test.gts` is a useful model: it verifies independent
  start/end changes, invalid-to-valid transitions, local selection surviving
  rerenders, new arguments taking precedence, and refresh/pause behavior.
- Accordion tests cover an external `forceState` change and loading-to-ready
  content. Flatpickr explicitly tests updating `@date`.
- Combo-box tests cover selection/removal/creation, grouped options, and real
  CSS regressions. Drag/drop and resizable-container tests exercise pointer
  and keyboard behavior. These are more substantial than render smoke tests.
- Site acceptance tests visit every enabled documentation page and exercise
  selected demos, theme changes, and route bundles. Page rendering does not
  establish behavioral coverage of each demo.

## Findings and prioritized cases

Paths in this table are under `packages/core` unless indicated otherwise.
Missing cases are confirmed by reviewing the corresponding tests; source risks
are separately labeled and need a browser regression test before being treated
as reproduced bugs.

| Priority | Area and evidence | Cases to add |
| --- | --- | --- |
| P1 | **Tabbed content focus and edge cases.** `tests/integration/components/eui-tabs-test.gts` now covers controlled panel selection, but has no focus-entry tests. `src/components/eui-tabbed-content.gts` still queries focus targets using `selectedTabId`, which is unset in controlled mode, and dereferences the result without a null check. This is a source-level risk adjacent to the fixed bug. | Controlled `@autoFocus="selected"`; keyboard entry/exit and re-entry; empty tabs; removed selected tab; tab IDs requiring CSS escaping. Assert actual focus and absence of exceptions. Verify the tab/panel ID relationship as well as panel text. |
| P1 | **Refresh interval external updates.** `eui-refresh-interval-test.gts` updates owner state through callbacks, but never independently replaces `@refreshInterval`. The source initializes local value/units in its constructor with no synchronization for subsequent argument changes. | Change the owner interval from 5 seconds to 2 minutes after render; assert both fields, accessible description, and the next callback payload. Also test zero/negative values and unit boundaries. Source suggests stale fields; runtime reproduction is pending. |
| P1 | **Pagination and table state.** `eui-pagination-test.gts` records clicks using a fixed active page. `eui-table-test.gts` records page-size/sort callbacks without updating owner arguments and checking the resulting UI. | Owner accepts a page click: active marker and next/previous labels update. Owner ignores it: displayed page stays put. Independently change active page, page count, page size, and sort direction. Check zero/one page and first/last-page boundaries. |
| P1 | **Range and dual range.** `eui-range-test.gts` verifies rendering and callbacks, mostly with literal values or a no-op owner. It does not establish that input, tooltip, tick selection, and thumb state stay synchronized after independent value updates. | Update owner values after render, including `0`; update min/max/step; assert numeric input, tooltip, selected ticks, highlight, and `aria-valuenow`. Exercise lower/upper crossing and validity payloads. Where a callback returns new values, verify the rendered result. |
| P1 | **Selection controls and option replacement.** Super-select tests verify a callback-driven selection, but not an independent value/options replacement. Selectable tests mutate options through owner callbacks and then primarily inspect owner state. Combo-box has broad interaction tests, but lacks a dedicated independent options/selection replacement test. | Replace arrays with new object instances; change selected value externally; remove the selected option; use empty/all-disabled options; assert displayed selection, selected ARIA state, hidden form value, and keyboard target. Specify expected behavior when the owner ignores callbacks. |
| P2 | **Toast lifecycle.** `eui-global-toast-list-test.gts` has only empty-list and service-add cases. Source includes dismissal, timers, hover pause/resume, double-dismiss prevention, and teardown. | Close button removes a toast and reports dismissal once; automatic expiry; hover pause/resume; duplicate dismissal; destroy while expiry is pending. Prefer deterministic time control over long real waits. |
| P2 | **Popover lifecycle.** `eui-popover-test.gts` covers opening and Escape/outside callbacks, but does not consistently assert closed DOM or focus restoration after dismissal. No core test explicitly uses `clearRender`. | Assert the panel disappears, focus returns appropriately, reopening works, and destroying an open panel removes portaled DOM and listeners. Test nested popovers so dismissing the inner panel does not close the outer panel. Automatic rendering-test teardown is useful but does not assert these contracts. |
| P2 | **Tree updates.** `eui-tree-view-test.gts` covers initial expansion, clicks, and arrows with fixed items. Source seeds expansion state from the initial items. | Replace items after render, remove an active node, and add nested nodes. Define whether `isExpanded` is an initial value or an ongoing control before encoding that behavior. Assert visible nodes and usable keyboard focus. |
| P2 | **Code block updates.** `eui-code-block-test.gts` verifies initial highlighting and that virtualization renders fewer than 500 lines. | Change content/language after render; verify new text/tokens; scroll a virtualized block and assert expected later lines; exercise fullscreen/copy controls and teardown. A bounded DOM count alone does not prove scrolling works. |
| P2 | **Date-picker depth.** Super-date-picker tests cover several valuable state transitions, but do not exercise the absolute/relative/now editor tabs. `packages/pikaday/tests/integration/components/eui-pikaday-test.gts` has no independent selected-date update case. | Edit start/end through each editor, verify callbacks and displayed ranges, then change arguments externally. Add Pikaday external date/min/max updates and calendar teardown checks. |

Several test names overstate what they exercise. Examples:

- The refresh interval test says “starts and stops,” but clicks Start once and
  never clicks Stop.
- The color-picker test says “Enter toggles, arrow down opens,” but exercises
  only ArrowDown. Its “rgba format, alpha and clearing” case checks alpha
  presence and format, without changing alpha or clearing.
- The color-stops test says a popover edits value and color, but checks its
  initial contents and deletes the stop without editing either value.
- The search test says “Enter / change” but only calls `fillIn`, exercising the
  change path.

Add the missing interactions or narrow those names. Review assertions, not test
titles, when deciding that a behavior is protected.

## A repeatable behavioral standard

For each stateful public component, keep a small explicit set of contract cases:

1. Initial/default rendering, with meaningful visible output assertions.
2. Each supported state mode: controlled, local/uncontrolled, or intentionally
   hybrid. Do not impose controlled semantics on components with local drafts.
3. User interaction: callback payload **and** rendered result when the owner
   accepts it. If applicable, verify behavior when the owner ignores it.
4. Independent owner updates after render, without firing the component's
   callback. This catches constructor snapshots and stale derived state.
5. Relevant boundaries: empty, missing, zero, disabled, read-only, invalid,
   removed selection, and replacement collections.
6. Keyboard/focus and accessibility state stay aligned with visible content.
7. Explicit teardown for components owning timers, listeners, observers,
   portaled content, or body/global styles.

Use component-specific DOM assertions rather than a universal helper that only
checks callbacks. Sharing fixtures is reasonable; hiding behavior assertions
behind a generic harness can reproduce the same blind spots across the suite.

For regression fixes, demonstrate that the focused test fails with the old
implementation and passes with the fix. For the tab-panel bug, the assertion
that a controlled selection initially renders “Two” is the key failure check;
tab selected styling alone would miss the bug.

## Recommended implementation order

First cover the P1 cases, starting with tabs/focus and refresh-interval updates,
then pagination/ranges and selection replacement. Resolve any failures against
the documented component contract and retain their regression tests. Next add
lifecycle tests for toast/popover and date-editor interactions.

Once behavioral gaps are addressed, add source-mapped statement/branch coverage
to the existing browser runner, including `.gts` templates. Validate the mapping
against a known missing template branch before adopting a threshold. Start with
a measured baseline and prevent regressions; an arbitrary percentage or direct
import count would reward shallow tests without catching this class of bug.

## Follow-up implementation

The table and counts above record the audit baseline. The follow-up adds 13
tests and strengthens existing assertions across ten component suites:

- Tabs: controlled focus, re-entry, special-character IDs, empty tabs, and
  removal of the selected tab, in addition to the earlier controlled panel test.
- Refresh interval: external updates, local drafts when the owner ignores
  callbacks, zero/invalid keyboard start, and an actual Stop interaction.
- Pagination: accepted/ignored callbacks, independent page changes, and
  zero/one-page boundaries. Table pagination now checks rendered page and size
  after callbacks and external updates.
- Ranges: external values/bounds, accepted input changes, zero, numeric inputs,
  selected ticks, tooltips, highlights, and accessible dual-range thumb values.
- Selection: replacement options/selection in super-select, combo-box and
  selectable; ignored controlled callbacks and visible selected state.
- Lifecycle: popover panel removal after dismissal and explicit destruction;
  toast dismissal removes the intended service entry and reports it once.

The new browser cases exposed bugs in selected-tab focus/re-entry,
special-character tab IDs, refresh interval synchronization, range highlighting
at zero, and empty pagination navigation. The implementation fixes accompany
their regression tests. The remaining backlog includes date-editor depth,
tree/code-block updates, and more extensive timer/focus lifecycle coverage.

Validation: the final Vite test bundle passes all 456 runtime tests in headless
Chromium, with zero failures or skips. Before the fixes, the focused browser run
failed on selected autofocus, special-character tab IDs, interval
synchronization, zero range highlighting, and empty pagination navigation.
