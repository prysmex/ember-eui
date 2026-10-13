---
title: Flex
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Flex"/>
<EuiSpacer @size="l" />

<EuiText>

Flex components lay out other components without writing CSS:

## Use cases

- **`EuiFlexGroup`** is useful for single row layouts and for quick alignment
  of items. By default items share the width equally and stretch to the same
  height.
- **`EuiFlexGrid`** should be used for repeated wrapping rows of same-width
  items, in 1–4 `@columns`.
- **`EuiFlexItem`** should be used as a direct child of both groups or grids.
  `@grow={{false}}` makes it only as wide as its content; `@grow={{2}}` takes
  twice the share. Depending on the layout it can also be omitted if its
  automatic flex or grow behavior is not desired.

```hbs
<EuiFlexGroup @alignItems="center" @gutterSize="s" @responsive={{false}}>
  <EuiFlexItem @grow={{false}}><EuiAvatar @name="Jane Cooper" /></EuiFlexItem>
  <EuiFlexItem>Jane Cooper</EuiFlexItem>
  <EuiFlexItem @grow={{false}}><EuiButtonIcon @iconType="gear" aria-label="Settings" /></EuiFlexItem>
</EuiFlexGroup>
```

On small screens, groups and grids stack their items in one column; set
`@responsive={{false}}` for rows that must stay on one line (like the one
above).

<EuiCallOut @title="Coloring and padding exist for examples only" @size="s">
  <p>
    Padding and background-color are added to all
    <strong>EuiFlexItems</strong> on this documentation page for
    illustrative purposes only. If needed, you must add your own padding
    through additional components or classes.
  </p>
</EuiCallOut>

## Shared behavior

The examples below follow the upstream pages: nesting and tag names apply to
all three components, then come the group, item and grid specific examples.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiFlexGroup

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@gutterSize` | `EuiFlexGroupGutterSize` | `'m'` | Space between items (CSS `gap`): `'none'`, `'xs'` (4px), `'s'` (8px), `'m'` (16px), `'l'` (24px) or `'xl'` (40px). |
| `@alignItems` | `EuiFlexGroupAlignItems` | `'stretch'` | Cross axis alignment (`align-items`): `'stretch'`, `'flexStart'`, `'flexEnd'`, `'center'` or `'baseline'`. |
| `@justifyContent` | `EuiFlexGroupJustifyContent` | `'flexStart'` | Main axis distribution (`justify-content`): `'flexStart'`, `'flexEnd'`, `'center'`, `'spaceBetween'`, `'spaceAround'` or `'spaceEvenly'`. |
| `@direction` | `EuiFlexGroupDirection` | `'row'` | `'row'`, `'rowReverse'`, `'column'` or `'columnReverse'`. |
| `@wrap` | `boolean` | `false` | Lets items wrap onto several lines. |
| `@responsive` | `boolean` | `true` | Below the theme's `m` breakpoint (767px in Borealis), wraps the group and makes every direct `EuiFlexItem` full width. Set `false` for rows that must stay on one line (e.g. icon + text). Column directions are never affected. |
| `@tagName` | `string` | `'div'` | Any tag name, e.g. `'span'` (inside text), `'section'` or `'ul'` (upstream's `component`). |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |

| Block | Description |
| --- | --- |
| default block | The `EuiFlexItem`s. |

### EuiFlexItem

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@grow` | `EuiFlexItemGrow` |  | How the item grows: `true` (default) takes an equal share of the space, `false` (or `0`) only takes its content's width, `1`–`10` take that many shares. |
| `@tagName` | `string` | `'div'` | Tag of the item. |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |

| Block | Description |
| --- | --- |
| default block | The content. |

### EuiFlexGrid

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@tagName` | `string` | `'div'` | Passes the HTML tag to the wrapping element. |
| `@direction` | `EuiFlexGridDirection` | `'row'` | `'row'` fills the grid row by row, `'column'` column by column. |
| `@columns` | `number` | `1` | Number of columns, `1` to `4` (upstream default `1`). The Ember-only `0` lets the items wrap at their own width. |
| `@gutterSize` | `EuiFlexGridGutterSize` | `'l'` | Space between items (CSS `gap`): `'none'`, `'s'` (8px), `'m'` (16px), `'l'` (24px) or `'xl'` (32px). |
| `@alignItems` | `EuiFlexGridAlignItems` | `'stretch'` | Cross axis alignment of the items in their cells: `'stretch'`, `'start'`, `'end'`, `'center'` or `'baseline'`. |
| `@responsive` | `boolean` | `true` | Below the theme's `m` breakpoint (767px in Borealis), stacks the items in one column. |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |

| Block | Description |
| --- | --- |
| default block | The `EuiFlexItem`s, laid out in a grid. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
