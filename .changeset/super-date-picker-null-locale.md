---
'@ember-eui/core': patch
---

`EuiSuperDatePicker`: `@locale` accepts `null`, e.g. a user's locale that is `string | null | undefined`. A `null` locale already fell back to `'en'`, as `undefined` does, but the type didn't allow it, so Glint rejected it.
