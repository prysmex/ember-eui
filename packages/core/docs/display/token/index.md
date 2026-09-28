---
title: Token
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Token"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiToken` is a small icon in a colored shape that tells the type of
something at a glance: a field's type (string, number, date, geo point…)
in a list of fields, or a symbol's kind in code search.

```hbs
<EuiToken @iconType="tokenString" @title="String field" />
```

EUI's `token*` icons (`tokenString`, `tokenNumber`, `tokenDate`,
`tokenGeo`, `tokenKeyword`, …) come with a shape and color, so the same
type always looks the same. Any other icon works too, with `@color`,
`@shape` and `@fill` (all of which also override the presets). Give it a
`@title` for screen readers.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiToken

A small icon in a colored shape that tells the type of a value or code
symbol, e.g. a field's type (string, number, date) in a list of fields.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@iconType` (required) | `IconType` |  | The icon: one of EUI's `token*` icons (`'tokenString'`, `'tokenNumber'`, `'tokenDate'`, …), which come with their own shape and color, or any other `EuiIcon` type. |
| `@color` | `string` | the token icon's color, or `'gray'` | `'euiColorVis0'` to `'euiColorVis9'`, `'gray'`, or a hex color (which forces `@fill="dark"` unless `@fill="none"`). |
| `@shape` | `'circle' \| 'square' \| 'rectangle'` | the token icon's, or `'circle'` | `'circle'`, `'square'` or `'rectangle'`. |
| `@fill` | `'light' \| 'dark' \| 'none'` | the token icon's, or `'light'` | `'light'` (tinted with a border), `'dark'` (solid) or `'none'`. |
| `@size` | `'xs' \| 's' \| 'm' \| 'l'` | `'s'` | `'xs'`, `'s'`, `'m'` or `'l'`. |
| `@title` | `string` |  | Title of the icon, read by screen readers, e.g. "String field". |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<span>`.

</EuiText>
<!-- api:end -->
