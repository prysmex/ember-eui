---
title: Title
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Title"/>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiTitle

A heading styled with EUI's type scale:
`<EuiTitle @size="s" @tagName="h3">Settings</EuiTitle>`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@tagName` |  | `'h2'` | The heading tag EuiTitle renders: `'h1'`–`'h6'`, `'p'` or `'legend'`. Put the text directly inside EuiTitle; do not wrap it in another heading. |
| `@size` |  | `'m'` | `'xxxs'`, `'xxs'`, `'xs'`, `'s'`, `'m'` or `'l'`. Size is independent of the tag: pick the tag for the page outline and the size for the look. |
| `@textTransform` |  |  | `'uppercase'` for all caps. |

| Block | Description |
| --- | --- |
| default block | The title's text. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<h1…h6>`.

</EuiText>
<!-- api:end -->
