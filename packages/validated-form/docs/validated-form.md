---
title: Validated form
---

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

<EuiText>

## Nested forms

Use the yielded `Form` component to group fields into a nested validated form:

```hbs
<ValidatedForm @onSubmit={{this.save}} as |form|>
  <form.Form as |address|>
    <address.FieldText
      @label="City"
      @value={{this.city}}
      @onChange={{this.updateCity}}
      @validations={{hash presence=(hash presence=true)}}
    />
  </form.Form>
</ValidatedForm>
```

`FieldNestedForm` is an alias for `Form`. Both support further nesting and the
same arguments as `ValidatedForm`. The parent treats each nested form as one
field: it is valid when all its children are valid, and touched when any child
is touched. Removing a nested form removes its contribution to the parent.
Submitting the parent updates touched state throughout the nested fields.

Nested forms render as `div` elements by default, and their inputs belong to the
outer HTML form. They inherit the parent's theme, disabled state and full width
setting. Use the parent's submit and reset handlers for the entire form.

For a separately invoked `ValidatedForm`, wire `@register`, `@unregister` and
`@onValidityChange` to the corresponding yielded parent callbacks, and pass
`@tagName="div"` and `@formId={{form.formId}}` when nesting inside its HTML form.

## Model-aware wrappers

Override `theme.FieldNestedForm` to render your own wrapper for both `Form` and
`FieldNestedForm`. The wrapper may accept additional arguments such as `@model`
and extend the yielded fields with `(component Form.FieldText model=@model)`.
The parent still registers only the wrapper's inner validated form.

```js
import PrysmexModelForm from './prysmex-model-form';

// Add this entry to the theme supplied to the parent form.
const theme = { ...PrysmexTheme, FieldNestedForm: PrysmexModelForm };
```

```hbs
<PrysmexModelForm @theme={{this.theme}} @model={{this.model}} as |form|>
  <form.Form @model={{this.model.address}} as |address|>
    <address.FieldText @property="city" />
  </form.Form>
</PrysmexModelForm>
```

The `@property` argument in this example belongs to the application's model-aware
field component. The base library does not interpret models or property names.

The wrapper must forward these arguments to its underlying `ValidatedForm`:

```hbs
<PUi::ValidatedForm
  @theme={{assign this.theme @theme}}
  @id={{@id}}
  @tagName={{@tagName}}
  @formId={{@formId}}
  @register={{@register}}
  @unregister={{@unregister}}
  @onValidityChange={{@onValidityChange}}
  @isDisabled={{@isDisabled}}
  @fullWidth={{@fullWidth}}
  ...attributes
  as |Form|
>
  {{yield
    (assign Form (hash
      FieldText=(component Form.FieldText model=@model)
    ))
  }}
</PUi::ValidatedForm>
```

Preserving the inherited theme allows deeper nesting to use the same wrapper.
Pass a model explicitly to each nested form so it can edit a different record.
Keep any additional submit, reset, or application-specific arguments your wrapper
already forwards. A nested form contributes validation to the parent's submit;
its own submit handler does not run when the parent submits.

</EuiText>

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
