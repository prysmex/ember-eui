# Upstream gaps found by the docs audit (2026-10-13)

The docs were aligned with the examples in EUI v123.1.0's own docs (elastic/eui
`packages/website/docs/components`). Where an upstream example needed something
Ember EUI doesn't support, the example was left out or adapted, never faked.
This is the list of those gaps. Effort: S/M/L.

## Display, editors, utilities

| Component | Missing prop/feature |
| --- | --- |
| EuiTourStep | no `useEuiTour` hook (`EuiTour` yields the same state and actions; deliberately not added) |
| EuiMarkdownEditor | `toolbarProps`; `getDefaultEuiMarkdownPlugins` exclude only `tooltip` (button stays); no link validator |
| EuiI18n | multi-token lookup, component-valued interpolation; no `EuiContext` |
| Missing components | `EuiFocusTrap`, `EuiWindowEvent` |
| Illustrations | `@elastic/eui-illustrations` not installed: no catalog/gallery |
| Not documented | utilities pages: error-boundary, html-id-generator, inner-text, pretty-duration, provider, container-queries, css-utility-classes, color-palettes, scroll |

## Forms

| Component | Missing prop/feature |
| --- | --- |
| EuiSearchBar | `box` prepend/append/onClick/onFocus/onBlur; filter option `view` as markup |
| EuiSuperDatePicker | not in the audit, still missing: `isDisabled={ display }`, the pretty duration display (`showPrettyDuration`), `quickSelectButtonProps`, the auto refresh append button, `updateButtonProps` tooltip/`responsive` (see super-date-picker-handoff.md) |
| EuiDatePicker | no calendar picker in core (flatpickr/pikaday packages) |

## Tables and data grid

| Component | Missing prop/feature |
| --- | --- |
| EuiDataGrid | react-window's own options (`estimatedColumnWidth`, `itemKey`, `outerElementType`, `direction`) don't apply to the Ember virtualizer; replace the virtualization with `@renderCustomGridBody` (see gaps-grid-handoff.md) |

## Layout, navigation, templates

| Component | Missing prop/feature | Upstream page | Effort | Notes |
|---|---|---|---|---|
