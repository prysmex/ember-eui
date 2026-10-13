# Last interaction differences handoff

Branch `eui-wave/last-interactions` (from `feat/eui-latest` at `f8bf0d34`),
target EUI 123.1.0. Every item was checked against upstream's source in
`upstream-docs/eui/packages/eui/src/components/`. Ships in 15.0.0.

## Closed

### 1. EuiComboBox toggle button focus (`combo_box.tsx`, `combo_box_input.tsx`)

- Pressing the chevron (`comboBoxToggleListButton`) now moves focus to it, as
  upstream's mousedown does. The trigger still stops the press from reaching
  ember-basic-dropdown's trigger, but no longer prevents the mousedown.
- Opening (`onOpenListClick`) focuses the input, which opens the list and
  calls `@onFocus` again (`onComboBoxFocus`). Closing (`closeList`) leaves
  focus on the button.
- Upstream `onContainerBlur`, ported for both the input and the button
  (new trigger `focusout` hook → `onToggleBlur`, shared `containerBlur`):
  - focus moving into the list: nothing happens;
  - focus moving elsewhere in the combo box (chevron, clear button, pill
    buttons): the active option is cleared, and `@onBlur` is not called;
  - focus leaving: `@onBlur`, the list closes, and the typed text is added.
- Upstream container `onKeyDown` while the button has focus
  (`onToggleKeydown`, from a keydown listener on the layout):
  - ArrowUp/ArrowDown open the list, or move through it (wrapping);
  - Escape closes an open list;
  - Tab is held while an option is active;
  - Enter and Space press the button natively. They, and other keys, are
    stopped there, so ember-basic-dropdown and ember-power-select don't
    toggle, choose or type ahead. Escape on a closed list and other Tabs
    pass through, as upstream.

### 2. Pills and the badge spread (`combo_box_input.tsx` `renderPills`, `combo_box_pill.tsx`, `badge.tsx`)

- Pills get the option's other keys, through the private
  `eui-spread-attributes` modifier, after the pill's own attributes
  (`data-test-subj` overrides `euiComboBoxPill`). Excluded: upstream's
  destructured keys (`key`, `label`, `color`, `onClick`, `append`,
  `prepend`, `truncationProps`, `toolTipContent`, `toolTipProps`); functions;
  objects.
  - This only applies to plain objects without `@searchField`. Model or
    class options, and `@searchField` options, are app data, so they get no
    attributes.
  - `className` is added to the pill's class.
  - `title` is the label (upstream `title={children}`).
- An option with `onClick` is a clickable badge button: `aria-label`
  "Change" (an upstream literal), and no remove button (upstream
  `pillOnClose` is undefined).
- EuiBadge with `@iconOnClick` and `@onClick`/`@href`: attributes other than
  `class`/`style` move to the text button or link (upstream `...rest` on
  `Element`, `className`/`style` on the outer span).
  - Ember can't split `...attributes`, so a modifier moves them after
    render and on every change (MutationObserver), like EuiDataGrid's
    `moveAriaAttributes`.
  - Pills never hit this combination: upstream gives an `onClick` pill no
    `iconOnClick`.
  - Badge demo d06 already documented this behaviour.

### 3. EuiFlyout push padding (`flyout.component.tsx` push padding effect)

`shouldPush = isPushed && (!isInManagedContext || isActiveManagedFlyout)`.
Before, it used `level` instead of the managed context. Now a pushed standard
flyout nested in a managed flyout doesn't pad the page, doesn't set the
offset variable and doesn't report to the manager. Session Escape and z-index
are unchanged.

### 4. EuiSelectable accessible name (`selectable.tsx` `getAccessibleName`)

- The root's `aria-label`/`aria-describedby` attributes are read from the
  root and removed, after render and on change (MutationObserver), into
  UI-only tracked fields.
- They are routed like upstream:
  - **Search:** its own `searchProps['aria-label']` wins, then
    `searchProps['aria-describedby']` + message id, then the root's label,
    then the root's description + message id. Otherwise it gets the
    "Filter options" label. With a label, `aria-describedby` stays the
    instructions id; with a description, the description replaces it.
  - **Listbox:** the same order, using `listProps` and the instructions id.
    Otherwise it gets "Filter options" when searchable, else nothing.
- `searchProps`' `aria-label`/`aria-describedby` are no longer spread as
  attributes. EuiSelectableSearch got a separate `@instructionsId`.

