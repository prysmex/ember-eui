---
title: Validated form
---

# Validated form

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
