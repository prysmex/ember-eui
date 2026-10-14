# Memory-leak audit: components (`packages/core/src/components`)

Branch `eui-leak/leak-components`. Scope: all 378 files under `packages/core/src/components`. Services, modifiers, utils and `-private` belong to the other agent; where a component depends on one, it is noted.
Method: grep hit list (listeners, observers, timers, rAF, runloop `later`/`next`/`throttle`/`schedule`, `in-element`, focus traps, module-level Map/Set/WeakMap, dynamic emotion styles), then every hit read in context and checked for a cleanup that runs on every teardown path. Tests: `packages/core/tests/integration/leaks/components-teardown-test.gts` (5 passing guards, 5 `skip` tests that fail today and document findings; each was run unskipped first and failed as described).

## Summary

| ID | Title | Severity | Status |
|---|---|---|---|
| F-EMO-1 | Emotion cache grows with data-driven styles (avatar image URL, custom colors) | Medium | Confirmed |
| F-POP-1 | `EuiPopover` never emits `panelRef(null)`: stale detached panel and live window resize listener after close | Medium | Confirmed |
| F-EMO-2 | Flyout mask class: one emotion rule per z-index value | Low | Suspected |
| F-DRAG-1 | Saturation / color-stop thumb: document drag listeners removed only on `mouseup` | Low | Confirmed (saturation) |
| F-DRAG-2 | Data grid body: document `pointerup` listener removed only on `pointerup` | Low | Suspected |
| F-GLOB-1 | Data grid and basic table leave a document `copy` listener forever | Low | Confirmed by reading |
| F-TOAST-1 | `EuiGlobalToastList.dismissTimeoutIds` grows by one entry per dismissed toast | Low | Confirmed by reading |
| F-TOAST-2 | Toast timers for toasts removed externally still fire (ghost `@dismissToast`) | Low | Suspected |
| F-TIP-1 | `EuiToolTip.updateAttachTo` `next()` not guarded against destroy | Low | Suspected |
| F-MISC-1..7 | Small unguarded timers / refs (see below) | Low | Suspected |

Counts: High 0, Medium 2, Low 9 groups. Nothing found that leaks per mount/unmount of the heavy families (modal, flyout, tooltip, combo box, super date picker, toasts, tour, markdown editor, code block, resizable container, drag and drop, collapsible nav, header, table, inner text, text truncate, auto sizer): their listeners, observers, timers and portals are released, as the passing guard tests and code reading show.

## Findings

### F-EMO-1 Emotion cache grows with data-driven styles
- **Where:** `eui-avatar.gts:147-231` (`avatarStyle` puts `backgroundImage: url(${imageUrl})` and a custom/derived `backgroundColor` into the object passed to `euiClass`), `eui-text-color.gts:76-83` (custom CSS color), `eui-token.gts:128-150` (custom `@color`), weaker: `eui-aspect-ratio.gts:36-50` (`aspectRatio`/`maxWidth` args). Root: `utils/eui/styles.ts:89` -> `context.cache.css(...)` (`utils/emotion/context.ts:119-134`, owned by the other agent).
- **Mechanism:** each distinct style object adds a permanent rule to the emotion cache's `<style data-emotion>` sheet. The cache is flushed only when the context that created it is destroyed (`EuiThemeContext.destroy`), i.e. at app end for the root provider. Unmounting the component does not remove its rule. Class strings are memoised in `@cached` getters, so the cost is one rule per distinct value ever rendered, not per render.
- **Trigger:** avatars with per-user image URLs (worse with signed or cache-busting URLs: a new rule on every URL change), tokens/text with user-chosen colors, in a long-lived SPA. Bounded only by the number of distinct values.
- **Severity:** Medium (High where URLs or colors are effectively unique per render).
- **Evidence (Confirmed):** skipped tests `avatar: rules for per-instance image URLs are released after unmount` (30 distinct URLs: sheet rule count rises by 32 and stays at +32 after all avatars unmount, expected +0) and `text color: rules for custom colors are released after unmount` (+30 stays +30).
- **Proposed fix:** put per-instance values in inline `style` (or CSS custom properties set via `style`) and keep one static class: `background-image: var(--euiAvatarImage)` with `style="--euiAvatarImage:url(...)"`, same for color. Alternatively an LRU-bounded cache in the emotion wrapper, or refcounting rules per class and removing on last unmount.

### F-POP-1 `EuiPopover` never emits `panelRef(null)`
- **Where:** `eui-popover.gts:1201-1220` (`registerPanel`) wired only with `{{didInsert this.registerPanel}}` at line 1269; the `panel === null` branch (lines 1206-1214: reset state, remove `resize` listener) is dead. Consumers relying on `@panelRef(null)`: `EuiDataGridCell.registerPopoverPanel` (`eui-data-grid/cell.gts:383-387`, removes the keydown listener from the previous panel and adds one to the next, never sees null), `EuiInputPopover` (`didInsertPanel`).
- **Mechanism:** after the panel closes (portal content removed) `popover.panel` keeps pointing at the detached panel element, `window` keeps the `positionPopoverFluid` resize listener (which references the popover and, through `this.panel`, the detached subtree) and `isOpenStable`, `popoverStyles`, arrow state are not reset. Cleared only in `willDestroy`.
- **Trigger:** every popover opened at least once keeps a resize handler running `positionPopover` against a detached panel on every window resize, and retains one detached panel, until the popover itself is destroyed. A page with many popovers (table rows, data grid cells with expansion popovers) multiplies this.
- **Severity:** Medium (per instance, per open; bounded by instance lifetime).
- **Evidence (Confirmed):** skipped tests `popover: closing it reports panelRef(null)` (last `panelRef` call is the detached div) and `popover: closing it removes the window resize listener` (listener count 1 after close, expected 0). The guard test `popover: unmounting while open leaves no window listeners or portal` passes, so destroy is fine.
- **Proposed fix:** add a teardown for the panel: `{{didInsert this.registerPanel}}{{willDestroy (fn this.registerPanel null)}}`, or make `registerPanel` a modifier returning `() => this.registerPanel(null)`; also clear `this.panel` there.

