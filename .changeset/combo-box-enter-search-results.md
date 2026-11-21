---
'@ember-eui/core': patch
---

`EuiComboBox` with `@search`: pressing Enter after typing an option's exact label adds that option again. It looked for the label in `@options` instead of the search results, so with a server-side search (an empty or different `@options`) Enter did nothing and the typed text stayed in the input. As in upstream, a partial match still adds nothing until an option is highlighted with the arrow keys.
