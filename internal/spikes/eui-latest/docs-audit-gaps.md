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
| EuiComboBox | `inputPopoverProps`: `panelRef` / `popoverRef` (ref props). The list is an ember-basic-dropdown panel, so `repositionOnScroll` is always on and `buffer` / `container` only bound it horizontally (props-popovers-handoff.md) |

## Automated prop audit (2026-10-13)

`node scripts/upstream-prop-audit.mjs . out.json` compares the props upstream
EUI declares for each component with our Args/Blocks (it skips React-only
and HTML-level props). Rebuild `packages/core/declarations` first
(`npx ember-tsc` in packages/core), or it reads stale types.

The first run found 249 candidate props in 74 components. Four waves closed
them (see props-buttons-, props-popovers-, props-forms- and
props-display-handoff.md). The audit now lists 16 components, all decided:

| Component | Prop | Why it stays |
| --- | --- | --- |
| EuiFlexGroup, EuiFlexGrid, EuiFlexItem, EuiForm, EuiModalHeaderTitle, EuiTextColor, EuiTextAlign | `component` | Ember EUI's `@tagName` |
| EuiTextColor, EuiTextAlign | `cloneElement` | no Ember equivalent for applying classes to a child |
| EuiFacetButton | `iconSide`, `iconSize`, `iconType`, `textProps` | our facet button is not built on EuiButtonContent |
| EuiComboBox, EuiDelayHide | `renderOption`, `render` | the default block |
| EuiComment | `timelineAvatar` | `@timelineIcon` and `<:timelineIcon>` |
| EuiDatePickerRange | `startDateControl`, `endDateControl` | the `<:start>` / `<:end>` blocks |
| EuiSelectableTemplateSitewide | `searchable` | upstream forces it on |
| EuiCollapsibleNav | `hideCloseButton`, `pushMinBreakpoint` | no effect upstream either |
| EuiContextMenuPanel | `height` | upstream only sets a meaningless `height` attribute |
| EuiDraggable | `usePortal` | the native drag image needs no portal |

The remaining "missing components" are React plumbing (providers, context,
observers, error boundary), internals (combo box input/list, date tabs,
checkbox control, resizable flyout, help button, toast list item,
validatable control) and the EuiDatePicker decision.

## Decisions

- EuiDatePicker: calendars live in `@ember-eui/flatpickr` and `@ember-eui/pikaday`, not in core.
- EuiBasicTable / EuiDataGrid: tabular copy markers stay as upstream (always on); no Ember-only switch to turn them off.
- EuiErrorBoundary: Glimmer has no render error boundaries. Ember EUI ships its fallback, `EuiErrorMessage` (`@error` / `@errorMessage`), for route `error` templates and caught errors.
- EuiContext (i18n): not added. Every EUI component reads its texts from the global `euiI18n` service, which cannot see the component tree, so a provider could only translate the `<EuiI18n>` instances an app writes. `@i18n={{hash mapping=...}}` scopes one instance; `mappingFunc` is on `@i18n` and on the service. `formatDateTime` and `locale` of upstream's `I18nShape` are not ported.
- Global `eui-*` utility classes: Emotion styles replace them, so EuiEmotionProvider does not inject them. The declarations are listed on the CSS utility classes page; `euiFullHeight`, `euiXScroll`, `euiYScroll` and the other helpers are in `@ember-eui/core/theming`.
- EuiProvider `componentDefaults`: only table pagination defaults exist, via `euiConfig` (`componentDefaults.EuiTablePagination`); other args are set where the component is used.
- EuiFocusTrap, react-focus-on only options (`as`, `lockProps`, `inert`, `whiteList`, `focusLock`, `allowPinchZoom`, `preventScrollOnFocus`, the `data-focus-guard` sentinels): they configure react-focus-on's DOM and have no counterpart in focus-trap.
- `useEuiTour`: not added; `EuiTour` yields the same state and actions.
