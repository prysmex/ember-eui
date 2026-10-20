---
'@ember-eui/core': patch
---

Booting ember-eui no longer loads all of CommonJS lodash. `@elastic/eui-theme-borealis` imports `@elastic/eui-theme-common`'s index, which reaches its vis color store and `import { uniqueId } from 'lodash'`; neither package declares itself side-effect free, so every app got ~70KB of minified lodash next to lodash-es. ember-eui now bundles the parts of the two theme packages it uses, from their ES modules, with their lodash imports going to lodash-es; the unused vis color store is left out. Every entry is about 83KB smaller (minified; ~28KB gzip): an app rendering only `EuiEmotionProvider` loads 126KB of ember-eui instead of 209KB, one rendering `EuiButton` 276KB instead of 359KB. The theme packages stay dependencies for their types; imports of them in your own code are not affected.
