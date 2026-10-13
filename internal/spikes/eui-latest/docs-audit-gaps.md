# Upstream gaps found by the docs audit (2026-10-13)

The docs were aligned with the examples in EUI v123.1.0's own docs (elastic/eui
`packages/website/docs/components`). Where an upstream example needed something
Ember EUI doesn't support, the example was left out or adapted, never faked.
This is the list of those gaps. Effort: S/M/L.

## Display, editors, utilities

| Component | Missing prop/feature |
| --- | --- |
| EuiTourStep | no `useEuiTour` hook (`EuiTour` yields the same state and actions; deliberately not added) |
| EuiMarkdownEditor | `processingConfig.linkProps`; `markdownFormatProps`; upstream's `remark-parse-no-trim` and intraword-underscore plugin (see gaps-text-handoff.md) |
| EuiI18n | no `EuiContext` (deliberately not added, see the i18n Context example); `@i18n` has no `mappingFunc` |
| Utilities | no `useEuiContainerQuery`, no `euiXScroll`/horizontal overflow helper, no standalone `PrettyDuration`/`usePrettyDuration` (see super-date-picker-handoff.md), no EuiErrorBoundary (Glimmer has no equivalent), no global `eui-*` utility classes or `componentDefaults` |
| EuiFocusTrap | react-focus-on's `as`, `lockProps`, `inert`, `whiteList`, `focusLock`, `allowPinchZoom`, `preventScrollOnFocus` and the `data-focus-guard` sentinels; `EuiProvider componentDefaults` |

## Forms

| Component | Missing prop/feature |
| --- | --- |

## Tables and data grid

| Component | Missing prop/feature |
| --- | --- |
| EuiDataGrid | react-window's own options (`estimatedColumnWidth`, `itemKey`, `outerElementType`, `direction`) don't apply to the Ember virtualizer; replace the virtualization with `@renderCustomGridBody` (see gaps-grid-handoff.md) |

## Layout, navigation, templates

| Component | Missing prop/feature | Upstream page | Effort | Notes |
|---|---|---|---|---|

## Decisions

- EuiDatePicker: calendars live in `@ember-eui/flatpickr` and `@ember-eui/pikaday`, not in core.
- EuiBasicTable / EuiDataGrid: tabular copy markers stay as upstream (always on); no Ember-only switch to turn them off.
- EuiErrorBoundary: Glimmer has no render error boundaries. Ember EUI ships its fallback, `EuiErrorMessage` (`@error` / `@errorMessage`), for route `error` templates and caught errors.
