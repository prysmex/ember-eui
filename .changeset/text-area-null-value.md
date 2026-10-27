---
'@ember-eui/core': patch
---

`EuiTextArea`: `@value` accepts `null`, e.g. an attribute that is `string | null`. A `null` value already rendered an empty textarea, as `undefined` does, but the type didn't allow it, so Glint rejected it.
