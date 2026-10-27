---
'@ember-eui/core': patch
---

`EuiStat`: `@title` accepts a number as well as a string, e.g. `@title={{this.count}}`. The stat already rendered it (a `0` too), but the type only allowed a string, so Glint rejected a number. Upstream EUI takes any node there.
