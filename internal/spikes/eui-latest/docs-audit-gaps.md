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
| EuiComboBox | `inputPopoverProps` keys that only exist on EuiPopover: `closeOnScroll` (upstream's combo box sets it by default), `repositionOnScroll`, `buffer`, `offset`, `container`, `panelRef`, `popoverRef`, `onPanelResize`, `isLoading`, and attributes for the popover root; the list is an ember-basic-dropdown panel |

## Automated prop audit (2026-10-13)

`node scripts/upstream-prop-audit.mjs . out.json` compares the props upstream
EUI declares for each component with our Args/Blocks (it skips React-only
and HTML-level props). 74 components have candidate gaps (249 props). This is
a candidate list: some entries are covered differently in Ember (blocks
instead of render props, `...attributes`), so check each before porting.

| Group | Components | Props |
| --- | --- | --- |
| Button-like components that inherit EuiButton / EuiButtonEmpty props upstream | EuiSkipLink, EuiHeaderSectionItemButton, EuiPaginationButton, EuiDataGridToolbarControl, EuiFacetButton, EuiSuperUpdateButton, EuiFilterButton, EuiAutoRefreshButton, EuiFormControlButton, EuiHeaderLink, EuiButton, EuiButtonEmpty | `contentProps`, `textProps`, `iconSide`, `iconSize`, `iconType`, `isLoading`, `isSelected`, `isDisabled`, `hasAriaDisabled`, `color`, `size`, `flush`, `fill`, `fullWidth`, `minWidth`, `element` (varies per component) |
| Popover-based props | EuiTourStep (all EuiPopover props), EuiIconTip / EuiToolTip / EuiBetaBadge `anchorProps`, EuiIconTip `offset` / `repositionOnScroll` / `disableScreenReaderOutput`, EuiColorPalettePicker `popoverProps` / `isOpen` / `itemClassName`, EuiHeaderLinks `popoverProps` / `popoverButtonProps`, EuiRange / EuiDualRange `inputPopoverProps`, EuiColorPicker `popoverZIndex`, EuiCopy `tooltipProps`, EuiKeyPadMenuItem `betaBadgeTooltipProps` | as listed |
| Flyout-based props | EuiCollapsibleNav (EuiFlyout's props, incl. session and menu props), EuiFlyout `includeFixedHeadersInFocusTrap`, `includeSelectorInFocusTrap`, `pushAnimation` | as listed |
| Element/tag choice | EuiFlexGroup, EuiFlexGrid, EuiFlexItem, EuiForm, EuiMarkdownFormat, EuiModalHeaderTitle, EuiQuickSelectPanel, EuiTextColor / EuiTextAlign (`component`, `cloneElement`), EuiPanel / EuiCollapsibleNavGroup (`element`) | `component` / `element` |
| Data-driven alternatives to blocks | EuiSteps / EuiStepsHorizontal `steps`, EuiGlobalToastList `toasts`, EuiContextMenuPanel `items` / `height`, EuiToast `text`, EuiKeyPadMenu `checkable`, EuiFilePicker `files`, EuiSkeletonLoading `loadingContent` / `loadedContent` / announce props | as listed |
| Component-specific | EuiMarkdownEditor (`autoExpandPreview`, `dropHandlers`, `editorId`, `errors`, `height`, `maxHeight`, `initialViewMode`, `onParse`, `parsingPluginList`, `processingPluginList`, `readOnly`, `showFooter`, …), EuiCollapsibleNavGroup (`arrowProps`, `borders`, `buttonProps`, `forceState`, `isLoading`, …), EuiDatePickerRange (`startDateControl`, `endDateControl`, `isCustom`, `prepend`, `append`, `iconSide`), EuiFormControlLayoutDelimited (`iconsPosition`, `isDropdown`, `wrapperProps`), EuiAutoRefresh (`append`, `isInvalid`, `isLoading`), EuiListGroupItem (`icon` node, `iconProps`), EuiComment (`timelineAvatar`, `verticalAlign`), EuiExpression (`descriptionProps`, `valueProps`), EuiFilterSelectItem (tooltips), EuiPinnableListGroup / EuiListGroup (`ariaLabelledby`, `showToolTips`), EuiSelectableTemplateSitewide (`searchable`), EuiSideNav (`isOpenOnMobile`, `truncate`), EuiBadgeGroup `gutterSize`, EuiCallOut `dismissButtonProps`, EuiCheckableCard `labelProps`, EuiComboBoxPill `onClickAriaLabel`, EuiContextMenu `onPanelChange`, EuiContextMenuItem `external`, EuiDatePopoverButton `buttonProps`, EuiDraggable `usePortal`, EuiEmptyPrompt `hasShadow`, EuiFlyoutMenu `iconType`, EuiFieldPassword `dualToggleProps`, EuiFormControlLayout `wrapperProps`, EuiFormRow `describedByIds`, EuiConfirmModal `outsideClickCloses`, EuiProgress `labelProps`, EuiSelectableList `windowProps` | as listed |
| Probably covered by blocks (verify) | EuiComboBox / EuiSelectableTemplateSitewide `renderOption`, EuiDelayHide `render` | - |

## Decisions

- EuiDatePicker: calendars live in `@ember-eui/flatpickr` and `@ember-eui/pikaday`, not in core.
- EuiBasicTable / EuiDataGrid: tabular copy markers stay as upstream (always on); no Ember-only switch to turn them off.
- EuiErrorBoundary: Glimmer has no render error boundaries. Ember EUI ships its fallback, `EuiErrorMessage` (`@error` / `@errorMessage`), for route `error` templates and caught errors.
- EuiContext (i18n): not added. Every EUI component reads its texts from the global `euiI18n` service, which cannot see the component tree, so a provider could only translate the `<EuiI18n>` instances an app writes. `@i18n={{hash mapping=...}}` scopes one instance; `mappingFunc` is on `@i18n` and on the service. `formatDateTime` and `locale` of upstream's `I18nShape` are not ported.
- Global `eui-*` utility classes: Emotion styles replace them, so EuiEmotionProvider does not inject them. The declarations are listed on the CSS utility classes page; `euiFullHeight`, `euiXScroll`, `euiYScroll` and the other helpers are in `@ember-eui/core/theming`.
- EuiProvider `componentDefaults`: only table pagination defaults exist, via `euiConfig` (`componentDefaults.EuiTablePagination`); other args are set where the component is used.
- EuiFocusTrap, react-focus-on only options (`as`, `lockProps`, `inert`, `whiteList`, `focusLock`, `allowPinchZoom`, `preventScrollOnFocus`, the `data-focus-guard` sentinels): they configure react-focus-on's DOM and have no counterpart in focus-trap.
- `useEuiTour`: not added; `EuiTour` yields the same state and actions.
