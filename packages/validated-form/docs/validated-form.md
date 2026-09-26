<EuiSpacer/>
<EuiPageHeader @pageTitle="Validated form"/>
<EuiSpacer @size="l" />

<EuiText>

`@ember-eui/validated-form` is a form whose fields validate their own
values: pass `@validations` (with
[ember-validators](https://github.com/rwjblue/ember-validators)) or
`@customValidations` to each field. Errors show once a field has been
touched (blurred) or the form submitted, and `@onSubmit` runs only when
every field is valid.

```bash
pnpm add @ember-eui/validated-form
```

```hbs
<ValidatedForm @onSubmit={{this.save}} as |Form|>
  <Form.FieldText
    @label="Email"
    @value={{this.email}}
    @onChange={{this.updateEmail}}
    @validations={{hash presence=(hash presence=true) format=(hash type="email")}}
  />
  <EuiButton @type="submit" @fill={{true}}>Save</EuiButton>
</ValidatedForm>
```

Unlike the changeset form, you keep the values: each field shows
`@value` and calls `@onChange` with the new value. `@validations` is a
hash of ember-validators validators and their options (`presence`,
`length`, `format`, `number`, `inclusion`, `date`, …). For other rules,
`@customValidations` takes functions returning `true` or an error
message:

```js
customValidations = [
  { validation: (value) => value !== 'admin' || 'This name is reserved' },
];
```

The yielded fields are `FieldText`, `FieldTextArea`, `FieldNumber`,
`FieldPassword`, `FieldSelect`, `FieldComboBox`, `FieldCheckboxGroup`,
`FieldRadioGroup`, `FieldSwitch`, `FieldRangeSlider`,
`FieldDualRangeSlider` and `FieldMarkdownEditor`; each also takes
`EuiFormRow`'s args and its control's args. `@onValidityChange` on the
form tells you when the whole form becomes valid or invalid.

</EuiText>

<EuiHorizontalRule />

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
