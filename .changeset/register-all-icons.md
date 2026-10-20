---
'@ember-eui/core': patch
---

Apps that prefer every icon bundled up front can opt out of lazy icons: call `registerAllIcons()` from `@ember-eui/core/utils/register-all-icons` once (e.g. in `app/app.js`) and no icon loads when it first renders, with no placeholder, fade-in or request. It adds all ~700 icons to the bundle that imports it (~330KB minified, ~130KB gzip). Without it, icons stay lazy.
