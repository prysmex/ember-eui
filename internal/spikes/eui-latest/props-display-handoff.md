# Upstream prop gaps: display, lists, navigation and misc

Branch `eui-wave/props-display`. The candidates come from
`node scripts/upstream-prop-audit.mjs` (section "Automated prop audit" of
`docs-audit-gaps.md`). Each one was checked against EUI v123.1.0 source
before porting. `docs-audit-gaps.md` is not edited: the coordinator updates
it from the tables below.

## Closed

| Component | Props | Ember API |
| --- | --- | --- |
| EuiSteps | `steps` | `@steps` (array of `{ title, children, status, titleSize, headingElement, className, …attributes }`), numbered from `@firstStepNumber`. Content is the `children` text, or the new `<:step as \|step index\|>` block (React node -> block). Without `@steps` the default block renders as before. |
| EuiStepsHorizontal | `steps` | `@steps` (array of `{ title, status, onClick, disabled, size, 'aria-label', className, …attributes }`), numbered by position. `onClick` maps to EuiStepHorizontal's `@onStepClick`. |
| EuiGlobalToastList | `toasts` (with `toastLifeTimeMs`, `dismissToast`) | `@toasts` (array of `{ id, …EuiToast args, text, toastLifeTimeMs }`). When given, the list renders it instead of the `euiToaster` service and never mutates it: dismissal (close button, lifetime, "Clear all") only calls `@dismissToast`, the caller removes the toast. Timers, pause on hover/focus, fade-out and per-toast lifetime are shared with the service mode. |
| EuiToast | `text` | `@text`, alias of `@body` (`@body` wins). Toast data entries accept `text` too. |
| EuiContextMenuPanel | `items` | `@items`: the same entries as an EuiContextMenu panel's `items` (items, `{ isSeparator: true }`, `{ renderItem }`). The list gets `role="menu"`, items `role="menuitem"`; arrow keys work as with block items. Items win over the block, as upstream. |
| EuiContextMenu | `onPanelChange` | `@onPanelChange({ panelId, direction })`, called from `showPanel` like upstream. |
| EuiContextMenuItem | `external` (+ `hasAriaDisabled`, `rel`) | `@external` (external icon + i18n screen reader text, default on for `_blank`, upstream `EuiExternalLinkIcon`), `@rel` with upstream's secure rel, `@hasAriaDisabled` (`aria-disabled`, focusable, events blocked through `-private/eui-disabled-element.ts`, upstream `canHaveInteractiveStyles` / `buttonIsDisabled`). |
| EuiListGroup | `ariaLabelledby` | `@ariaLabelledby`; `@listItems` entries also pass `icon`, `iconProps`, `hasAriaDisabled`. |
| EuiPinnableListGroup | `ariaLabelledby`, `showToolTips` | `@ariaLabelledby`, `@showToolTips` (passed to EuiListGroup). Items now also pass `rel`, `external`, `icon`, `iconProps`, `hasAriaDisabled`, `color`, `showToolTip`, `toolTipText`, `toolTipProps`; other keys become attributes of the item (upstream spreads items into EuiListGroup `listItems`). |
| EuiListGroupItem | `icon`, `iconProps` (+ `hasAriaDisabled`) | `@icon` (a component, rendered with `euiListGroupItem__icon` and `iconProps.css`; `@iconType` wins, as upstream), `@iconProps` (`color` default `'inherit'`, `size`, `title`, `titleId`, `css`, `className`, other keys as attributes), `@hasAriaDisabled` on link/button items. |
| EuiSideNav | `isOpenOnMobile`, `truncate` | `@isOpenOnMobile` (upstream name; `@isOpenMobile` kept, deprecated), `@truncate` reaching every depth through a private `@navTruncate` on EuiSideNavItem; an item's own `truncate` wins. |
| EuiComment | `verticalAlign` | `@verticalAlign` (`'top'` / `'center'`), also as a `verticalAlign` key of EuiCommentList `@comments`. |
| EuiExpression | `descriptionProps`, `valueProps` | `@descriptionProps` / `@valueProps`: `className`, `css` (composed last), `style` (object, merged after the columns width as upstream), other keys as attributes. |
| EuiCallOut | `dismissButtonProps` | `@dismissButtonProps`: `className`, `css`, `aria-label`, `data-test-subj`, `isDisabled`, `hasAriaDisabled`, `display`, `iconSize`, other keys as attributes. `iconType`/`color`/`size`/`onClick` stay fixed, as upstream. |
| EuiEmptyPrompt | `hasShadow` | `@hasShadow` (EuiPanel's: only on a borderless `plain` panel). |
| EuiConfirmModal | `outsideClickCloses` | `@outsideClickCloses`, passed to EuiModal (mask click calls `@onCancel`). |

`*Props` hashes follow main's pattern: keys that are inner-component args are
mapped, the rest go through `-private/eui-spread-attributes.ts`.

## Skipped (and why)

| Component | Prop | Reason |
| --- | --- | --- |
| EuiContextMenuPanel | `height` | Upstream only forwards it to the panel's `<div>` as a meaningless `height` HTML attribute; EuiContextMenu's own `height` does the sizing (`fixedHeight`), and our EuiContextMenu already has `@height`. Standalone panels can use `style`. |
| EuiSkeletonLoading | `isLoading`, `contentAriaLabel`, `announce*Status`, `ariaLiveProps`, `loadingContent`, `loadedContent` | Already covered: all args exist, and the content props are the `<:loadingContent>` / `<:loadedContent>` blocks. **Audit false positive** (see below). |
| EuiDelayHide | `render` | Covered by the default block (render prop -> block). |
| EuiComment | `timelineAvatar` | Covered by `@timelineIcon` (icon type string, upstream's string form) and `<:timelineIcon>` (node form). |
| EuiBadgeGroup | `gutterSize` | Already an arg. **Audit false positive.** |
| EuiDraggable | `usePortal` | Not applicable: upstream portals the dragged clone because react-beautiful-dnd positions it `fixed`, which breaks inside transformed containers. Our pragmatic-drag-and-drop port drags with the browser's native drag image (outside every stacking context) and moves keyboard drags in place with transforms, so there is nothing to portal. |

Audit false positives: `scripts/upstream-prop-audit.mjs` (and
`generate-api-docs.mjs`) take the first `TOC<…>`-typed variable statement in a
declaration file as the component when the file also declares one (e.g.
`applyAttributes` in eui-skeleton-loading, `BadgeGroupItem` in
eui-badge-group). The coordinator may want to make the audit prefer the
default export. EuiComment had the same problem (its private
`EuiCommentItem` class was documented instead of EuiComment); it is fixed by
moving that class to `-private/eui-comment-item.gts`, so the EuiComment API
table is now correct.

## Behaviour changes (upstream-faithful)

- EuiContextMenuItem links get `rel` (`noreferrer`, plus `noopener` for
  `_blank`; upstream `getSecureRelForTarget`) and, for `target="_blank"`, the
  external icon and "(external, opens in a new tab or window)" text.
- EuiContextMenu panel items (and the new panel `@items`): keys that are not
  item args become attributes of the item (upstream spreads `...rest`), e.g.
  `aria-current`. Before, only `data-test-subj` was applied.
- EuiPinnableListGroup items: unknown keys now become attributes of the item
  (upstream spreads them).
- No existing test assertion was changed.

## Docs

- Steps: demo7 "Steps as data" (upstream default example with `@steps` +
  `<:step>`), demo8 "Horizontal steps as data" (upstream horizontal example).
- Toast: d06 "Toast list as data" (upstream toast list with `toasts` /
  `dismissToast`).
- Context menu: d02 now uses `@items` like upstream's single panel example;
  d01 text mentions the external icon and `@onPanelChange`.
- List group: d03 passes `iconProps: { color: 'default' }` as upstream.
- Side nav: page and demos use `@isOpenOnMobile`; `@truncate` documented.
- API tables regenerated (`node scripts/generate-api-docs.mjs`).
- No upstream examples exist for `verticalAlign`, `descriptionProps`,
  `valueProps`, `dismissButtonProps`, `hasShadow` (empty prompt) or
  `outsideClickCloses` (confirm modal); the API tables cover them.

## Files

- Components: `eui-steps.gts`, `eui-steps-horizontal.gts`,
  `eui-global-toast-list.gts`, `eui-toast.gts`, `eui-context-menu.gts`,
  `eui-context-menu-panel.gts`, `eui-context-menu-item.gts`,
  `eui-list-group.gts`, `eui-list-group-item.gts`,
  `eui-pinnable-list-group.gts`, `eui-side-nav.gts`, `eui-side-nav-item.gts`,
  `eui-comment.gts`, `eui-comment-list.gts`, `eui-expression.gts`,
  `eui-call-out.gts`, `eui-empty-prompt.gts`, `eui-confirm-modal.gts`.
- New private modules: `-private/eui-context-menu-entry.gts` (panel entry
  shared by EuiContextMenu and EuiContextMenuPanel, no import cycle),
  `-private/eui-comment-item.gts`.
- Tests: `tests/integration/components/eui-display-upstream-props-test.gts`
  (24 tests).

## Checks

- `ember-tsc --noEmit`: clean. eslint on changed files: clean.
- `generate-eui-styles.mjs --check`: OK; parity tests 357/357 (no style
  changes).
- Filtered related suites (steps, toast, context menu, lists, side nav,
  comment, expression, callout, empty prompt, modal): 274/274.
- Full core suite: 1998/1998 (main 1974 + 24 new).
- `rollup --config`: no package.json change (only private modules added).
