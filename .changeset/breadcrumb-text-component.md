---
'@ember-eui/core': patch
---

A breadcrumb's `text` can be a component as well as a string, e.g. `(hash text=(component MyLabel label="X") href="/x")`. EuiBreadcrumbs already rendered a curried component there, but `EuiBreadcrumb.text` was typed `string`, so Glint rejected it. A breadcrumb with `popoverContent` shows its component `text` in its tooltip too.
