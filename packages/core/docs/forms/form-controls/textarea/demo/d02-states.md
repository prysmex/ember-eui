---
order: 2
---

# Resizing and states

<EuiText>

`@resize` is `vertical` (default), `horizontal`, `both` or `none`. The
usual states apply: `@isInvalid`, `@compressed`, `@readOnly`, `@disabled`
and `@fullWidth`.

</EuiText>

```hbs template
<EuiFormRow @label="No resizing">
  <EuiTextArea @resize="none" @rows={{2}} @value="Fixed size" />
</EuiFormRow>
<EuiFormRow @label="Invalid" @isInvalid={{true}} @error="Required.">
  <EuiTextArea @isInvalid={{true}} @rows={{2}} />
</EuiFormRow>
<EuiFormRow @label="Compressed" @display="rowCompressed">
  <EuiTextArea @compressed={{true}} @rows={{2}} @value="Dense forms" />
</EuiFormRow>
<EuiFormRow @label="Disabled">
  <EuiTextArea @disabled={{true}} @rows={{2}} @value="Can't edit" />
</EuiFormRow>
```
