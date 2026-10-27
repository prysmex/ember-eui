---
title: Stat
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Stat"/>

<EuiText>

**EuiStat** can be used to display prominent text or number values. It consists of `@title` and `@description` elements with several visual styling arguments (examples below).

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiStat

A key number with a description, e.g. on a dashboard.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@textAlign` | `EuiStatTextAlign` | `'left'` | `'left'`, `'center'` or `'right'` (logical, so left/right flip in RTL). |
| `@title` | `string \| number` |  | The number or value, e.g. `1234` or "1,234". Use the `<:title>` block for markup. |
| `@description` | `string` |  | What it measures, e.g. "Total users". Use the `<:description>` block for markup. |
| `@titleColor` | `EuiStatTitleColor \| string` | `'default'` | Color of the title: `'default'`, `'subdued'`, `'primary'`, `'success'`, `'warning'`, `'danger'`, `'accent'`, or any CSS color. |
| `@titleSize` |  | `'l'` | Size of the title, any `EuiTitle` size. |
| `@isLoading` | `boolean` |  | Shows "--" instead of the title, pulses it (unless reduced motion is requested) and labels it "Statistic is loading" (i18n token `euiStat.loadingText`). |
| `@reverse` | `boolean` | `false` | Puts the title above the description. |
| `@titleElement` | `string` | `'p'` | Tag of the title. |
| `@descriptionElement` |  | `'p'` | Tag of the description. |

Deprecated: `@screenReader` (Has no effect.).

| Block | Description |
| --- | --- |
| `<:title>` | The title, instead of `@title`. |
| `<:description>` | The description, instead of `@description`. |
| default block | Extra content after the stat, e.g. a trend. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
