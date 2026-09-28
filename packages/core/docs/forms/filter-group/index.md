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
| `@fullWidth` | `boolean` |  | Takes the container's full width instead of its content's. |

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
| `@iconType` |  |  | Icon, e.g. `'arrowDown'` for a button opening a popover. |
| `@iconSide` | `'left' \| 'right'` | `'right'` | `'left'` or `'right'` of the text. |
| `@color` |  | `'text'` | Text color, any `EuiButtonEmpty` color. |
| `@isSelected` | `boolean` |  | Pressed look, e.g. while its popover is open or a toggle is on. |
| `@hasActiveFilters` | `boolean` |  | Bold text and an accent badge: some of its filters are applied. |
| `@numFilters` | `number` |  | Number of available filters, shown in a badge. |
| `@numActiveFilters` | `number` |  | Number of applied filters, shown instead of `@numFilters` when above 0. |
| `@isDisabled` | `boolean` |  | Disables the button. |
| `@grow` | `boolean` | `true` | Grows to fill the group. |
| `@withNext` | `boolean` |  | Removes the divider after it, to join it with the next button (e.g. "On" and "Off" toggles). |
| `@noDivider` | `boolean` |  | Same as `@withNext`. |
| `@type` | `string` | `'button'` | `type` of the `<button>`. |

| Block | Description |
| --- | --- |
| default block | The button text. |

### EuiFilterSelectItem

One option in a filter popover (opened from an `EuiFilterButton`): a
button with a check mark when `@checked="on"`, or a cross when `"off"`
(excluded).

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@checked` | `'on' \| 'off'` |  | `'on'` (check mark, included), `'off'` (cross, excluded) or nothing (not applied). |
| `@isFocused` | `boolean` |  | Highlights it, e.g. while moving through the list with the keyboard. |
| `@showIcons` | `boolean` | `true` | Shows the check mark / cross column. |
| `@disabled` | `boolean` |  | Disables the option. |

| Block | Description |
| --- | --- |
| default block | The option's label. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>`.

</EuiText>
<!-- api:end -->
