---
title: Described form groups
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Described form groups"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiDescribedFormGroup` splits a long form into titled sections, each
with an explanation on the left and its fields on the right, like a
settings page.

```hbs
<EuiDescribedFormGroup @titleTagName="h3">
  <:title>Notifications</:title>
  <:description>Choose how we reach you.</:description>
  <:default>
    <EuiFormRow @label="Email"><EuiFieldText /></EuiFormRow>
  </:default>
</EuiDescribedFormGroup>
```

Put the text of the title directly in `<:title>` (it is already wrapped
in an `EuiTitle` heading, `h2` unless `@titleTagName` says otherwise).

</EuiText>

<EuiHorizontalRule />

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
| `@fullWidth` | `boolean` | the enclosing EuiForm's `@fullWidth`, else `false` | Lets the group grow to the container's width instead of twice the theme's form max width. |
| `@gutterSize` |  | `'l'` | Space between the description and the fields. |
| `@ratio` | `EuiDescribedFormGroupRatio` | `'half'` | Width of the fields column relative to the description: `'half'` (1:1), `'third'` (fields 2:1) or `'quarter'` (fields 3:1). |
| `@titleSize` |  | `'xs'` | Size of the title, any `EuiTitle` size. |
| `@titleTagName` |  | `'h2'` | Tag of the title, e.g. `'h3'`. |
| `@fieldFlexItemProps` |  |  | Props for the fields column: `{ grow, class }`. |
| `@descriptionFlexItemProps` |  |  | Props for the title and description column: `{ grow, class }`. |

| Block | Description |
| --- | --- |
| default block | The fields, usually `EuiFormRow`s. |
| `<:title>` | Title of the group (on the left), as text: it is rendered in an `EuiTitle` whose tag is `@titleTagName`, and names the group (`aria-labelledby`) unless the group has its own `aria-label` or `aria-labelledby`. |
| `<:description>` | Explanation under the title. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
