<!-- empty on purpose -->

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### ValidatedForm

A form whose fields validate their own values with ember-validators
(`@validations`) or functions (`@customValidations`). Errors show once a
field is touched; submitting calls `@onSubmit` only when all fields are
valid.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@id` | `string` | a random id | Id of the form; fields join it with `form=`. |
| `@onInvalid` | `() => void` |  | Called on submit while a field is invalid (all fields show their errors). |
| `@onSubmit` | `() => void \| Promise<void>` |  | Called on submit when every field is valid. If it returns a promise that rejects, the fields are marked touched again. |
| `@onReset` | `(e: Event) => void` |  | Called when the form is reset. |
| `@onValidityChange` |  |  | Called when the form's validity or touched state changes, e.g. to disable the submit button while invalid. |
| `@theme` | `Partial<IValidatedFormTheme>` |  | Replaces the yielded field components (see the theme docs). |
| `@isDisabled` | `boolean` |  | Disables every field. |
| `@fullWidth` | `boolean` |  | Makes every field full width. |
| `@compressed` | `boolean` |  | Compressed fields, for dense forms. |
| `@tagName` |  |  | `'form'` (the default) or `'div'`. |
| `@isInvalid` |  |  | Shows `@error` in a callout above the form, see EuiForm. |
| `@invalidCallout` |  |  | See EuiForm's `@invalidCallout`. |
| `@error` |  |  | Form-level errors, see EuiForm's `@error`. |
| `@errorTitle` |  |  | Title of the errors callout. |

| Block | Description |
| --- | --- |
| default block | Yields the form's state (`isValid`, `isInvalid`, `isTouched`, `isInvalidAndTouched`, `formId`) and its field components, already connected to it: `as \|form\|` → `<form.FieldText @label="Name" @value={{this.name}} @onChange={{…}} @validations={{…}} />`. |

</EuiText>
<!-- api:end -->
