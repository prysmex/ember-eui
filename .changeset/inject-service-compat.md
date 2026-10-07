---
'@ember-eui/core': patch
---

Use `inject as service` from `@ember/service` again. The bare `service` export only exists in Ember 4.1+, so on older Ember versions `@service` was `undefined` and loading a component failed with "decorator is not a function".