### F-EMO-2 Flyout mask z-index class
- **Where:** `eui-flyout.gts:1160-1165` (`maskClass`: `zIndex: ${this.zIndex.mask} !important`), z-index source `mountZIndex` / session z-index from `utils/eui/flyout-manager/reducer.ts:97,168` (`currentZIndex` +2/+3 per flyout, reset to 0 only when no sessions and no unmanaged flyouts remain, lines 107-110).
- **Mechanism:** a new emotion rule per distinct z-index. Bounded while flyouts close; grows without bound when one flyout stays open (or a session persists) while others open and close repeatedly.
- **Severity:** Low. Suspected (reading only). **Fix:** set the mask z-index via inline `style`.

### F-DRAG-1 Drag listeners on `document` removed only by `mouseup`
- **Where:** `eui-saturation.gts:109-121`, `eui-color-stops/thumb.gts:171-196` (the `move`/`up` closures are local; no component teardown). `eui-dual-range.gts:253-281` does it right (cleanup in the modifier).
- **Mechanism:** unmounting mid-drag (picker popover closes via Escape/blur while the mouse is down), or a `mouseup` that never reaches the document, leaves `mousemove`/`mouseup` on `document` holding the component, its `box` element and `onChange`. Self-heals on the next `mouseup` anywhere, so practical impact is small.
- **Severity:** Low. **Evidence (Confirmed):** skipped test `saturation: unmounting mid-drag removes the document drag listeners` (1 `mousemove` listener after `clearRender`). **Fix:** keep the cleanup in a field and call it from `willDestroy` (or use a modifier), also handle `blur`/`pointercancel`.

### F-DRAG-2 Data grid body `pointerup`
- **Where:** `eui-data-grid/body.gts:636-653` (`onPointerDown` adds a capturing `pointerup` listener removed only on `pointerup`). Same shape, same self-healing. Low, Suspected. Fix as F-DRAG-1.

### F-GLOB-1 Document `copy` listeners never removed
- **Where:** `eui-data-grid.gts:713-716` (`copyFocusedDataGridCell`, `onTabularCopy`), `eui-basic-table.gts:334` (`onTabularCopy`).
- **Mechanism:** module-level handler functions, so `addEventListener` dedupes: one permanent listener per page, not per instance. They hold no component, so no retention; it is permanent work (a cheap handler) on every `copy` after the first grid or table mounted.
- **Severity:** Low. Confirmed by reading. **Fix:** ref-count mounted grids/tables and remove at zero, or register once in a service.

