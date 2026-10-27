---
'@ember-eui/core': patch
---

`EuiSelect`: `@value` accepts `null`, e.g. a record's id that is `string | null`. It already selected nothing for `null`, as for `undefined` (with `@hasNoInitialSelection`, the empty option), but the type didn't allow it, so Glint rejected it.
