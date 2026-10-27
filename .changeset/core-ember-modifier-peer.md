---
'@ember-eui/core': minor
---

`ember-modifier` is a peer dependency of `@ember-eui/core` (`^4.1.0`) instead of a dependency. As a dependency it installed its own copy next to the app's, so Glint saw core's modifiers (e.g. the one form controls use for validation) as coming from another `ember-modifier` and rejected them ("no Glint brand"). Apps need `ember-modifier` 4.1 or later in their own dependencies; Ember apps usually have it already.
