---
'@ember-eui/core': patch
---

`EuiComboBox`: a selection given as an Ember array-like without `slice()` (e.g. ember-data's PromiseManyArray) shows its pills again. The component read it as a list, but handed it to ember-power-select as is, and the pills, rendered with `{{#each}}`, couldn't iterate it.
