---
'@ember-eui/core': patch
---

`EuiToolTip`: `@content` accepts a `SafeString` as well as a string, e.g. `@content={{htmlSafe (t "some.key")}}`. The tooltip already rendered it as markup, but the type only allowed a string, so Glint rejected it.
