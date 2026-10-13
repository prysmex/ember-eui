# Component-audit gaps: popover, combo box, textarea, tooltips, header logo

Branch `eui-wave/props-tooltips`. Every gap was checked against EUI v123.1.0
source first.

## Closed

1. **EuiPopover** (`eui-popover.gts`)
   - Initial focus: with `@ownFocus` (or a panel whose `aria-modal` is not
     `true`) and no `@initialFocus`, the panel itself is focused and Tab
     reaches the first element, as upstream (`initialFocus = () => this.panel`).
     An `@initialFocus` that matches nothing falls back to the first tabbable.
   - `@panelProps` (`className`, `css`, `tabIndex`, `role`, `aria-modal`,
     other `aria-*`/`data-*`/attributes, `on<Event>` listeners).
   - `@focusTrapProps` (`disabled`, `returnFocus`, `initialFocus`,
     `onEscapeKey`, `onClickOutside`, `shards`), passed through
     `focusTrapFactory` from `-private/focus-trap-registry.ts`; `joinFocusTraps`
     is untouched.
   - `@onPositionChange(position)`.
2. **EuiComboBox**
   - `@inputRef(element | null)`: the search input (not the validity input);
     `null` when removed.
   - `@inputPopoverProps` subset: `panelClassName`, `panelPaddingSize`,
     `panelStyle`, `panelMinWidth`, `panelCss`, `panelProps` (`className`, `css`),
     `zIndex` (replaces anchor + 2000), `anchorPosition` (up/down picks above/below
     unless `@verticalPosition`), `css` (root). The list is an
     ember-basic-dropdown panel, not an EuiPopover, so popover-only keys
     (`closeOnScroll`, `repositionOnScroll`, `buffer`, `offset`, `container`,
     `panelRef`, `popoverRef`, `onPanelResize`, root attributes) are not
     supported and stay in `docs-audit-gaps.md`.
   - Docs demo d15 now uses `@inputRef` like upstream's.
3. **EuiTextArea**: `@icon`, `@isLoading`, `@isClearable` (upstream wraps in
   EuiFormControlLayout; so does this now, `euiFormControlLayout--euiTextArea`,
   icons anchored to the bottom, `data-test-subj="clearTextAreaButton"`).
4. **Tooltips**: pagination arrows (not while disabled), color picker swatches
   (`@showToolTip`, `@toolTipProps`), EuiHue and EuiSaturation (hex, hue
   tooltip on the side closer to the thumb), EuiAvatar (native `title` removed:
   upstream wraps the avatar in an `EuiToolTip` with the name and
   `disableScreenReaderOutput` when there is a name). New arg
   `EuiToolTip @anchorStyle` (upstream `anchorProps.style`, used by the
   saturation indicator).
5. **EuiHeaderLogo** `@logoType="horizontal"`: new private
   `eui-header-logo/elastic-logo-full.gts`, a port of upstream
   `elastic_logo_full.tsx` (title default "Elastic", `max-height` size.l,
   `width: auto`, class `euiHeaderLogo__image`).
   **The artwork is the Elastic logo, an Elasticsearch B.V. trademark**; it is
   copied from upstream as is and the file header says so. Decide whether it
   should ship.

Also: removed the stale `EuiCollapsibleNavBeta | not ported` row (removed
upstream) and the closed rows/lines from `docs-audit-gaps.md` and the
migration guide's Known gaps (combo box and popover keep a narrowed line for
what is left).

## Skipped / not applicable

- Nothing from the list was missing upstream.
- `EuiPopover` `panelProps` does not apply EuiPanel's own props
  (`paddingSize`, `borderRadius`, `hasShadow`, ...) and `panelProps.id` is
  ignored (the trigger's `aria-controls` uses the panel id).

## Behaviour changes (each upstream-faithful)

- EuiPopover default initial focus: first tabbable -> the panel. The only
  internal caller that depended on it, the data grid cell popover (forms and
  editors), now passes `@initialFocus` (first tabbable, else the panel).
  Every other test passed unchanged.
- EuiAvatar: no native `title`; DOM is `span.euiToolTipAnchor > .euiAvatar`
  when it has a name. Same for color picker swatches, pagination arrows
  (`span.euiToolTipAnchor > button`), hue and saturation.
- EuiTextArea: markup is `div.euiFormControlLayout > div.childrenWrapper > textarea`.

Existing assertions changed (old -> new; upstream `avatar.tsx`,
`color_picker_swatch.tsx`, `pagination_button_arrow.tsx`, `text_area.tsx`):
- `eui-avatar-test`, `eui-icon-family-test`: `title="Jane Doe"` -> no `title`.
- `eui-color-picker-family-test`: swatches `li > .euiColorPickerSwatch` ->
  `li > .euiToolTipAnchor > .euiColorPickerSwatch`.
- `eui-icon-test` (icon names): `type('.euiToolTipAnchor')` also matched the
  new pagination tooltip anchors; it now excludes the pagination.

## Tests

- New: `eui-tooltips-test` (5), popover (7), text area (4), header logo (1),
  avatar (1), combo box (3).
- Core full suite: 1965/1965 (1945 before). Validated-form 25/25 and
  changeset-form 24/24, built against this worktree's core (temporary
  worktree-local `node_modules` with `@ember-eui/core` -> worktree core, plus
  a rollup `dist`; the symlinks were restored and `core/dist`, `dist-tests`
  removed).
- ember-tsc clean, eslint clean on changed files, parity 357/357, API docs
  regenerated, rollup refreshed `package.json` (one new private file).
