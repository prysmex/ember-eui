---
title: Empty Prompt
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Empty prompt"/>
<EuiSpacer/>
<EuiText>
  <p>
  The <strong>EuiEmptyPrompt</strong> is the building block to create an empty state. You can use it as a placeholder for any type of empty content. They are especially helpful for replacing entire pages or parts of a product that contain no content.
   </p>
</EuiText>
<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiEmptyPrompt

A message filling an empty page or section: an icon, a title, some text
and actions, e.g. when a list has no items yet or a page failed to load.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@layout` | `'vertical' \| 'horizontal'` | `'vertical'` | `'vertical'` centers everything in a column; `'horizontal'` puts the icon beside the text. |
| `@paddingSize` |  | `'l'` | Padding around the content, any `EuiPanel` padding size. |
| `@color` |  | `'transparent'` | Background, any `EuiPanel` color (`'plain'`, `'subdued'`, `'danger'`, …). |
| `@hasBorder` |  |  | Adds a border around the prompt. |
| `@iconType` |  |  | Large icon above the title, e.g. `'search'` or `'logoKibana'`. |
| `@iconColor` |  | `@color`, or `'subdued'` | Color of the icon. |
| `@title` | `string` |  | Title, e.g. "No dashboards yet". |
| `@titleSize` |  | `'m'` | Size of the title, any `EuiTitle` size. |
| `@body` | `string` |  | Text explaining the situation and what to do. |
| `@actions` | `ComponentLike[]` |  | Components rendered as the prompt's actions (e.g. a primary `EuiButton` and an `EuiButtonEmpty`), laid out in a row or column. Use the `<:content>` block for full control. |
| `@footer` | `string` |  | Text in a footer, e.g. a link to the docs. Use the `<:footer>` block for markup. |

| Block | Description |
| --- | --- |
| `<:icon>` | Custom content instead of the `@iconType` icon, e.g. an `EuiImage`. |
| `<:content>` | Replaces the title, body and actions with your own content. |
| `<:footer>` | The footer, instead of `@footer`. |

</EuiText>
<!-- api:end -->
