---
title: Filter group
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Filter group"/>
<EuiSpacer @size="l" />

<EuiText>

A filter group is a bar of filter buttons, usually beside a search field
above a list or table:

- **`EuiFilterGroup`** joins the buttons in one bordered bar.
- **`EuiFilterButton`** is one button: a toggle ("Open" / "Closed"), or
  the anchor of a popover listing options, with `@numFilters` (options
  available) or `@numActiveFilters` (options applied) in a badge.
- **`EuiFilterSelectItem`** is an option in that popover, with a check
  mark (`@checked="on"`) or a cross (`@checked="off"`, excluded).

```hbs
<EuiFilterGroup>
  <EuiFilterButton @withNext={{true}} @hasActiveFilters={{this.onlyOpen}} {{on "click" this.showOpen}}>
    Open
  </EuiFilterButton>
  <EuiFilterButton @hasActiveFilters={{this.onlyClosed}} {{on "click" this.showClosed}}>
    Closed
  </EuiFilterButton>
</EuiFilterGroup>
```

`@withNext` joins a button with the next one (no divider), for toggles
that belong together. `@hasActiveFilters` makes the text bold and the
badge accent-colored when some of the button's filters are applied.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiFilterGroup

A bar of `EuiFilterButton`s joined in one bordered group, usually next
to a search field, e.g. "On / Off" toggles and a "Status" popover.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |
| `@fullWidth` | `boolean` |  | Takes the container's full width instead of its content's. |
| `@compressed` | `boolean` |  | Smaller buttons and radius, e.g. next to a compressed search field. |
| `@display` | `'regular' \| 'highlighted'` | `'regular'` | `'regular'` or `'highlighted'` (selected `@isToggle` buttons are filled). |
| `@showDividers` | `boolean` | `true` | Dividers between the buttons. |

| Block | Description |
| --- | --- |
| default block | The `EuiFilterButton`s (and popovers anchored on them). |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiFilterButton

A button in an `EuiFilterGroup`: a toggle ("On", "Off"), or the anchor
of a popover listing filter options, with the number of options or of
active filters.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@iconType` |  |  | Icon, e.g. `'chevronSingleDown'` for a button opening a popover. |
| `@iconSide` | `'left' \| 'right'` | `'right'` | `'left'` or `'right'` of the text. |
| `@color` |  | `'text'` | Text color, any `EuiButtonEmpty` color. |
| `@badgeColor` | `'accent' \| 'success'` | `'accent'` | Color of the badge while `@hasActiveFilters`: `'accent'` or `'success'`. |
| `@isSelected` | `boolean` |  | Pressed look, e.g. while its popover is open or a toggle is on. Sets `aria-expanded` on popover anchors (`@iconType="chevronSingleDown"` or its legacy alias `"arrowDown"`), `aria-pressed` otherwise. |
| `@isToggle` | `boolean` |  | Renders an on/off toggle (upstream `isToggle`): a small `EuiButton` look, highlighted while `@isSelected`. |
| `@hasActiveFilters` | `boolean` |  | Bold text and an accent badge: some of its filters are applied. |
| `@numFilters` | `number` |  | Number of available filters, shown in a badge. |
| `@numActiveFilters` | `number` |  | Number of applied filters, shown instead of `@numFilters` when above 0. |
| `@isDisabled` | `boolean` |  | Disables the button. |
| `@grow` | `boolean` | `true` | Grows to fill the group. |
| `@withNext` | `boolean` |  | Removes the divider after it, to join it with the next button (e.g. "On" and "Off" toggles). |
| `@noDivider` | `boolean` |  | Same as `@withNext`. |
| `@type` | `string` | `'button'` | `type` of the `<button>`. |
| `@hasAriaDisabled` | `boolean` |  | Beta: with `@isDisabled`, renders `aria-disabled` instead of the native `disabled`; the button keeps focus while clicks are blocked. |
| `@iconSize` |  | `'m'` | Size of the icon. |
| `@isLoading` | `boolean` |  | Replaces the icon with a spinner and disables the button. |
| `@contentProps` | `EuiElementProps` |  | Upstream's `contentProps`: `class`/`className`, `css` and HTML attributes for the element wrapping the icon, text and badge. |
| `@textProps` | `EuiElementProps` |  | Upstream's `textProps`: `class`/`className`, `css` and HTML attributes for the element wrapping the text. |

| Block | Description |
| --- | --- |
| default block | The button text. Leave it out for an icon-only button. |

### EuiFilterSelectItem

One option in a filter popover (opened from an `EuiFilterButton`): a
button with a check mark when `@checked="on"`, or a cross when `"off"`
(excluded).

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@checked` | `'on' \| 'off'` |  | `'on'` (check mark, included; sets `aria-selected="true"`), `'off'` (cross, excluded) or nothing (not applied). |
| `@isFocused` | `boolean` |  | Highlights it, e.g. while moving through the list with the keyboard, and scrolls it into view when it becomes focused. |
| `@showIcons` | `boolean` | `true` | Shows the check mark / cross column. |
| `@truncateContent` | `boolean` | `true` | Truncates a long label with an ellipsis. |
| `@disabled` | `boolean` |  | Disables the option. |

| Block | Description |
| --- | --- |
| default block | The option's label. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>`.

</EuiText>
<!-- api:end -->
