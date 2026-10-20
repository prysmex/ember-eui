---
'@ember-eui/core': patch
---

EUI's style factories ship as one module per upstream style file instead of a single ~660KB module. Each component imports only the styles it renders, so an app bundles only the styles of the components it uses, and a lazily loaded component (a route-split page, a dynamic `import()`) brings its own styles with it instead of adding them to the app's entry. In a Vite/Embroider app, an entry rendering `EuiButton` with a lazily loaded `EuiDataGrid` route loads 373KB of ember-eui before running instead of 494KB (minified; 121KB gzip instead of 147KB). `@ember-eui/core/utils/eui/styles.generated` still exports every factory.
