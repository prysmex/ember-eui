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
| `@shape` | `TokenShape` | the token icon's, or `'circle'` | `'circle'`, `'square'` or `'rectangle'`. |
| `@fill` | `EuiTokenFill` | `'light'` | `'light'` (tinted with a border), `'dark'` (solid) or `'none'`. |
| `@size` | `TokenSize` | `'s'` | `'xs'` (8px), `'s'` (16px), `'m'` (24px) or `'l'` (32px). |
| `@title` | `string` |  | Title of the icon, read by screen readers, e.g. "String field". |
| `@aria-label` | `string` |  | Accessible label of the icon, instead of `@title`. |
| `@aria-labelledby` | `string` |  | Id(s) of the element(s) labelling the icon. |
| `@aria-describedby` | `string` |  | Id(s) of the element(s) describing the icon. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<span>`.

</EuiText>
<!-- api:end -->
