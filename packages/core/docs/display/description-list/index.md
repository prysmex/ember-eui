---
title: Description list
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Description list"/>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiDescriptionList

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@compressed` | `boolean` |  | Smaller text. |
| `@type` |  | `'row'` | `'row'` stacks each title above its description, `'column'` puts them side by side, `'responsiveColumn'` is a column that stacks on small screens, `'inline'` flows them as compact inline text. |
| `@textStyle` |  | `'normal'` | `'reverse'` styles the descriptions as the prominent text and the titles as the smaller labels. |
| `@align` |  | `'left'` | `'left'` or `'center'`. |
| `@listItems` | `{ title: string; description: string; }[]` |  | The terms: `[{ title: 'Name', description: 'Jane' }]`. Without it, pass `EuiDescriptionListTitle` / `EuiDescriptionListDescription` in the block. |
| `@titleProps` | `{ className?: string; }` |  | Props for each title from `@listItems`: `{ className }`. |
| `@descriptionProps` | `{ className?: string; }` |  | Props for each description from `@listItems`: `{ className }`. |

| Block | Description |
| --- | --- |
| default block | Pairs of `EuiDescriptionListTitle` and `EuiDescriptionListDescription` (ignored when `@listItems` is set). |

### EuiDescriptionListTitle

A term (`<dt>`) in an EuiDescriptionList.

| Block | Description |
| --- | --- |
| default block | The text. |

### EuiDescriptionListDescription

The description (`<dd>`) of the term before it, in an EuiDescriptionList.

| Block | Description |
| --- | --- |
| default block | The text. |

</EuiText>
<!-- api:end -->
