---
"@ember-eui/core": patch
---

EuiComboBox: the input no longer shifts right inside EuiText (or anywhere
lists are styled), and ember-power-select's screen reader announcement
("3 results") no longer shows under the options. Both fixes are in
`@ember-eui/core/styles/ember-eui.css`.
