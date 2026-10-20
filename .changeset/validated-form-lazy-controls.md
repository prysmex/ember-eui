---
'@ember-eui/validated-form': patch
---

The heavy fields load their control on demand: `FieldComboBox`, `FieldRangeSlider`, `FieldDualRangeSlider` and `FieldMarkdownEditor` import `EuiComboBox`, `EuiRange`, `EuiDualRange` or `EuiMarkdownEditor` the first time one renders, and render once it has loaded (later renders have it at once). Importing `ValidatedForm` no longer brings the combo box (ember-power-select, vertical-collection), the ranges and the markdown editor (parser, highlighter, emoji) into your bundle: a login form with three text fields loads 646KB of ember-eui in a production Vite/Embroider build instead of 1285KB (189KB gzip instead of 367KB). `FieldMarkdownEditor` with `@editorComponent` never loads `EuiMarkdownEditor`. The imports register test waiters, so `settled()` and the test helpers wait for them. `@ember/test-waiters` is now a dependency.
