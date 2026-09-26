---
title: Stat
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Stat"/>

<EuiText>
    <p>
    <strong>EuiStat</strong> can be used to display prominent text or number values. It consists of <EuiCode>title</EuiCode> and <EuiCode>description</EuiCode> elements with several visual styling properties (examples below).
    </p>
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
| `@textAlign` |  | `'left'` | `'left'`, `'center'` or `'right'`. |
| `@title` | `string` |  | The number or value, e.g. "1,234". Use the `<:title>` block for markup. |
| `@description` | `string` |  | What it measures, e.g. "Total users". Use the `<:description>` block for markup. |
| `@titleColor` |  | `'default'` | Color of the title: `'default'`, `'subdued'`, `'primary'`, `'success'`, `'danger'`, `'accent'`, or any CSS color. |
| `@titleSize` |  | `'l'` | Size of the title, any `EuiTitle` size. |
| `@isLoading` | `boolean` |  | Shows "--" instead of the title, e.g. while it loads. |
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
