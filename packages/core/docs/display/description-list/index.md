---
title: Description list
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Description list"/>
<EuiSpacer @size="l" />

<EuiText>

**EuiDescriptionList** is a component for listing pairs of information together, e.g. the properties of an item. Pass the pairs as `@listItems`, or write them with **EuiDescriptionListTitle** and **EuiDescriptionListDescription**.

`@type` lays the pairs out in rows (default), `column`s, `responsiveColumn`s or `inline`; `@textStyle="reverse"` emphasizes the descriptions instead of the titles.

</EuiText>

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
| `@type` | `EuiDescriptionListType` | `'row'` | `'row'` stacks each title above its description, `'column'` puts them side by side, `'responsiveColumn'` is a column that stacks below the `m` breakpoint, `'inline'` flows them as compact inline text. |
| `@textStyle` | `'normal' \| 'reverse'` | `'normal'` | `'reverse'` styles the descriptions as the prominent text and the titles as the smaller labels. |
| `@align` | `'left' \| 'center'` | `'left'` | `'left'` or `'center'`. |
| `@rowGutterSize` | `'s' \| 'm'` | `'s'` | Space between rows: `'s'` or `'m'`. Column lists use it as the grid's row gap, row lists as the title's top margin. |
| `@columnGutterSize` | `'s' \| 'm'` | `'s'` | Space between the columns of a column list: `'s'` or `'m'`. |
| `@columnWidths` | `[number \| string, number \| string]` |  | Widths of the title and description columns of a column list: numbers are `fr` units, strings any grid track (`'200px'`, `'minmax(…)'`). |
| `@listItems` | `{ title: string; description: string; }[]` |  | The terms: `[{ title: 'Name', description: 'Jane' }]`. Without it, pass `EuiDescriptionListTitle` / `EuiDescriptionListDescription` in the block. |
| `@titleProps` | `{ className?: string; }` |  | Props for each title from `@listItems`: `{ className }`. |
| `@descriptionProps` | `{ className?: string; }` |  | Props for each description from `@listItems`: `{ className }`. |

| Block | Description |
| --- | --- |
| default block | Pairs of `EuiDescriptionListTitle` and `EuiDescriptionListDescription` (ignored when `@listItems` is set). |

### EuiDescriptionListTitle

A term (`<dt>`) in an EuiDescriptionList. Its styles follow the nearest
list's `@type`, `@textStyle`, `@compressed`, `@align` and `@rowGutterSize`.

| Block | Description |
| --- | --- |
| default block | The text. |

### EuiDescriptionListDescription

The description (`<dd>`) of the term before it, in an EuiDescriptionList.
Its styles follow the nearest list's `@type`, `@textStyle`, `@compressed`
and `@align`.

| Block | Description |
| --- | --- |
| default block | The text. |

</EuiText>
<!-- api:end -->
