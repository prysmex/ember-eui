---
'@ember-eui/core': patch
---

`EuiTab`: `@id` accepts a number as well as a string, e.g. `@id={{index}}` in an `{{#each}}`. It was already rendered as the `id` attribute, but the type only allowed a string, so Glint rejected a number. The tab objects of `EuiTabbedContent` and `EuiPageHeader` keep a string `id`.