### 5. EuiListGroup / EuiListGroupItem tooltips (`list_group.tsx`, `list_group_item.tsx`, `_list_item_layout.tsx`)

gaps-display already had `@showToolTip`, `@toolTipText`, `@toolTipProps`,
`@showToolTips` and `@listItems`. Compared with upstream, what was left:

- **Block label as tooltip content.** `content: toolTipText ?? label`, where
  the label is a node. The block (Ember's label node) renders in EuiToolTip's
  `<:content>` when there is no `@toolTipText` and no
  `toolTipProps.content`. EuiMaybeToolTip has a new `@blockContent` +
  `<:content>`.
- **Block label title.** `title = innerText` for a node label, through
  EuiInnerText. The ref is only attached while a title is due, so not when
  wrapping or with a tooltip.
- **Tooltip description.** A plain `<li>` with a tooltip gets
  `aria-describedby` = tooltip id, merged with the caller's ids.
  - The id is `toolTipProps.id`, else a guid.
  - Interactive items keep EuiToolTip's own while-visible
    `aria-describedby`.
- **More `toolTipProps`.** `isShown`, `onMouseOut`, `onFocus` and `onBlur`
  are forwarded too.
- **`@wrapText`.** Upstream EuiListGroup passes `wrapText` to `listItems`
  only; children are cloned with `color` and `showToolTip`. The list
  context no longer carries `wrapText`.
  - EuiPinnableListGroup passes its `@wrapText` per item, as upstream's
    `listItems` path does.
  - `@showToolTips` and `@color` still reach block items.
- Demo d04 now mirrors upstream's third item: a rich block, no
  `@toolTipText`.

## Deliberate behaviour changes (old → new, upstream reference)

| # | Change | Old | New | Upstream |
| --- | --- | --- | --- | --- |
| 1 | Chevron press | Focus stayed in the input | Focus moves to the button; its keys/blur follow the container handlers | `combo_box.tsx` `onContainerBlur`/`onKeyDown`/`onOpenListClick`, `combo_box_input.tsx` icon |
| 2 | Combo `@onBlur` | Every input blur | Only when focus leaves the combo box; moving inside clears the active option | `onContainerBlur` |
| 3 | Pills | `color` only | Option keys as attributes, `className`, `title`=label, `onClick` → "Change" button without remove | `renderPills`, `EuiComboBoxPill` |
| 4 | EuiBadge attrs with `@iconOnClick` + `@onClick`/`@href` | Outer span | Text button/link (`class`/`style` stay) | `badge.tsx` `{...rest}` on `Element` |
| 5 | Nested pushed flyout in a managed flyout | Pushed | Does not push | `flyout.component.tsx` `shouldPush` |
| 6 | EuiSelectable `aria-label`/`aria-describedby` | Root `<div>`; search/list labelled with the (custom) placeholder | Search and listbox; fallback "Filter options" | `selectable.tsx` `getAccessibleName`, `placeholderName` |
| 7 | EuiListGroup `@wrapText` | Also block items | `@listItems` only | `list_group.tsx` |
| 8 | Block label of EuiListGroupItem | No title, empty tooltip | `title` = its text; tooltip shows it | `list_group_item.tsx` `labelProps`, `_tooltipProps` |
| 9 | Plain list item with a tooltip | No `aria-describedby` on the `li` | Tooltip id | `_list_item_layout.tsx` `hasInternalTooltip` |

All of them are in `.changeset/borealis-migration.md` (one bullet) and in
`docs/migrating-to-borealis.md` (Display, Forms, Overlays, Navigation
tables). Known gaps: the combo box chevron / plain-text and list group
tooltip entries were removed (closed).

## Existing tests changed

- `eui-lists-test` "EuiListGroupItem: wrapText, reactive args keep the
  element": `@wrapText` moved from the list to the item (setup only; the
  assertions are unchanged). Upstream: `list_group.tsx` doesn't clone
  `wrapText` into children.
- `eui-badge-family-test`, the clickable badges test:
  - the two both-handler badges got classes;
  - `[data-both]` root selectors → `.both`, and `data-both` is asserted on
    the child button;
  - the root `.both` asserts it has no `data-both`;
  - `[data-both-link] a…` → `.both-link a…[data-both-link]`.
  - Upstream: `badge.tsx` `...rest`.
