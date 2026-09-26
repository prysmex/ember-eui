---
title: Loading
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Loading"/>
<EuiSpacer @size="l" />

<EuiText>

Loading indicators, from smallest to largest:

- **`EuiLoadingSpinner`** for a part of the page or an action in progress
  (buttons and fields have their own `@isLoading`).
- **`EuiLoadingContent`** shows animated placeholder lines where text will
  appear.
- **`EuiLoadingLogo`** for loading a whole app or page.

```hbs
<EuiLoadingSpinner @size="l" />
<EuiLoadingContent @lines={{3}} />
```

For progress with a known end, see `EuiProgress`.

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
