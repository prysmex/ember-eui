<EuiSpacer/>
<EuiPageHeader @pageTitle="Described form groups"/>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiDescribedFormGroup

A section of a long form: a title and description on the left, its
fields on the right (stacked on small screens).

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@fullWidth` | `boolean` |  | Lets the fields column grow to the container's width. |
| `@gutterSize` |  | `'l'` | Space between the description and the fields. |
| `@titleSize` |  | `'xs'` | Size of the title, any `EuiTitle` size; also aligns the fields with it. |
| `@titleTagName` |  |  | Tag of the title, e.g. `'h3'`. |
| `@fieldFlexItemProps` |  |  | Props for the fields column: `{ grow, class }`. |
| `@descriptionFlexItemProps` |  |  | Props for the title and description column: `{ grow, class }`. |

| Block | Description |
| --- | --- |
| default block | The fields, usually `EuiFormRow`s. |
| `<:title>` | Title of the group (on the left), as text: it is rendered in an `EuiTitle` whose tag is `@titleTagName`. |
| `<:description>` | Explanation under the title. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