- `eui-badge-family-test` "long text truncates…": `[data-long-child]` root
  → `.long-child`, and the child button carries `data-long-child` (same
  reference).

No other test edits. The existing toggle, async `@search` click
(`eui-combo-box-click-focus-test`), list z-index / focus-trap joining
(`eui-stacking-test`), derived options and flyout session Escape/z-index
tests pass unchanged.

## New tests (24)

- `eui-combo-box-last-interactions-test.gts` (9):
  - closing keeps focus on the button, without `@onBlur`, and reopening
    refocuses the input (`@onFocus` count);
  - focus moving to the button clears the active option;
  - keys on the button (arrows open/move/wrap, Enter/letters/Space don't
    choose/type/toggle, Escape closes);
  - Tab held;
  - leaving from the button (`@onBlur`, close, `@onCreateOption`);
  - leaving with a closed list;
  - pill attributes / title / exclusions;
  - "Change" pill;
  - `@searchField` / class options get no attributes.
- `eui-selectable-accessible-name-test.gts` (7): root label → search +
  list; no search; root describedby (+ message / + instructions); props
  win; `listProps` label + `searchProps` describedby; placeholder-name
  fallback (not the custom placeholder) and none without search; a changed
  root label is moved again.
- `eui-list-group-item-test.gts` (+6): block tooltip content (rich); text
  and `props.content` win; block title via inner text (wrap/tooltip remove
  it); `li` `aria-describedby` merge/removal; `isShown`; list `@wrapText`
  only for `@listItems`.
- `eui-flyout-upstream-parity-test.gts` (+1): nested pushed flyout doesn't
  pad or report; a standalone one pads 260px and resets. It fails with the
  old `shouldPush`, which was verified.
- `eui-badge-family-test.gts` (+1): attributes on the text button,
  class/style on the root, updates moved, `iconOnClick` alone stays on the
  root.

## Checks (worktree, Chromium 130, CI=true)

- Full core suite: **1930/1930** (main 1906 + 24).
- Filtered while iterating: list 126, selectable 73, search 68, flyout 239,
  combo 120, badge 48.
- Companions, built against this worktree's core: validated-form **25/25**,
  changeset-form **24/24**.
  - Recipe: `rollup --config` in core (exit 0, `package.json` unchanged),
    then a temporary local `node_modules` per companion with
    `@ember-eui/core` → the worktree core.
  - `dist-tests` was verified to contain the new code.
  - The symlinks were restored and `core/dist` removed. sync-injected was
    not run.
  - Script: `scratchpad/li-companion.sh`.
- `ember-tsc --noEmit` clean, ESLint clean on changed files, parity 357/357,
  `generate-api-docs` (badge, list group, selectable pages).

## Not done / remaining differences

- **Combo chevron keys.** Enter, Space and other non-navigation keys on the
  focused chevron are stopped at the combo box, so ember-basic-dropdown
  doesn't toggle and ember-power-select doesn't type ahead. Upstream lets
  them bubble past the combo box. Escape on a closed list and Tab (without
  an active option) still bubble.
- **Pills.** A `true` value becomes an empty attribute; React drops unknown
  boolean attributes. Only plain objects without `@searchField` are spread
  (a deliberate Ember guard).
- **Moved attributes** (EuiSelectable root, EuiBadge). If the caller later
  removes the attribute entirely, the moved value stays: Glimmer's
  `removeAttribute` on an absent attribute queues no mutation. A
  Glimmer-managed `title` on the badge's child (inner text) can override a
  caller `title` when the text changes.
- **EuiSelectable `listProps['aria-labelledby']`** is not forwarded
  (upstream passes it through `cleanedListProps`). It wasn't requested.
- **EuiListGroupItem** `icon`, `iconProps` and `buttonRef`, other
  `@listItems` keys (only `data-test-subj` is forwarded), and the
  layout's manual focus tooltip (`isFocused`; list group items never pass
  it upstream either).
- **Push padding.** Upstream 123.1.0 keeps a per-target contributions map
  (widest pushed flyout wins, base padding restored). The Ember
  `pushFlyoutPadding` was not compared beyond `shouldPush`.
- **Known gaps.** The `docs/migrating-to-borealis.md` "Known gaps" section
  still lists the flyout manager and other items that earlier waves closed.
  Only the combo box and list group entries were updated here.
