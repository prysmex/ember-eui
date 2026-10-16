---
'@ember-eui/core': patch
---

`EuiComboBox`: with `@singleSelection={{hash asPlainText=true}}` and a block, the selection is rendered with the block again (as in 14.x, on ember-power-select) while nothing is typed, e.g. enum values shown as an avatar and a translated label instead of the raw value. The block receives the option, then the select. Typing shows the input's text again, so search works as before. The input keeps the option's label as its value, which screen readers announce. Without a block, the input shows the label text, as upstream EUI does.
