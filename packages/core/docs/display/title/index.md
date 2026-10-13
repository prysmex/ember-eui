---
title: Title
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Title"/>
<EuiSpacer @size="l" />

<EuiText>

**EuiTitle** styles the page, section, and content headings we use in Kibana. Unlike **EuiText** it is margin neutral and more suitable for general layout design. It renders a heading styled with EUI's type scale. Its tag and
its size are independent: choose the tag (`@tagName`, `h2` by default)
for the page's outline, and the size (`@size`, `m` by default) for how
it looks.

```hbs
<EuiTitle @size="l" @tagName="h1">Dashboards</EuiTitle>
<EuiTitle @size="xs" @tagName="h3">Recent</EuiTitle>
```

Put the text directly inside `EuiTitle`; it already is the heading
element, so don't wrap the text in another `<h2>`.

</EuiText>

<EuiHorizontalRule />

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
| `@size` | `'xxxs' \| 'xxs' \| 'xs' \| 's' \| 'm' \| 'l'` | `'m'` | `'xxxs'`, `'xxs'`, `'xs'`, `'s'`, `'m'` or `'l'`. Size is independent of the tag: pick the tag for the page outline and the size for the look. |
| `@textTransform` | `'uppercase'` |  | `'uppercase'` for all caps. |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |

| Block | Description |
| --- | --- |
| default block | The title's text. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<h1…h6>` / `<p>` / `<legend>`.

</EuiText>
<!-- api:end -->
