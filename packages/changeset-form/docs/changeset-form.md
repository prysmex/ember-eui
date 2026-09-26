<!-- empty on purpose -->

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiChangesetForm

A form bound to an ember-changeset: each field reads and writes a
property of the changeset (`@fieldName`) and shows its validation
errors; submitting validates, then saves the changeset.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@id` | `string` | a random id | Id of the form; fields join it with `form=`. |
| `@changeset` (required) | `BufferedChangeset` |  | The ember-changeset (usually with validations, e.g. from ember-changeset-validations) whose properties the fields edit. |
| `@beforeSubmit` | `(changeset: BufferedChangeset, e: Event) => void` |  | Called on submit before validating, e.g. to set derived values. |
| `@onSubmit` | `(data: {}, e: Event) => void` |  | Called when the form is submitted and the changeset is valid, after `changeset.save()` (or `execute()`), with the saved data. |
| `@onReset` | `(data: {}, e: Event) => void` |  | Called when the form is reset, after `changeset.rollback()`, with the data. |
| `@runExecuteInsteadOfSave` | `boolean` | `false` | Applies the changes to the underlying object with `changeset.execute()` instead of saving it. |
| `@fullWidth` | `boolean` |  | Makes every field full width. |
| `@initialValidation` | `boolean` |  | Validates the whole changeset on render, showing errors right away. |
| `@theme` | `Partial<IEuiChangesetFormTheme>` |  | Replaces the yielded field components (see the theme docs). |
| `@isDisabled` | `boolean` |  | Disables every field. |

| Block | Description |
| --- | --- |
| default block | Yields the field components (bound to the changeset), the changeset, whether the form was submitted and the form's id: `as \|Form changeset hasSubmitted\|` → `<Form.FieldText @fieldName="name" @label="Name" />`. |

</EuiText>
<!-- api:end -->
