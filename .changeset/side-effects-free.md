---
'@ember-eui/validated-form': patch
'@ember-eui/changeset-form': patch
'@ember-eui/flatpickr': patch
'@ember-eui/pikaday': patch
---

The packages declare `"sideEffects": ["*.css", "./tests/**"]` (as `@ember-eui/core` already did), so bundlers may leave out the modules your app imports but does not use. Their modules do nothing when imported beyond registering their templates; a new check over the built packages keeps it that way.
