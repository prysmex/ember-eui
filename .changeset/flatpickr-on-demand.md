---
'@ember-eui/flatpickr': patch
---

`EuiFlatpickr` imports flatpickr (~40KB minified) when the first picker is set up instead of at module level, so importing the component, or a route that renders it only sometimes, no longer adds flatpickr to your bundle: an app rendering one `EuiFlatpickr` loads 298KB of ember-eui and flatpickr up front instead of 347KB (93KB gzip instead of 107KB), and the picker's code arrives as a separate chunk. Later pickers are created without waiting. The import is a test waiter, so `settled()` waits for it. The component also imports `EuiFieldText` directly instead of through the `@ember-eui/core/components` index.
