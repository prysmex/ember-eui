---
title: Loading
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Loading"/>
<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiLoadingSpinner

A spinning circle, for loading content or actions in progress.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@size` |  | `'m'` | `'s'`, `'m'`, `'l'` or `'xl'`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<span>`.

### EuiLoadingContent

Animated placeholder lines shown while text content loads.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@lines` | `number` | `1` | Number of lines, 1 to 10. |
| `@singleLineClasses` | `string` |  | Extra classes for each line. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<span>`.

### EuiLoadingLogo

A bouncing logo, for loading a whole page or app.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@logo` | `string` | `'logoKibana'` | The logo, anything `EuiIcon`'s `@type` accepts. |
| `@size` | `'m' \| 'l' \| 'xl'` | `'m'` | `'m'`, `'l'` or `'xl'`. |

</EuiText>
<!-- api:end -->
