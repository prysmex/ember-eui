---
'@ember-eui/core': patch
---

Icons can be registered up front: every EUI icon type now has a module, `@ember-eui/core/icons/<type>`, whose default export is its component, and `registerIcons({ cross, search })` from `@ember-eui/core/utils/preload-icons` makes those icons render with the first paint, without the loading placeholder, the fade-in or a request (see the icons' Lazy loading docs). An icon that has loaded or was registered still renders at once, without fading in, everywhere afterwards. The map of icon loaders (one per type, ~700) is now imported with the first icon that has to load instead of with `EuiIcon`, which takes ~46KB (minified; 14KB gzip) off every app that renders an icon: an app rendering one `EuiIcon` loads 160KB of ember-eui up front instead of 206KB. In return, the first icon an app loads (rather than registers) takes one more request.
