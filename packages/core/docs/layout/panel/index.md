---
title: Panel
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Panel"/>

<EuiText>
  <p>
<strong>EuiPanel</strong> is a building block component. Use it as a layout helper for containing content. It is also commonly used as a base for other larger components like <strong>EuiPage</strong>, <strong>EuiPopover</strong> and <strong>EuiCard</strong>.
  </p>
</EuiText>

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
| `@onClick` | `(e: MouseEvent) => void` |  | Makes the whole panel clickable (hover styles, `role="button"`). |
| `@isClickable` | `boolean` | `true` | Hover styles for a clickable panel. |

| Block | Description |
| --- | --- |
| default block | The panel's content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
