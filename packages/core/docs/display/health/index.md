---
title: Health
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Health"/>

<EuiHorizontalRule />
<EuiText>
<p>
<p>The <strong>EuiHealth</strong> component should be used when showing comparitive health of listed objects (like servers, HTTP response status codes(as per convenience), nodes, indexes..etc). Because icons are vague and bulky and color alone does not work, color plus text provides a recognizable, lightweight combo that works in most situations.</p>
</p>
</EuiText>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiHealth

A status: a colored dot followed by text, e.g. "Healthy" or "Down".

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@color` | `string` |  | Color of the dot: `'success'`, `'warning'`, `'danger'`, `'subdued'`, any `EuiIcon` color or a CSS color. |
| `@textSize` |  | `'m'` | Text size: `'xs'`, `'s'`, `'m'` or `'inherit'`. |

| Block | Description |
| --- | --- |
| default block | The status text. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
