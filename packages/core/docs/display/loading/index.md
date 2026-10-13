---
title: Loading
# not .../loading: Ember renders a route named `loading` as its parent's loading substate
url: docs/display/loading-indicators
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Loading"/>
<EuiSpacer @size="l" />

<EuiText>

Use loading indicators sparingly and opt for showing actual [progress](/docs/display/progress) over infinite spinners. It is ok to use multiple loaders on a page if each section is progressively loaded. However, if the entire page is loaded at once, use a single, larger loading indicator.

`EuiLoadingContent` (animated placeholder lines) is an Ember EUI extension, shown after the upstream examples.

</EuiText>

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
| `@size` | `'s' \| 'm' \| 'l' \| 'xl' \| 'xxl'` | `'m'` | `'s'`, `'m'`, `'l'`, `'xl'` or `'xxl'`. |
| `@color` | `{ border?: string; highlight?: string }` |  | Native upstream border/highlight color customization. |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<span>`.

### EuiLoadingContent

Animated placeholder lines shown while text content loads. Drawn with
upstream EuiSkeletonText's styles (EuiLoadingContent's latest successor).

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@lines` | `number` | `1` | Number of lines, 1 to 10. |
| `@size` | `'m' \| 's' \| 'xs' \| 'relative'` | `'m'` | Line height of the text being replaced: `'m'`, `'s'`, `'xs'` (EuiText sizes) or `'relative'` (`1em`). |
| `@singleLineClasses` | `string` |  | Extra classes for each line. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<span>`.

### EuiLoadingLogo

A bouncing logo, for loading a whole page or app.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@logo` | `string` | `'logoKibana'` | The logo, anything `EuiIcon`'s `@type` accepts. |
| `@size` | `'m' \| 'l' \| 'xl'` | `'m'` | `'m'`, `'l'` or `'xl'`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<span>`.

### EuiLoadingChart

Animated bars, for a chart or visualization that is loading.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@size` | `'m' \| 'l' \| 'xl'` | `'m'` | `'m'`, `'l'` or `'xl'`. |

Deprecated: `@mono` (Has no effect: latest EUI draws every chart loader with the neutral `loadingChartMonoBackground` tokens.).

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<span>`.

### EuiLoadingElastic

The Elastic logo, animated, for a full page or app that is loading.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@size` | `'m' \| 'l' \| 'xl' \| 'xxl'` | `'m'` | `'m'`, `'l'`, `'xl'` or `'xxl'`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<span>`.

</EuiText>
<!-- api:end -->
