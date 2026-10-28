---
'@ember-eui/changeset-form': patch
---

The fields `EuiChangesetForm` yields no longer require the args they pass to their control themselves, so `<form.FieldSwitch @fieldName="x" @label="…" />` type-checks. `FieldSwitch` dropped `@checked`, `FieldRadioGroup` `@idSelected`, `FieldCheckboxGroup` `@idToSelectedMap` and `FieldDualRangeSlider` `@value` from their args, and their `@onChange` is the field's own optional callback instead of also being the control's required one. Glint rejected these fields with "Property 'checked' is missing" and the like, though they worked at runtime. `FieldText`, `FieldTextArea`, `FieldPassword`, `FieldNumber` and `FieldSelect` no longer take `@value`: they read the value from the changeset and ignored it.
