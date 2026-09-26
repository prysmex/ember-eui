<EuiSpacer/>
<EuiPageHeader @pageTitle="Changeset form"/>
<EuiSpacer @size="l" />

<EuiText>

`@ember-eui/changeset-form` binds EUI form fields to an
[ember-changeset](https://github.com/adopted-ember-addons/ember-changeset):
each field reads and writes one property of the changeset (by
`@fieldName`) and shows that property's validation errors. Submitting the
form validates the changeset and, when it is valid, saves it.

```bash
pnpm add @ember-eui/changeset-form ember-changeset ember-changeset-validations
```

```hbs
<EuiChangesetForm
  @changeset={{changeset this.user this.UserValidations}}
  @onSubmit={{this.saved}}
  as |Form changeset|
>
  <Form.FieldText @fieldName="name" @label="Name" />
  <Form.FieldText @fieldName="email" @label="Email" />
  <Form.FieldSelect @fieldName="role" @label="Role" @options={{this.roles}} />
  <EuiButton @type="submit" @fill={{true}} @isDisabled={{changeset.isInvalid}}>Save</EuiButton>
</EuiChangesetForm>
```

```js
import { validatePresence, validateFormat } from 'ember-changeset-validations/validators';

export const UserValidations = {
  name: validatePresence(true),
  email: validateFormat({ type: 'email' }),
};
```

The form yields its fields already bound to the changeset: `FieldText`,
`FieldTextArea`, `FieldNumber`, `FieldPassword`, `FieldSelect`,
`FieldComboBox`, `FieldCheckbox`, `FieldCheckboxGroup`, `FieldRadio`,
`FieldRadioGroup`, `FieldSwitch`, `FieldRangeSlider`,
`FieldDualRangeSlider`, and `FieldBase` for your own controls. Each field
takes `EuiFormRow`'s args (`@label`, `@helpText`, …) and its control's args.
Nested properties work (`@fieldName="address.city"`).

On submit the form calls `@beforeSubmit`, validates, then
`changeset.save()` (or `changeset.execute()` with
`@runExecuteInsteadOfSave`) and `@onSubmit` with the saved data. Errors
show on each field as soon as it is validated; `@initialValidation`
validates everything on render.

`FieldComboBox` needs `@onChange`: set the changeset value yourself there
(e.g. to store ids instead of objects); the field validates it.

</EuiText>

<EuiHorizontalRule />

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
