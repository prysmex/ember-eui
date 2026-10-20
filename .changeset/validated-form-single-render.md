---
'@ember-eui/validated-form': patch
---

Fields render once when inserted and once per value change, instead of twice each time: their error messages are derived from the value and the validations rather than stored after every render and again in a timer. The form keeps track of which children are invalid or touched as each child reports its change, so a keystroke no longer asks every other field of the form for its validity, and `@onValidityChange` is called in the same run loop as the change instead of the next one. App fields that extend `FieldBase` keep working: `setValidationMessages`, `didUpdateValue` and assigning `_validationErrorMessages` still do what they did.
