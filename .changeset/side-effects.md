---
"@ember-eui/core": patch
---

Declare `sideEffects` so apps bundle only the components they import:
importing one component from `@ember-eui/core/components` no longer pulls
in the whole library (e.g. EuiButton alone: ~43 KB of core code instead of
~680 KB, minified, before the lazily loaded icons).
