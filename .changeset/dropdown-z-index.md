---
"@ember-eui/core": patch
---

EuiComboBox's options list shows above modals and flyouts again: its
z-index is now set through ember-basic-dropdown's
`--ember-basic-dropdown-content-z-index`, so it no longer depends on which
stylesheet loads last.
