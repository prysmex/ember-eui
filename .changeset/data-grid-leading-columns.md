---
'@ember-eui/core': minor
---

`EuiDataGrid`:

- New `virtualizationOptions.leadingColumnCount`: the first N columns are always rendered, besides the column window, so columns kept in view with `position: sticky` (frozen columns) never unmount while the others stay virtualized.
- `setCellProps` applies a cell's props without a tracked write after render, and drops the props of a column the cell no longer shows. Scrolling a large grid re-renders less.
- The package's `app-js` no longer lists the four modules that are not components. They re-exported a default that does not exist, which broke a host built with `staticInvokables: false`.
