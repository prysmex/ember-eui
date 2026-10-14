# Memory leak audit (2026-10-14)

Ember EUI `master` (v16.0.0), audited four ways:

| Report | Approach |
| --- | --- |
| [leak-harness.md](leak-harness.md) | The whole core suite in an opt-in leak mode: listeners, observers, timers, focus traps, portals and retained apps after each test, plus 100× mount/unmount and open/close of 13 heavy components |
| [leak-site.md](leak-site.md) | A Chromium crawl of every docs page (CDP), with heap and DOM metrics per pass, per-route bisection and heap snapshots |
| [leak-infra.md](leak-infra.md) | Code review plus targeted tests of services, modifiers, utilities, caches/registries and the companion packages |
| [leak-components.md](leak-components.md) | Code review of all 378 component files, with teardown tests |

Run the detectors again with `scripts/leaks.sh [filter]` in packages/core
(leak mode, ~8 min for the full suite) and `site/tests/leak/README.md` (site
crawl).

## Findings, deduplicated

Status: **Fixed** (on this branch), **Open**. Evidence: C = reproduced by a
test or the crawl, S = code reading.

| # | Severity | Status | Where | What | Reports |
| --- | --- | --- | --- | --- | --- |
| 1 | High | Fixed (ae410e7c) | `modifiers/resize-observer.ts` (core; validated-form has no copy, its docs page used an older installed core) | Every re-run creates a new ResizeObserver without disconnecting the previous one; teardown disconnects only the last. 51 live after 50 re-runs; +39 per whole-site crawl; 155 suite tests end with one connected. Used by EuiToolTip, EuiInputPopover, EuiContextMenuPanel, EuiCodeBlock, markdown editor, EuiBottomBar, EuiResizableContainer, table sticky scrollbar (C) | LH-02, L1, LI-1 |
| 2 | Medium | Fixed | EuiAvatar, EuiTextColor / EuiText / EuiMarkdownFormat, EuiToken, EuiAspectRatio | Per-instance values (image URLs, custom colors, ratios) became permanent Emotion classes. Now inline like upstream (C) | F-EMO-1 |
| 3 | Medium | Fixed | `utils/eui/flyout-manager/reducer.ts` | Back closing the last session never reset the z-index counter (upstream bug too), so z-indexes and the mask's classes kept climbing (C) | LI-4, F-EMO-2 |
| 4 | Medium | Fixed (d210270c) | `eui-popover.gts` `registerPanel` | `panelRef(null)` is never sent: a closed popover keeps its detached panel and a window `resize` listener until destroyed; data grid cells keep a stale panel (C) | F-POP-1 |
| 5 | Medium | Fixed | flatpickr `eui-flatpickr.gjs` | Unmounted during setup (lazy `@locale`, same run loop) or two quick `@locale` changes: an orphan picker stays in `<body>` with window/document listeners (C) | LI-6 Fixed in 900ed7c8. |
| 6 | Medium | Fixed | `eui-search-bar/field-value-selection-filter.gts` | A cache-reset timer on every load, only the last cleared; each holds the destroyed component (C) | LH-03, L2, F-MISC-3 Fixed in ba21c094. |
| 7 | Medium | Documented (78bdb590) | `@css` (all components) | Each distinct dynamic `@css` value adds a full copy of the component's rules, never removed. Same as React EUI (Emotion is append-only). Documented in docs/theming.md and the `EuiCss` JSDoc: keep `@css` static, use `style` for values that change (C) | LI-2 |
| 8 | Low | Fixed | `eui-saturation.gts`, color stop thumb, data grid body | Drag listeners on `document` removed only on mouseup/pointerup; unmount mid-drag leaves them (C for saturation) | F-DRAG-1/2 Fixed in 3c4e9d8f. |
| 9 | Low | Fixed | `eui-global-toast-list.gts` | Dismissed timer ids never pruned; timers of toasts removed by the app still fire (S) | F-TOAST-1/2 Fixed in d11eb563. |
| 10 | Low | Fixed | `eui-data-grid.gts`, `eui-basic-table.gts` | One permanent shared `copy` listener on `document` each (C) | F-GLOB-1, LH-05 Fixed in 59bcb679. |
| 11 | Low | Fixed (65e3fdf7, d210270c, 9ca3d9c1) | EuiToolTip `updateAttachTo`, EuiRange blur `later`, EuiColorPicker `next`, markdown drop zone `insertText`, data grid column actions `setTimeout`, EuiFocusTrap outside click, changeset-form `validate` `later` | Deferred callbacks without a destroyed check (one tick to 200 ms); the tooltip one can leave listeners on the `@attachTo` element (S) | F-TIP-1, F-MISC, LI-7 Guards fixed in 65e3fdf7 (EuiRange/EuiDualRange, EuiColorPicker, EuiFocusTrap, changeset-form); the data grid column actions timeout is left as is (it only captures the grid, and must run after the header unmounts); the tooltip guard is fixed in d210270c; the drop zone belongs to the demos fix. |
| 12 | Low | Fixed (d210270c) | `eui-overlay-mask.gts` | `@maskRef(null)` never sent (S) | F-MISC-4 |
| 13 | Low | Fixed (d210270c) | EuiPopover `performOnFrame` | Animation-frame loop runs on after destroy, bounded by the transition (C) | LH-04 |
| 14 | Low | Fixed (d210270c) | `outsideClickDetector` | One extra destructor per update, released with the modifier; no listener leak (C) | LI-5 |
| 15 | Low | Accepted | Emotion per theme, `euiToaster` queue, `htmlIdGenerator` warnings, split-button color memo, first-use style variants | Bounded in normal use; unbounded only with live theme overrides / arbitrary strings (C/S) | LI-3, LI-8, LI-9, LI-10, L3 |

#11, markdown drop zone `insertText` part: Fixed (9ca3d9c1). The other #11 callbacks belong to other fixes.

Not EUI:
- **ember-source 7.3 `renderComponent`** (used by `render()` in tests) never releases a test's app or DOM, ~5 MB per test. Report upstream. Leak mode works around it (LH-01).
- **`@atlaskit` drag-and-drop auto-scroll** logs a warning with a DOM element on every render; DevTools keeps those nodes while open (S1).

Bugs found along the way (not leaks):
- EuiComboBox unmounted while its list is open throws an autotracking assertion in development builds (LH-06). Fixed (d210270c).
- Fixed (70aba706): the comment list and markdown editor demos threw `TypeError: … reading 'start'` (leak-site.md). `getCursorNode` had lost upstream's `child.position` check; remark-intraword-underscore makes nodes without a position.
- Fixed (2dc7177f): a tracking assertion on `isTouched` in a validated-form demo (leak-site.md). Chrome fires `focusout` when the focused element is removed mid-render; ValidatedForm now touches the field after render.

## Clean

Focus traps and the focus-trap registry; modal, flyout and the rest of the
flyout manager; tooltip, combo box, super date picker auto-refresh, toasts on
destroy; data grid, tables, code block, markdown editor, resizable container,
drag and drop; EuiEmotionProvider listeners and global styles;
`containerQuery`, form-row MutationObservers; pikaday; validated-form
registration; intervals, IntersectionObservers, portals and detached DOM
across the whole docs site; the docs app's own code. None of the 13 heavy
components grows per mount/unmount or open/close.
