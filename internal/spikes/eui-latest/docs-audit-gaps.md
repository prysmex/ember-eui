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
| EuiBasicTable | not in the audit, still missing (see tables-gaps-handoff.md): action `name` as rich content (text only); other `<td>` attributes on a column object (only `className`/`data-test-subj`; use `cellProps`); copy-to-clipboard tabular markers; `EuiComponentDefaultsContext` page-size defaults |
| EuiDataGrid | `virtualizationOptions.onScroll` direction/`scrollUpdateWasRequested`; `estimatedRowHeight`; no custom virtualization (react-window); `footerCellProps` style; cell-action `closePopover` (upstream doesn't pass it either) |
| EuiDataGrid (extension) | renderers don't get row depth / expanded state |

## Layout, navigation, templates

| Component | Missing prop/feature | Upstream page | Effort | Notes |
|---|---|---|---|---|

## Decisions

- EuiDatePicker: calendars live in `@ember-eui/flatpickr` and `@ember-eui/pikaday`, not in core.
