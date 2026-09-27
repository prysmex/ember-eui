---
title: Panel
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Panel"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiPanel` is a box for grouping content: a white background, padding, a
rounded border and a shadow by default. Other components (cards,
popovers, page sections) are built on it.

```hbs
<EuiPanel @paddingSize="l" @hasBorder={{true}}>
  <EuiTitle @size="xs" @tagName="h3">Usage</EuiTitle>
  <EuiText><p>32 of 50 seats used.</p></EuiText>
</EuiPanel>
```

- `@paddingSize`: `none`, `s`, `m` (default) or `l`.
- `@hasShadow` (on by default) and `@hasBorder` for plain panels.
- `@color` for a shaded or colored background (`subdued`, `primary`,
  `success`, `warning`, `danger`, `accent`, `transparent`).
- `@onClick` makes the whole panel clickable.

`EuiSplitPanelOuter` and `EuiSplitPanelInner` build a panel made of
sections with different colors, e.g. a footer.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiPanel

A box grouping content, with background, padding, border and shadow options.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@hasShadow` | `boolean` | `true` | Adds a box shadow (plain panels only). |
| `@hasBorder` | `boolean` |  | Adds a border (plain and transparent panels only). |
| `@paddingSize` |  | `'m'` | Padding: `'none'`, `'s'`, `'m'` or `'l'`. |
| `@borderRadius` |  | `'m'` | `'none'` or `'m'`. |
| `@color` |  | `'plain'` | Background: `'plain'`, `'transparent'`, `'subdued'`, `'accent'`, `'primary'`, `'success'`, `'warning'` or `'danger'`. |
| `@grow` | `boolean` | `true` | Grows to fill a flex parent's height. |
| `@onClick` | `(e: MouseEvent) => void` |  | Makes the whole panel clickable (hover styles, `role="button"`, focusable, Enter and Space activate it). |
| `@isClickable` | `boolean` | `true` | Hover styles for a clickable panel. |

| Block | Description |
| --- | --- |
| default block | The panel's content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiSplitPanelOuter

A panel split into sections (`EuiSplitPanelInner`) with different colors or padding.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@direction` | `'column' \| 'row'` | `'column'` | `'column'` stacks the sections, `'row'` puts them side by side. |
| `@responsive` | `Named['sizes']` | `['xs', 's']`; pass `false` to never stack | Screen sizes on which a `'row'` split panel stacks its sections. |
| `@grow` | `boolean` | `false` | Grows to fill a flex parent. |
| `@paddingSize` |  | `'none'` | Padding of the outer panel. |
| `@hasShadow` |  |  | Adds a shadow. |
| `@color` |  |  | Background, any `EuiPanel` color. |
| `@borderRadius` |  |  | Border radius. |
| `@hasBorder` |  |  | Adds a border. |

| Block | Description |
| --- | --- |
| default block | The `EuiSplitPanelInner` sections. |

### EuiSplitPanelInner

One section of an EuiSplitPanelOuter, e.g. a header or footer with its own color.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@hasShadow` |  | `false` | Adds a shadow. |
| `@color` |  | `'transparent'` | Background, any `EuiPanel` color. |
| `@borderRadius` |  | `'none'` | Border radius. |
| `@hasBorder` |  | `false` | Adds a border. |
| `@paddingSize` |  |  | Padding, any `EuiPanel` padding size. |

| Block | Description |
| --- | --- |
| default block | The section's content. |

</EuiText>
<!-- api:end -->
