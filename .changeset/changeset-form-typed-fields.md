---
'@ember-eui/changeset-form': patch
---

The fields `EuiChangesetForm` yields (`FieldText`, `FieldTextArea`, `FieldCheckbox`, `FieldComboBox`, …) keep their own types: their args, named blocks and element. They were typed `ComponentLike<any>`, so Glint rejected element attributes such as `<form.FieldText @fieldName="x" type="color" class="pl-24" />` and named blocks such as `<:prepend as |classes|>`. Each is now its field component with the args the form passes it (`changeset`, `formId`, `fullWidth`, `hasSubmitted`, `disabled`) made optional (type `EuiChangesetFormFields`). `EuiChangesetFormDefaultTheme` has the precise component types; a `@theme` field is expected to take the same args as the default one it replaces.
