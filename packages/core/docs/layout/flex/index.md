---
title: Flex
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Flex"/>
<EuiSpacer @size="l" />

<EuiText>

Flex components lay out other components without writing CSS:

- **`EuiFlexGroup`** puts its `EuiFlexItem`s in a row (or a column), with a
  gutter between them. By default items share the width equally and
  stretch to the same height.
- **`EuiFlexItem`** is one cell. `@grow={{false}}` makes it only as wide as
  its content; `@grow={{2}}` takes twice the share.
- **`EuiFlexGrid`** lays out repeated items (cards, stats) in a grid of 1–4
  `@columns`.

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
    The examples on this page add padding and a background to every
    <strong>EuiFlexItem</strong> so you can see them. Flex items have
    neither by default.
  </p>
</EuiCallOut>

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
| `@gutterSize` |  | `'l'` | Space between items: `'none'`, `'xs'`, `'s'`, `'m'`, `'l'` or `'xl'`. |
| `@alignItems` |  | `'stretch'` | Cross axis alignment (`align-items`): `'stretch'`, `'flexStart'`, `'flexEnd'`, `'center'` or `'baseline'`. |
| `@justifyContent` |  | `'flexStart'` | Main axis distribution (`justify-content`): `'flexStart'`, `'flexEnd'`, `'center'`, `'spaceBetween'`, `'spaceAround'` or `'spaceEvenly'`. |
| `@direction` |  | `'row'` | `'row'`, `'rowReverse'`, `'column'` or `'columnReverse'`. |
| `@wrap` | `boolean` | `false` | Lets items wrap onto several lines. |
| `@responsive` | `boolean` | `true` | Stacks the items in one column on small screens. Set `false` for rows that must stay on one line (e.g. icon + text). |
| `@tagName` | `'div' \| 'span'` | `'div'` | `'div'` or `'span'` (inside text). |

| Block | Description |
| --- | --- |
| default block | The `EuiFlexItem`s. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>` / `<span>`.

### EuiFlexItem

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@grow` |  |  | How the item grows: `true` (default) takes an equal share of the space, `false` only takes its content's width, `1`–`10` take that many shares. |
| `@tagName` | `string` | `'div'` | Tag of the item. |

| Block | Description |
| --- | --- |
| default block | The content. |

### EuiFlexGrid

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@tagName` | `string` | `'div'` | Passes the HTML tag to the wrapping element. |
| `@direction` |  | `'row'` | `'row'` fills the grid row by row, `'column'` column by column. |
| `@columns` | `number` | `0` | Number of columns, `1` to `4`. `0` lets the items wrap at their own width. |
| `@gutterSize` |  | `'l'` | Space between items: `'none'`, `'s'`, `'m'`, `'l'` or `'xl'`. |
| `@responsive` | `boolean` | `true` | Stacks the items in one column on small screens. |

| Block | Description |
| --- | --- |
| default block | The `EuiFlexItem`s, laid out in a grid. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
