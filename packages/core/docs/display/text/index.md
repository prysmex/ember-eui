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
| `@size` | `'xs' \| 's' \| 'm' \| 'relative'` | `'s'` | `'xs'`, `'s'`, `'m'` or `'relative'` (inherits). |
| `@textAlign` | `EuiTextAlignment` |  | `'left'`, `'center'` or `'right'` (logical, so they flip in RTL). |
| `@color` | `EuiTextColorValue` |  | Any EuiTextColor value: a named color such as `'subdued'` or `'danger'`, or a CSS color. Inherits when omitted. |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |

| Block | Description |
| --- | --- |
| default block | HTML content (paragraphs, lists, headings, code…), styled by EuiText. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiTextColor

Colors its text content.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@color` | `EuiTextColorValue` | `'default'` | `'default'`, `'subdued'`, `'success'`, `'accent'`, `'accentSecondary'`, `'danger'`, `'warning'`, `'ghost'`, `'inherit'`, `'primary'`, or any CSS color value. |
| `@tagName` | `'span' \| 'div' \| 'p'` | `'span'` | `'span'` (inline), `'div'` or `'p'`. |

| Block | Description |
| --- | --- |
| default block | The content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<span>` / `<div>` / `<p>`.

### EuiTextAlign

Aligns its text content.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@textAlign` | `EuiTextAlignment` | `'left'` | `'left'`, `'center'` or `'right'`. Left and right are logical: they map to `start`/`end`, so they flip in RTL. |
| `@tagName` | `'div' \| 'span' \| 'p'` | `'div'` | `'div'`, `'span'` or `'p'`. |

| Block | Description |
| --- | --- |
| default block | The content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>` / `<span>` / `<p>`.

</EuiText>
<!-- api:end -->
