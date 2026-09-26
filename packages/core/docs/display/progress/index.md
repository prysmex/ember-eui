---
title: Progress
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Progress"/>
<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiProgress

A progress bar: a value out of `@max`, or an indeterminate loading bar.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@max` | `number` |  | Maximum value. With it the bar shows `@value`; without it the bar is an indeterminate loading animation. |
| `@value` | `number` |  | Current value, from 0 to `@max`. |
| `@size` |  | `'m'` | Thickness: `'xs'`, `'s'`, `'m'` or `'l'`. |
| `@position` |  | `'static'` | `'static'` renders in place; `'fixed'` / `'absolute'` pin it to the top of the window / its positioned parent. |
| `@color` |  | `'success'` | `'primary'`, `'success'`, `'warning'`, `'danger'`, `'subdued'`, `'accent'` or `'vis0'`–`'vis9'`. |
| `@labelClasses` | `string` |  | Classes for the value text. |
| `@valueText` | `string \| boolean` |  | `true` shows `@value` above the bar; for other text use the `<:valueText>` block. |

Deprecated: `@label` (Has no effect, use the `<:label>` block.).

| Block | Description |
| --- | --- |
| `<:label>` | Label above the bar (with `@max`). |
| `<:valueText>` | Value text above the bar, e.g. "70%" (with `@max`). |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>` / `<progress>`.

</EuiText>
<!-- api:end -->