### F-TOAST-1 / F-TOAST-2 Global toast list bookkeeping
- **Where:** `eui-global-toast-list.gts:344-352` (`dismissTimeoutIds.push(...)` never pruned; only cleared timers on destroy), `scheduleToastForDismissal` / `toastIdToTimerMap`.
- **Mechanism (TOAST-1):** one number per dismissed toast for the lifetime of the list, which is normally the app lifetime. Tiny but unbounded. Fix: remove the id inside its own timeout callback.
- **Mechanism (TOAST-2):** a toast removed from `@toasts`/the service by the consumer (not through the list's dismiss) keeps its `Timer` in `toastIdToTimerMap` until it fires, then calls `@dismissToast` for a toast that is already gone. Bounded by `toastLifeTimeMs`; unbounded if a huge/`Infinity`-like life time is used. Fix: reconcile the timer map with `@toasts` on update (clear timers of toasts that disappeared).
- **Severity:** Low. TOAST-1 Confirmed by reading; TOAST-2 Suspected. Destroy is fine: guard test `global toast list: pending dismissal timers do not fire after teardown` passes.

### F-TIP-1 `EuiToolTip.updateAttachTo`
- **Where:** `eui-tool-tip.gts:337-348`: `next(() => { removeAttachToHandlers(); this._attachTo = ...; this.setupAttachToHandlers(); })` has no `isDestroying` guard. If the tooltip is destroyed in the same tick, `setupAttachToHandlers` adds `mousemove/focusin/mouseout/focusout` listeners to the external `@attachTo` element after `willDestroy` already ran, and they are never removed (they hold the destroyed tooltip). Low (race window of one tick), Suspected. Fix: guard with `isDestroying/isDestroyed` or store and cancel the `next`.
- Note: `onKeyUp`/`hasFocusMouseMoveListener` (lines 630-636) would leak a `window` mousemove listener (not removed in `willDestroy`), but `onKeyUp` is not wired in the template, so it is dead code today. Remove it or clean it up before wiring.

### F-MISC (small, Low, Suspected)
1. `eui-range.gts:305-325` `onInputBlur` schedules `later(this, ..., 200)` that is never cancelled: after unmount within 200 ms it calls `@onBlur` and sets state on a destroyed component. Fix: store and `cancel` in `willDestroy`.
2. `eui-color-picker.gts:371` `next(this, this.closeColorSelector)` unguarded (benign: sets a flag on a destroyed object).
3. `eui-search-bar/field-value-selection-filter.gts:148-153` overwrites `cacheTimeout` on each load without clearing the previous timer; `registerDestructor` clears only the last. Older timers fire later and also null the cache early.
4. `eui-overlay-mask.gts` `{{callWith @maskRef}}` has no cleanup, so `maskRef(null)` is never sent (consumer keeps the detached mask). Also relies on the `-private` `setBodyClass` helper being ref-counted (other agent).
5. `eui-markdown-editor-drop-zone.gts:262-278` `Promise.all(...).then(insertText)` calls `insertText` after the drop zone is destroyed (the state setters are guarded, `insertText` is not).
6. `eui-data-grid/column-actions.gts:236-240` `setTimeout(... grid.setFocusedCell ...)` unguarded (header-row.gts:142 is guarded).
7. `eui-focus-trap.gts:271-279` `setTimeout(() => onClickOutside)` after `closeOnMouseup` fires even if the trap was destroyed (callback runs, no retention beyond the tick).

## Dependencies on the other agent's areas
- `EuiFocusTrap`, `EuiPopover`, `EuiModal`, `EuiFlyout`: `createRegisteredFocusTrap`, `attachToFocusTraps` (`-private`), focus-trap registry.
- `EuiFlyout`: `euiFlyoutManager` service (`manager.useContainer` release, `addFlyout`/`closeFlyout` called in `afterRender` from modifier teardown; sessions state).
- `EuiToolTip`: `toolTipManager` (`registerTooltip`/`deregisterToolTip` are balanced in `willDestroy` here).
- `EuiOverlayMask`/body-class helper `setBodyClass`; `EuiResizeObserver`/`resizeObserver`, `mutationObserver`, `outsideClickDetector` modifiers; `utils/detect-element-resize.js` (`EuiAutoSizer`: removing the listener removes the trigger DOM but an in-flight `__resizeRAF__` is not cancelled; harmless).
- Emotion cache and `useEuiBorealisStyles` memoisation (F-EMO-1 root).

## Checked and found clean (highlights)
- **Popovers/tooltips:** `EuiPopover` timers (`later`), rAF (`updateFocus`, closing transition) and scroll listener are cancelled in `willDestroy`; panel prop listeners removed by modifier cleanup. `EuiToolTip` rAF `testAnchor` loop ends on destroy (its `_anchor` becomes null), `later` cancelled, `toolTipManager` deregistered, window listeners removed (guard test). `EuiToolTipPopover` removes its resize listener and body class.
- **Modals/flyouts/overlays:** focus traps are modifier-driven (`focusTrap`, cleanup by ember-focus-trap; `EuiFocusTrap` `trapEffects` returns a cleanup for document/window listeners, scroll lock and isolation). `EuiFlyout`: window keydown/resize/scroll/drag listeners in modifier cleanup or `registerDestructor`; both ResizeObservers disconnected; rAF callbacks guarded; manager registration released on teardown (guard test: window listeners back to baseline after unmount). `EuiPortal` removes its node. `EuiOverlayMask` is `in-element` into `body`, torn down by Glimmer.
- **Data grid:** cell focus registry (`onFocusUpdate`) returns an unregister (identity-checked); `ResizeObserver`s via `observeResize` (cancels rAF + disconnects); MutationObservers disconnected; column resizer removes window listeners in `willDestroy`; in-memory renderer's detached `in-element` container dies with the component; header drag-and-drop and auto-scroll return pragmatic-dnd cleanups; `body.paddingBottom`/class and fullscreen body class restored by modifier cleanup.
- **Tables:** sticky header/scrollbar observers and scroll listeners in modifier cleanup; `STICKY_ROWS` is a `WeakMap` keyed by the table; `stickyCells` Set entries removed on teardown.
- **Combo box / selectable:** scroll listener + its 500 ms arming timer cleaned by `stopListeningToScroll` (called on close and in `willDestroy`); `ResizeObserver` disconnected; async options/search promises guarded by `isDestroying`; `watchedPromises` is a `WeakSet`; `EuiSelectable` MutationObserver disconnected; list `ResizeObserver` cancels its rAF.
- **Super date picker / refresh:** the auto-refresh modifier stops on teardown and while awaiting `@onRefresh` (guard test passes: no call after `clearRender`); update-button and popover-button timers cancelled in `willDestroy`.
- **Toasts:** list rAFs and dismiss timers cancelled in `willDestroy` (guard test passes).
- **Tour, markdown editor, code block, resizable container, DnD, collapsible nav, header, inner text, text truncate, auto sizer:** cleanups present as listed in the coverage table (`registerDestructor` for DnD context monitors, panel/resizer registries deregistered, body padding/header counters balanced, observers disconnected, rAFs cancelled).
- **Module-level state in components:** only `WeakMap`s keyed by elements/objects (`renderedHtml`, `STICKY_ROWS`, `sawLoading`, `applied`), constant `Set`s, the `PANELLED` Map in `eui-basic-table.gts:312` (keyed by breakpoint name; bounded by the finite breakpoint values), and the header fixed-count counter (balanced). No module-level registry holds component instances.

## Coverage table
Verdicts: "clean (no lifecycle code)" = grep found no listener/observer/timer/portal/async/module-state construct and the file is presentational; "clean (reviewed, teardown present)" = such constructs exist and were read, with a matching cleanup; otherwise finding IDs.

| File (under `packages/core/src/components`) | Verdict |
|---|---|
| `common.ts` | clean (no lifecycle code) |
| `eui-accordion.gts` | clean (reviewed, teardown present) |
| `eui-aspect-ratio.gts` | F-EMO-1 (finite, low) |
| `eui-auto-refresh-button.gts` | clean (no lifecycle code) |
| `eui-auto-refresh.gts` | clean (no lifecycle code) |
| `eui-auto-sizer.gts` | clean (low note: pending rAF in utils/detect-element-resize) |
| `eui-avatar.gts` | F-EMO-1 |
| `eui-badge-group.gts` | clean (no lifecycle code) |
| `eui-badge.gts` | clean (reviewed, teardown present) |
| `eui-banner.gts` | clean (no lifecycle code) |
| `eui-basic-table-panel.gts` | clean (no lifecycle code) |
| `eui-basic-table.gts` | F-GLOB-1 (document copy listener); PANELLED Map bounded by breakpoint values |
| `eui-basic-table/collapsed-item-actions.gts` | clean (no lifecycle code) |
| `eui-basic-table/default-item-action.gts` | clean (no lifecycle code) |
| `eui-basic-table/expanded-item-actions.gts` | clean (no lifecycle code) |
| `eui-basic-table/pagination-bar.gts` | clean (reviewed, teardown present) |
| `eui-beacon.gts` | clean (no lifecycle code) |
| `eui-beta-badge.gts` | clean (no lifecycle code) |
| `eui-bottom-bar.gts` | clean |
| `eui-breadcrumbs.gts` | clean (reviewed, teardown present) |
| `eui-button-content.gts` | clean (no lifecycle code) |
| `eui-button-empty.gts` | clean (no lifecycle code) |
| `eui-button-group-button.gts` | clean (reviewed, teardown present) |
| `eui-button-group.gts` | clean (no lifecycle code) |
| `eui-button-icon.gts` | clean (reviewed, teardown present) |
| `eui-button.gts` | clean (reviewed, teardown present) |
| `eui-call-out.gts` | clean (reviewed, teardown present) |
| `eui-card-select.gts` | clean (no lifecycle code) |
| `eui-card.gts` | clean (reviewed, teardown present) |
| `eui-checkable-card.gts` | clean (no lifecycle code) |
| `eui-checkbox-group.gts` | clean (no lifecycle code) |
| `eui-checkbox.gts` | clean (reviewed, teardown present) |
| `eui-code-block.gts` | clean (WeakMap keyed by element; observers disconnected) |
| `eui-code-block/annotation.gts` | clean (no lifecycle code) |
| `eui-code-block/controls.gts` | clean (no lifecycle code) |
| `eui-code-block/full-screen-display.gts` | clean (reviewed, teardown present) |
| `eui-code-block/virtualized.gts` | clean (reviewed, teardown present) |
| `eui-code.gts` | clean (reviewed, teardown present) |
| `eui-collapsible-nav-group.gts` | clean (no lifecycle code) |
| `eui-collapsible-nav.gts` | clean (reviewed, teardown present) |
| `eui-color-palette-display.gts` | clean (no lifecycle code) |
| `eui-color-palette-picker.gts` | clean (no lifecycle code) |
| `eui-color-picker-swatch.gts` | clean (no lifecycle code) |
| `eui-color-picker.gts` | F-MISC-2 (next() unguarded, benign) |
| `eui-color-stops.gts` | clean (reviewed, teardown present) |
| `eui-color-stops/thumb.gts` | F-DRAG-1 |
| `eui-combo-box-pill.gts` | clean (no lifecycle code) |
| `eui-combo-box.gts` | clean (scroll timer+listener, ResizeObserver, promises guarded) |
| `eui-combo-box/create-option.gts` | clean (no lifecycle code) |
| `eui-combo-box/group.gts` | clean (no lifecycle code) |
| `eui-combo-box/no-matches-message.gts` | clean (no lifecycle code) |
| `eui-combo-box/node.gts` | clean (no lifecycle code) |
| `eui-combo-box/option-text.gts` | clean (no lifecycle code) |
| `eui-combo-box/options.gts` | clean (reviewed, teardown present) |
| `eui-combo-box/search-message.gts` | clean (no lifecycle code) |
| `eui-combo-box/trigger.gts` | clean (no lifecycle code) |
| `eui-combo-box/trigger/input.gts` | clean (reviewed, teardown present) |
| `eui-comment-list.gts` | clean (no lifecycle code) |
| `eui-comment-timeline.gts` | clean (no lifecycle code) |
| `eui-comment.gts` | clean (no lifecycle code) |
| `eui-confirm-modal.gts` | clean (reviewed, teardown present) |
| `eui-container-query.gts` | clean (no lifecycle code) |
| `eui-context-menu-item.gts` | clean (reviewed, teardown present) |
| `eui-context-menu-panel.gts` | clean (reviewed, teardown present) |
| `eui-context-menu.gts` | clean (reviewed, teardown present) |
| `eui-control-bar.gts` | clean |
| `eui-copy.gts` | clean (no lifecycle code) |
| `eui-data-grid-toolbar-control.gts` | clean (no lifecycle code) |
| `eui-data-grid.gts` | F-GLOB-1 (document copy listeners) |
| `eui-data-grid/body-base.ts` | clean (reviewed, teardown present) |
| `eui-data-grid/body.gts` | F-DRAG-2 (pointerup listener, self-heals); observers clean |
| `eui-data-grid/cell-actions.gts` | clean (no lifecycle code) |
| `eui-data-grid/cell.gts` | F-POP-1 (consumer: popoverPanel keeps stale panel); otherwise clean |
| `eui-data-grid/column-actions.gts` | F-MISC-6 (setTimeout unguarded, benign) |
| `eui-data-grid/column-resizer.gts` | clean (reviewed, teardown present) |
| `eui-data-grid/column-selector.gts` | clean (reviewed, teardown present) |
| `eui-data-grid/column-sorting.gts` | clean (reviewed, teardown present) |
| `eui-data-grid/copy-marker.gts` | clean (no lifecycle code) |
| `eui-data-grid/custom-body.gts` | clean (reviewed, teardown present) |
| `eui-data-grid/default-cell-popover.gts` | clean (no lifecycle code) |
| `eui-data-grid/display-selector.gts` | clean (reviewed, teardown present) |
| `eui-data-grid/footer-row.gts` | clean (no lifecycle code) |
| `eui-data-grid/fullscreen-selector.gts` | clean (no lifecycle code) |
| `eui-data-grid/header-cell.gts` | clean (reviewed, teardown present) |
| `eui-data-grid/header-row.gts` | clean (reviewed, teardown present) |
| `eui-data-grid/in-memory-renderer.gts` | clean (reviewed, teardown present) |
| `eui-data-grid/keyboard-shortcuts.gts` | clean (no lifecycle code) |
| `eui-data-grid/pagination.gts` | clean (no lifecycle code) |
| `eui-data-grid/row-model.ts` | clean (reviewed, teardown present) |
| `eui-data-grid/row-tree-hooks.ts` | clean (reviewed, teardown present) |
| `eui-data-grid/row.gts` | clean (reviewed, teardown present) |
| `eui-data-grid/toolbar.gts` | clean (no lifecycle code) |
| `eui-data-grid/tree-cell.gts` | clean (no lifecycle code) |
| `eui-date-picker-range.gts` | clean (no lifecycle code) |
| `eui-delay-hide.gts` | clean (reviewed, teardown present) |
| `eui-delay-render.gts` | clean (reviewed, teardown present) |
| `eui-described-form-group.gts` | clean (no lifecycle code) |
| `eui-description-list-description.gts` | clean (no lifecycle code) |
| `eui-description-list-title.gts` | clean (no lifecycle code) |
| `eui-description-list.gts` | clean (no lifecycle code) |
| `eui-drag-drop-context.gts` | clean (registerDestructor) |
| `eui-draggable.gts` | clean (pragmatic-dnd cleanup) |
| `eui-droppable.gts` | clean |
| `eui-dual-range.gts` | clean (reviewed, teardown present) |
| `eui-emotion-button.gts` | clean (no lifecycle code) |
| `eui-emotion-provider.gts` | clean (reviewed, teardown present) |
| `eui-empty-prompt.gts` | clean (no lifecycle code) |
| `eui-error-message.gts` | clean (no lifecycle code) |
| `eui-expression.gts` | clean (no lifecycle code) |
| `eui-facet-button.gts` | clean (no lifecycle code) |
| `eui-facet-group.gts` | clean (no lifecycle code) |
| `eui-field-number.gts` | clean (reviewed, teardown present) |
| `eui-field-password.gts` | clean (reviewed, teardown present) |
| `eui-field-search.gts` | clean (reviewed, teardown present) |
| `eui-field-text.gts` | clean (no lifecycle code) |
| `eui-file-picker.gts` | clean (reviewed, teardown present) |
| `eui-filter-button.gts` | clean (reviewed, teardown present) |
| `eui-filter-group.gts` | clean (no lifecycle code) |
| `eui-filter-select-item.gts` | clean (no lifecycle code) |
| `eui-flex-grid.gts` | clean (reviewed, teardown present) |
| `eui-flex-group.gts` | clean (no lifecycle code) |
| `eui-flex-item.gts` | clean (reviewed, teardown present) |
| `eui-flyout-body.gts` | clean (no lifecycle code) |
| `eui-flyout-footer.gts` | clean (no lifecycle code) |
| `eui-flyout-header.gts` | clean (no lifecycle code) |
| `eui-flyout-menu.gts` | clean (no lifecycle code) |
| `eui-flyout-resizable.gts` | clean (no lifecycle code) |
| `eui-flyout-resize-button.gts` | clean (no lifecycle code) |
| `eui-flyout.gts` | F-EMO-2 (mask class per z-index); listeners/observers/rAF verified clean |
| `eui-focus-trap.gts` | F-MISC-7 (setTimeout in closeOnMouseup release, benign); depends on -private createRegisteredFocusTrap |
| `eui-form-append.gts` | clean (no lifecycle code) |
| `eui-form-control-button.gts` | clean (no lifecycle code) |
| `eui-form-control-layout-clear-button.gts` | clean (no lifecycle code) |
| `eui-form-control-layout-custom-icon.gts` | clean (no lifecycle code) |
| `eui-form-control-layout-delimited.gts` | clean (no lifecycle code) |
| `eui-form-control-layout-icons.gts` | clean (no lifecycle code) |
| `eui-form-control-layout.gts` | clean (no lifecycle code) |
| `eui-form-control-layout/eui-form-append-prepend.gts` | clean (no lifecycle code) |
| `eui-form-error-text.gts` | clean (no lifecycle code) |
| `eui-form-fieldset.gts` | clean (no lifecycle code) |
| `eui-form-help-text.gts` | clean (no lifecycle code) |
| `eui-form-label.gts` | clean (no lifecycle code) |
| `eui-form-legend.gts` | clean (no lifecycle code) |
| `eui-form-prepend.gts` | clean (no lifecycle code) |
| `eui-form-row.gts` | clean (no lifecycle code) |
| `eui-form.gts` | clean (reviewed, teardown present) |
| `eui-global-toast-list.gts` | F-TOAST-1, F-TOAST-2 |
| `eui-header-alert.gts` | clean (no lifecycle code) |
| `eui-header-breadcrumbs.gts` | clean (no lifecycle code) |
| `eui-header-link.gts` | clean (no lifecycle code) |
| `eui-header-links.gts` | clean (reviewed, teardown present) |
| `eui-header-logo.gts` | clean (no lifecycle code) |
| `eui-header-logo/elastic-logo-full.gts` | clean (no lifecycle code) |
| `eui-header-section-item-button.gts` | clean (reviewed, teardown present) |
| `eui-header-section-item.gts` | clean (no lifecycle code) |
| `eui-header-section.gts` | clean (no lifecycle code) |
| `eui-header.gts` | clean (module counter balanced by modifier teardown) |
| `eui-health.gts` | clean (no lifecycle code) |
| `eui-hide-for.gts` | clean (no lifecycle code) |
| `eui-highlight.gts` | clean (no lifecycle code) |
| `eui-horizontal-rule.gts` | clean (no lifecycle code) |
| `eui-hue.gts` | clean (no lifecycle code) |
| `eui-i18n-number.gts` | clean (no lifecycle code) |
| `eui-i18n.gts` | clean (no lifecycle code) |
| `eui-i18n/render.gts` | clean (no lifecycle code) |
| `eui-icon-tip.gts` | clean (no lifecycle code) |
| `eui-icon.gts` | clean (reviewed, teardown present) |
| `eui-illustration.gts` | clean (no lifecycle code) |
| `eui-image.gts` | clean (reviewed, teardown present) |
| `eui-in-memory-table.gts` | clean (no lifecycle code) |
| `eui-inline-edit-text.gts` | clean (no lifecycle code) |
| `eui-inline-edit-title.gts` | clean (no lifecycle code) |
| `eui-inline-edit/eui-inline-edit-form.gts` | clean (reviewed, teardown present) |
| `eui-inner-text.gts` | clean (reviewed, teardown present) |
| `eui-input-popover.gts` | clean (reviewed, teardown present) |
| `eui-key-pad-menu-item.gts` | clean (no lifecycle code) |
| `eui-key-pad-menu.gts` | clean (no lifecycle code) |
| `eui-link.gts` | clean (reviewed, teardown present) |
| `eui-list-group-item.gts` | clean (reviewed, teardown present) |
| `eui-list-group.gts` | clean (no lifecycle code) |
| `eui-live-announcer.gts` | clean |
| `eui-loading-chart.gts` | clean (no lifecycle code) |
| `eui-loading-content.gts` | clean (no lifecycle code) |
| `eui-loading-elastic.gts` | clean (no lifecycle code) |
| `eui-loading-logo.gts` | clean (no lifecycle code) |
| `eui-loading-spinner.gts` | clean (no lifecycle code) |
| `eui-mark.gts` | clean (no lifecycle code) |
| `eui-markdown-editor-drop-zone.gts` | F-MISC-5 (insertText after destroy, benign) |
| `eui-markdown-editor-footer.gts` | clean (no lifecycle code) |
| `eui-markdown-editor-footer/icons/markdown-logo.gts` | clean (no lifecycle code) |
| `eui-markdown-editor-text-area.gts` | clean (no lifecycle code) |
| `eui-markdown-editor-toolbar.gts` | clean (no lifecycle code) |
| `eui-markdown-editor-toolbar/icons/markdown-checkmark.gts` | clean (no lifecycle code) |
| `eui-markdown-editor.gts` | clean (reviewed, teardown present) |
| `eui-markdown-format.gts` | clean (reviewed, teardown present) |
| `eui-markdown-format/markdown-checkbox.gts` | clean (no lifecycle code) |
| `eui-markdown-format/markdown-code-block.gts` | clean (no lifecycle code) |
| `eui-markdown-format/markdown-code.gts` | clean (no lifecycle code) |
| `eui-markdown-format/markdown-horizontal-rule.gts` | clean (no lifecycle code) |
| `eui-markdown-format/markdown-link.gts` | clean (no lifecycle code) |
| `eui-markdown-format/markdown-tooltip.gts` | clean (no lifecycle code) |
| `eui-modal-body.gts` | clean (no lifecycle code) |
| `eui-modal-footer.gts` | clean (no lifecycle code) |
| `eui-modal-header-title.gts` | clean (no lifecycle code) |
| `eui-modal-header.gts` | clean (no lifecycle code) |
| `eui-modal.gts` | clean (reviewed, teardown present) |
| `eui-notification-badge.gts` | clean (no lifecycle code) |
| `eui-notification-event-messages.gts` | clean (no lifecycle code) |
| `eui-notification-event-meta.gts` | clean (no lifecycle code) |
| `eui-notification-event-read-button.gts` | clean (no lifecycle code) |
| `eui-notification-event-read-icon.gts` | clean (no lifecycle code) |
| `eui-notification-event.gts` | clean (no lifecycle code) |
| `eui-overlay-mask.gts` | F-MISC-4 (maskRef never nulled); depends on -private setBodyClass |
| `eui-page-body.gts` | clean (no lifecycle code) |
| `eui-page-content-body.gts` | clean (no lifecycle code) |
| `eui-page-content-header-section.gts` | clean (no lifecycle code) |
| `eui-page-content-header.gts` | clean (no lifecycle code) |
| `eui-page-content.gts` | clean (no lifecycle code) |
| `eui-page-header-content.gts` | clean (no lifecycle code) |
| `eui-page-header-section.gts` | clean (no lifecycle code) |
| `eui-page-header.gts` | clean (no lifecycle code) |
| `eui-page-section.gts` | clean (no lifecycle code) |
| `eui-page-side-bar.gts` | clean (no lifecycle code) |
| `eui-page-sidebar.gts` | clean (no lifecycle code) |
| `eui-page-template.gts` | clean (reviewed, teardown present) |
| `eui-page-template/bottom-bar.gts` | clean (reviewed, teardown present) |
| `eui-page-template/empty-prompt.gts` | clean (no lifecycle code) |
| `eui-page-template/sidebar.gts` | clean (reviewed, teardown present) |
| `eui-page.gts` | clean (no lifecycle code) |
| `eui-pagination-button.gts` | clean (no lifecycle code) |
| `eui-pagination.gts` | clean (reviewed, teardown present) |
| `eui-pagination/arrow-button.gts` | clean (no lifecycle code) |
| `eui-pagination/button-wrapper.gts` | clean (no lifecycle code) |
| `eui-pagination/next-button.gts` | clean (no lifecycle code) |
| `eui-pagination/previous-button.gts` | clean (no lifecycle code) |
| `eui-panel.gts` | clean (no lifecycle code) |
| `eui-pinnable-list-group.gts` | clean (no lifecycle code) |
| `eui-popover-footer.gts` | clean (no lifecycle code) |
| `eui-popover-title.gts` | clean (no lifecycle code) |
| `eui-popover.gts` | F-POP-1 (also verified: timers/rAF/scroll listener cancelled in willDestroy) |
| `eui-portal.gts` | clean (node removed in willDestroy); note portalRef(null) not sent |
| `eui-pretty-duration.gts` | clean (no lifecycle code) |
| `eui-progress.gts` | clean (reviewed, teardown present) |
| `eui-radio-group.gts` | clean (no lifecycle code) |
| `eui-radio.gts` | clean (no lifecycle code) |
| `eui-range-highlight.gts` | clean (no lifecycle code) |
| `eui-range-input.gts` | clean (no lifecycle code) |
| `eui-range-label.gts` | clean (no lifecycle code) |
| `eui-range-levels.gts` | clean (no lifecycle code) |
| `eui-range-slider.gts` | clean (no lifecycle code) |
| `eui-range-thumb.gts` | clean (no lifecycle code) |
| `eui-range-ticks.gts` | clean (no lifecycle code) |
| `eui-range-tooltip.gts` | clean (no lifecycle code) |
| `eui-range-track.gts` | clean (reviewed, teardown present) |
| `eui-range-wrapper.gts` | clean (no lifecycle code) |
| `eui-range.gts` | F-MISC-1 (later 200ms not cancelled) |
| `eui-refresh-interval.gts` | clean (no lifecycle code) |
| `eui-resizable-container.gts` | clean (panel/resizer registries deregistered in modifier teardown) |
| `eui-resizable-container/button.gts` | clean (reviewed, teardown present) |
| `eui-resizable-container/collapse-button.gts` | clean (no lifecycle code) |
| `eui-resizable-container/panel.gts` | clean (reviewed, teardown present) |
| `eui-saturation.gts` | F-DRAG-1 |
| `eui-screen-reader-live.gts` | clean (reviewed, teardown present) |
| `eui-screen-reader-only.gts` | clean (no lifecycle code) |
| `eui-search-bar-filters.gts` | clean (reviewed, teardown present) |
| `eui-search-bar.gts` | clean (no lifecycle code) |
| `eui-search-bar/eui-search-box.gts` | clean (no lifecycle code) |
| `eui-search-bar/field-value-selection-filter.gts` | F-MISC-3 (cache timers overwritten) |
| `eui-search-bar/field-value-toggle-filter.gts` | clean (no lifecycle code) |
| `eui-search-bar/field-value-toggle-group-filter.gts` | clean (no lifecycle code) |
| `eui-search-bar/is-filter.gts` | clean (no lifecycle code) |
| `eui-select.gts` | clean (no lifecycle code) |
| `eui-selectable-list-item.gts` | clean (no lifecycle code) |
| `eui-selectable-list.gts` | clean (reviewed, teardown present) |
| `eui-selectable-list/option-text.gts` | clean (no lifecycle code) |
| `eui-selectable-message.gts` | clean (no lifecycle code) |
| `eui-selectable-search.gts` | clean (reviewed, teardown present) |
| `eui-selectable-template-sitewide.gts` | clean (reviewed, teardown present) |
| `eui-selectable.gts` | clean (reviewed, teardown present) |
| `eui-show-for.gts` | clean (reviewed, teardown present) |
| `eui-side-nav-item.gts` | clean (no lifecycle code) |
| `eui-side-nav-item/button.gts` | clean (no lifecycle code) |
| `eui-side-nav.gts` | clean (no lifecycle code) |
| `eui-skeleton-circle.gts` | clean (no lifecycle code) |
| `eui-skeleton-loading.gts` | clean (reviewed, teardown present) |
| `eui-skeleton-loading/screen-reader-live.gts` | clean (reviewed, teardown present) |
| `eui-skeleton-rectangle.gts` | clean (reviewed, teardown present) |
| `eui-skeleton-text.gts` | clean (no lifecycle code) |
| `eui-skeleton-title.gts` | clean (no lifecycle code) |
| `eui-skip-link.gts` | clean (reviewed, teardown present) |
| `eui-spacer.gts` | clean (no lifecycle code) |
| `eui-split-button.gts` | clean (no lifecycle code) |
| `eui-split-button/eui-split-button-action-primary.gts` | clean (no lifecycle code) |
| `eui-split-button/eui-split-button-action-secondary.gts` | clean (no lifecycle code) |
| `eui-split-panel/inner.gts` | clean (no lifecycle code) |
| `eui-split-panel/outer.gts` | clean (no lifecycle code) |
| `eui-stat.gts` | clean (no lifecycle code) |
| `eui-stat/description.gts` | clean (no lifecycle code) |
| `eui-stat/title.gts` | clean (no lifecycle code) |
| `eui-step-horizontal.gts` | clean (no lifecycle code) |
| `eui-step-number.gts` | clean (no lifecycle code) |
| `eui-step.gts` | clean (reviewed, teardown present) |
| `eui-steps-horizontal.gts` | clean (no lifecycle code) |
| `eui-steps.gts` | clean (no lifecycle code) |
| `eui-sub-steps.gts` | clean (no lifecycle code) |
| `eui-suggest-input.gts` | clean (no lifecycle code) |
| `eui-suggest-item.gts` | clean (no lifecycle code) |
| `eui-suggest.gts` | clean (no lifecycle code) |
| `eui-super-date-picker.gts` | clean (auto refresh verified by test) |
| `eui-super-date-picker/date-popover/absolute-tab.gts` | clean (no lifecycle code) |
| `eui-super-date-picker/date-popover/datetime-picker.gts` | clean (no lifecycle code) |
| `eui-super-date-picker/date-popover/eui-date-popover-button.gts` | clean (reviewed, teardown present) |
| `eui-super-date-picker/date-popover/eui-date-popover-content.gts` | clean (no lifecycle code) |
| `eui-super-date-picker/date-popover/eui-time-zone-display.gts` | clean (no lifecycle code) |
| `eui-super-date-picker/date-popover/now-tab.gts` | clean (no lifecycle code) |
| `eui-super-date-picker/date-popover/relative-tab.gts` | clean (no lifecycle code) |
| `eui-super-date-picker/eui-date-picker-range.gts` | clean (no lifecycle code) |
| `eui-super-date-picker/eui-quick-select-popover.gts` | clean (reviewed, teardown present) |
| `eui-super-date-picker/eui-quick-select-popover/eui-commonly-used-time-ranges.gts` | clean (no lifecycle code) |
| `eui-super-date-picker/eui-quick-select-popover/eui-quick-select-panel.gts` | clean (no lifecycle code) |
| `eui-super-date-picker/eui-quick-select-popover/eui-quick-select.gts` | clean (no lifecycle code) |
| `eui-super-date-picker/eui-quick-select-popover/eui-recently-used.gts` | clean (no lifecycle code) |
| `eui-super-date-picker/eui-super-update-button.gts` | clean (reviewed, teardown present) |
| `eui-super-date-picker/eui-time-window-buttons.gts` | clean (reviewed, teardown present) |
| `eui-super-date-picker/types/global.d.ts` | clean (no lifecycle code) |
| `eui-super-date-picker/utils/date-utils.ts` | clean (no lifecycle code) |
| `eui-super-date-picker/utils/index.ts` | clean (no lifecycle code) |
| `eui-super-date-picker/utils/pretty-duration.ts` | clean (no lifecycle code) |
| `eui-super-date-picker/utils/pretty-interval.ts` | clean (no lifecycle code) |
| `eui-super-date-picker/utils/quick-select.ts` | clean (no lifecycle code) |
| `eui-super-date-picker/utils/time-options.ts` | clean (no lifecycle code) |
| `eui-super-date-picker/utils/time-window.ts` | clean (no lifecycle code) |
| `eui-super-select-control.gts` | clean (reviewed, teardown present) |
| `eui-super-select.gts` | clean (reviewed, teardown present) |
| `eui-switch.gts` | clean (no lifecycle code) |
| `eui-tab.gts` | clean (no lifecycle code) |
| `eui-tabbed-content.gts` | clean (reviewed, teardown present) |
| `eui-table-body.gts` | clean (no lifecycle code) |
| `eui-table-footer-cell.gts` | clean (no lifecycle code) |
| `eui-table-footer.gts` | clean (no lifecycle code) |
| `eui-table-header-button.gts` | clean (no lifecycle code) |
| `eui-table-header-cell-checkbox.gts` | clean (reviewed, teardown present) |
| `eui-table-header-cell.gts` | clean (reviewed, teardown present) |
| `eui-table-header-mobile.gts` | clean (no lifecycle code) |
| `eui-table-header.gts` | clean (no lifecycle code) |
| `eui-table-pagination.gts` | clean (no lifecycle code) |
| `eui-table-row-cell-checkbox.gts` | clean (no lifecycle code) |
| `eui-table-row-cell.gts` | clean (no lifecycle code) |
| `eui-table-row.gts` | clean (no lifecycle code) |
| `eui-table-sort-mobile-item.gts` | clean (no lifecycle code) |
| `eui-table-sort-mobile.gts` | clean (no lifecycle code) |
| `eui-table.gts` | clean (observers/listeners in modifier cleanup; WeakMap keyed by table) |
| `eui-table/sticky-header.gts` | clean (reviewed, teardown present) |
| `eui-table/sticky-scrollbar.gts` | clean (reviewed, teardown present) |
| `eui-tabs.gts` | clean (no lifecycle code) |
| `eui-text-align.gts` | clean (no lifecycle code) |
| `eui-text-area.gts` | clean (reviewed, teardown present) |
| `eui-text-block-truncate.gts` | clean (reviewed, teardown present) |
| `eui-text-color.gts` | F-EMO-1 |
| `eui-text-diff.gts` | clean (no lifecycle code) |
| `eui-text-truncate.gts` | clean (reviewed, teardown present) |
| `eui-text.gts` | clean (no lifecycle code) |
| `eui-timeline-item-event.gts` | clean (no lifecycle code) |
| `eui-timeline-item-icon.gts` | clean (no lifecycle code) |
| `eui-timeline-item.gts` | clean (no lifecycle code) |
| `eui-timeline.gts` | clean (no lifecycle code) |
| `eui-title.gts` | clean (no lifecycle code) |
| `eui-toast.gts` | clean (no lifecycle code) |
| `eui-token.gts` | F-EMO-1 |
| `eui-tool-tip-popover.gts` | clean (resize listener + body class removed in willDestroy) |
| `eui-tool-tip.gts` | F-TIP-1 (low: next() unguarded); dead onKeyUp noted, otherwise clean |
| `eui-tour-step-indicator.gts` | clean (no lifecycle code) |
| `eui-tour-step.gts` | clean (reviewed, teardown present) |
| `eui-tour.gts` | clean (no lifecycle code) |
| `eui-tree-view.gts` | clean (reviewed, teardown present) |
| `eui-window-event.gts` | clean (reviewed, teardown present) |
| `eui-wrapping-popover.gts` | clean (reviewed, teardown present) |
| `text-block.gts` | clean (no lifecycle code) |
