---
title: Progress
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Progress"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiProgress` shows progress as a bar. Without `@max` it is an
indeterminate animation (something is loading); with `@max` and `@value`
it shows how much is done, optionally with a label and the value.

```hbs
<EuiProgress @size="xs" @color="accent" />
<EuiProgress @value={{70}} @max={{100}} @size="m" @valueText={{true}}>
  <:label>Uploading</:label>
</EuiProgress>
```

`@position="fixed"` pins a bar to the top of the window (e.g. while a
route loads); `@position="absolute"` pins it to the top of its
positioned parent.

</EuiText>

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
| `@size` | `'xs' \| 's' \| 'm' \| 'l'` | `'m'` | Thickness: `'xs'`, `'s'`, `'m'` or `'l'`. |
| `@position` | `'static' \| 'fixed' \| 'absolute'` | `'static'` | `'static'` renders in place; `'fixed'` / `'absolute'` pin it to the top of the window / its positioned parent. |
| `@color` | `EuiProgressColor` | `'success'` | `'primary'`, `'success'`, `'warning'`, `'danger'`, `'subdued'`, `'accent'`, `'accentSecondary'`, `'vis0'`–`'vis9'`, or any CSS color. |
| `@labelClasses` | `string` |  | Classes for the value text. |
| `@valueText` | `string \| boolean` |  | `true` shows `@value` as a percentage ("70%") above the bar; a string shows that text. For other content use the `<:valueText>` block. |
| `@label` | `string` |  | Label above the bar (with `@max`); or use the `<:label>` block. |

| Block | Description |
| --- | --- |
| `<:label>` | Label above the bar (with `@max`). |
| `<:valueText>` | Value text above the bar, e.g. "70%" (with `@max`). |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>` / `<progress>`.

</EuiText>
<!-- api:end -->
