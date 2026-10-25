---
'@ember-eui/core': patch
---

Drop `remark-parse` from `@ember-eui/core`'s dependencies. Only the `remark-parse-no-trim` fork is used at runtime; `remark-parse` was left for a type import, and it pulled in `trim@0.0.1` (GHSA-w5p7-h5w8-2hfq, ReDoS) for every consumer. The `Parser` type now comes from the fork, whose types are identical.
