# Upstream gaps found by the docs audit (2026-10-13)

The docs were aligned with the examples in EUI v123.1.0's own docs (elastic/eui
`packages/website/docs/components`). Where an upstream example needed something
Ember EUI doesn't support, the example was left out or adapted, never faked.
This is the list of those gaps. Effort: S/M/L.

## Display, editors, utilities

| Component | Missing prop/feature |
| --- | --- |

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

## From the component audit (not in the docs examples)

Found by checking the migration guide's Known gaps against the code
(2026-10-13); these were never in the docs-example audit above.

| Component | Missing |
| --- | --- |
| EuiPopover | initial focus on the panel, `panelProps`, `focusTrapProps`, `onPositionChange` |
| EuiComboBox | `inputPopoverProps`, `inputRef` |
| Tooltips | pagination arrows, color picker swatches and hue/saturation controls; EuiAvatar uses a native `title` |
| EuiTextArea | icons, loading state, clear button |
| EuiHeaderLogo | `logoType="horizontal"` |
| EuiCollapsibleNavBeta | not ported |

## Decisions

- EuiDatePicker: calendars live in `@ember-eui/flatpickr` and `@ember-eui/pikaday`, not in core.
- EuiBasicTable / EuiDataGrid: tabular copy markers stay as upstream (always on); no Ember-only switch to turn them off.
- EuiErrorBoundary: Glimmer has no render error boundaries. Ember EUI ships its fallback, `EuiErrorMessage` (`@error` / `@errorMessage`), for route `error` templates and caught errors.
- EuiContext (i18n): not added. Every EUI component reads its texts from the global `euiI18n` service, which cannot see the component tree, so a provider could only translate the `<EuiI18n>` instances an app writes. `@i18n={{hash mapping=...}}` scopes one instance; `mappingFunc` is on `@i18n` and on the service. `formatDateTime` and `locale` of upstream's `I18nShape` are not ported.
- Global `eui-*` utility classes: Emotion styles replace them, so EuiEmotionProvider does not inject them. The declarations are listed on the CSS utility classes page; `euiFullHeight`, `euiXScroll`, `euiYScroll` and the other helpers are in `@ember-eui/core/theming`.
- EuiProvider `componentDefaults`: only table pagination defaults exist, via `euiConfig` (`componentDefaults.EuiTablePagination`); other args are set where the component is used.
- EuiFocusTrap, react-focus-on only options (`as`, `lockProps`, `inert`, `whiteList`, `focusLock`, `allowPinchZoom`, `preventScrollOnFocus`, the `data-focus-guard` sentinels): they configure react-focus-on's DOM and have no counterpart in focus-trap.
- `useEuiTour`: not added; `EuiTour` yields the same state and actions.
