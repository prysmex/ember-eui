---
title: Text
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Text"/>

<EuiText>
  <p>
<strong>EuiText</strong> is a generic catchall wrapper that will apply our standard typography styling and spacing to naked HTML. Because of its forced style it <strong>only accepts raw XHTML</strong> and can not / should not be used to wrap React components (which would break their styling).

EuiText can ensure proper line-length for readability by setting a <EuiCode>max-width</EuiCode> on the entire component. To add the max-width setting, set <EuiCode>@grow=&#123;&#123;false&#125;&#125;</EuiCode>.

  </p>
</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiText

Styles plain HTML content (`<p>`, `<ul>`, `<h3>`, `<code>`…) with EUI's typography.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@grow` | `boolean` | `true` | `true` lets text span the container's full width; `false` caps lines at a readable width. |
| `@size` |  | `'m'` | `'xs'`, `'s'`, `'m'` or `'relative'` (inherits). |
| `@textAlign` |  |  | `'left'`, `'center'` or `'right'`. |
| `@color` |  |  | `'default'`, `'subdued'`, `'success'`, `'accent'`, `'danger'`, `'warning'`, `'ghost'` or `'primary'`. |

| Block | Description |
| --- | --- |
| default block | HTML content (paragraphs, lists, headings, code…), styled by EuiText. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiTextColor

Colors its text content.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@color` | `string` | `'default'` | `'default'`, `'subdued'`, `'success'`, `'accent'`, `'danger'`, `'warning'`, `'ghost'` or `'primary'`. |
| `@tagName` | `string` | `'span'` | `'span'` (inline) or `'div'`. |

| Block | Description |
| --- | --- |
| default block | The content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>` / `<span>`.

### EuiTextAlign

Aligns its text content.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@textAlign` | `'left' \| 'center' \| 'right'` | `'left'` | `'left'`, `'center'` or `'right'`. |

| Block | Description |
| --- | --- |
| default block | The content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
