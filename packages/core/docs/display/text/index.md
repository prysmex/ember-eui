---
title: Text
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Text"/>

<EuiText>

<strong>EuiText</strong> is a generic catchall wrapper that will apply our standard typography styling and spacing to naked HTML. Because of its forced styles, it <strong>only accepts raw XHTML</strong>.

</EuiText>

<EuiSpacer />

<EuiCallOut @title="Use direct descendants" @color="warning" @iconType="warning">
  <ul>
    <li>All your XHTML elements should be direct descendants of <strong>EuiText</strong>. Avoid wrapping them in a <EuiCode>div</EuiCode> or <EuiCode>span</EuiCode>. This will ensure styles are applied correctly.</li>
    <li>Avoid nesting Ember components, which would break their styling.</li>
  </ul>
</EuiCallOut>

<EuiSpacer />

<EuiText>

<strong>EuiText</strong> can ensure proper line-length for readability by setting a <EuiCode>max-width</EuiCode> on the entire component. To add the max-width setting, set `@grow={{false}}`.

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
| `@component` | `string` | `'div'` | The element to render: a tag name such as `'span'` or `'p'` (upstream's `component`). |
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
