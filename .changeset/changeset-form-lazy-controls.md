---
'@ember-eui/changeset-form': patch
---

The heavy fields load their control on demand: `FieldComboBox`, `FieldRangeSlider` and `FieldDualRangeSlider` import `EuiComboBox`, `EuiRange` or `EuiDualRange` the first time one renders, and render once it has loaded. Importing `EuiChangesetForm` no longer brings the combo box (ember-power-select, vertical-collection) and the ranges into your bundle: a login form with three text fields loads 619KB of ember-eui in a production Vite/Embroider build instead of 939KB (181KB gzip instead of 258KB). The fields also import each EUI component directly instead of through the `@ember-eui/core/components` index, so a dev server without tree-shaking loads only those. The imports register test waiters, so `settled()` and the test helpers wait for them. `@ember/test-waiters` is now a dependency.
