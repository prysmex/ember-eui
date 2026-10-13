# Upstream gaps found by the docs audit (2026-10-13)

The docs were aligned with the examples in EUI v123.1.0's own docs (elastic/eui
`packages/website/docs/components`). Where an upstream example needed something
Ember EUI doesn't support, the example was left out or adapted, never faked.
This is the list of those gaps. Effort: S/M/L.

## Display, editors, utilities

| Component | Missing prop/feature |
| --- | --- |
| EuiListGroup | `@listItems`, `@showToolTips`, item tooltip args |
| EuiImage | rich `@caption`, `@width`, `wrapperProps` |
| EuiCommentList | `comments` array, `ariaLabel` |
| EuiCallOut | `actionProps` |
| EuiCard | `betaBadgeProps` color/href/target, `hasBorder`, `@image` as element |
| EuiTimeline | node `children` on items |
| EuiTourStep | `@anchor`, `@zIndex`, `@footerAction` arg; no `useEuiTour` equivalent |
| EuiToolTip | `@repositionOnScroll` |
| EuiTextDiff | `timeout`, `insertComponent`, `deleteComponent` |
| EuiToast / toaster service | `body` is string-only |
| EuiTreeView | `icon` takes icon type strings only |
| EuiMarkdownEditor | `toolbarProps`; `getDefaultEuiMarkdownPlugins` exclude only `tooltip` (button stays); no link validator |
| EuiI18n | multi-token lookup, component-valued interpolation; no `EuiContext` |
| EuiCodeBlock | `lineNumbers.annotations` strings only |
| Missing components | `EuiFocusTrap`, `EuiWindowEvent` |
| Illustrations | `@elastic/eui-illustrations` not installed: no catalog/gallery |
| Not documented | utilities pages: error-boundary, html-id-generator, inner-text, pretty-duration, provider, container-queries, css-utility-classes, color-palettes, scroll |

## Forms

| Component | Missing prop/feature |
| --- | --- |
| EuiCheckbox | `readOnly` (+ styling) |
| EuiColorPalettePicker | per-palette `append`; palettes `euiPaletteRed/Green/SkyBlue/Yellow/Orange` |
| EuiInputPopover | `closeOnScroll` (selectable input popover demo leaves it out) |
| EuiInlineEdit* | `readModeProps` color/iconSide, `inputProps` prepend/readOnly |
| EuiSearchBar | `box` prepend/append/onClick/onFocus/onBlur; filter option `view` as markup |
| EuiSuperDatePicker | not in the audit, still missing: `isDisabled={ display }`, the pretty duration display (`showPrettyDuration`), `quickSelectButtonProps`, the auto refresh append button, `updateButtonProps` tooltip/`responsive` (see super-date-picker-handoff.md) |
| EuiDatePicker | no calendar picker in core (flatpickr/pikaday packages) |

## Tables and data grid

| Component | Missing prop/feature |
| --- | --- |
| EuiBasicTable | column `valign`, `truncateText: { lines }`, `textOnly` in cellProps leaks to DOM, column `name` text-only, sticky actions column |
| EuiInMemoryTable | `useEuiBasicTablePanelProps` (custom panels) |
| EuiTable | `stickyHeader`, `stickyScrollbar` |
| EuiDataGrid | `virtualizationOptions.onScroll` direction/`scrollUpdateWasRequested`; `estimatedRowHeight`; no custom virtualization (react-window); `footerCellProps` style; cell-action `closePopover` (upstream doesn't pass it either) |
| EuiDataGrid (extension) | renderers don't get row depth / expanded state |

## Containers, flyouts and modals

| Component | Missing prop/feature |
| --- | --- |
| EuiModal | `focusTrapProps.returnFocus` |
| EuiSuperSelect | `popoverProps` |
| EuiConfirmModal | `titleProps` |
| EuiAccordion | hover-only extra action (always visible) |

## Layout, navigation, templates

| Component | Missing prop/feature | Upstream page | Effort | Notes |
|---|---|---|---|---|
| EuiCard | `hasBorder` | containers/card.mdx | S | Hard-coded false; "Bordered" example missing. |
| EuiCard | `betaBadgeProps.color` / other badge props | containers/card.mdx | S | Colour derived from `isDisabled` only. |
| EuiCard | `image` as element/node | containers/card.mdx | S/M | `image` is string; d02 notes adaptation. |
| EuiResizableButton | standalone use (`isHorizontal`, `onMouseDown`, `onTouchStart`, `onKeyDown`) | containers/resizable-container.mdx | M | "Custom resize logic" example omitted. |
| EuiResizablePanel | collapsible `mode` options `className`, `data-test-subj` | containers/resizable-container.mdx | S | `Mode` allows only `{position}`. |
| EuiSelectableTemplateSitewide | `searchProps` (`append`, `onKeyUpCapture`, `inputRef`, `className`) | templates/sitewide-search | M | Only `@onSearch`, `@placeholder`; Cmd+K demo needs it. |
| EuiSelectableTemplateSitewide | `listProps`, `popoverProps` | templates/sitewide-search | S | `listProps` hard-coded internally. |
| EuiSelectableTemplateSitewide | `popoverButtonBreakpoints` | templates/sitewide-search | S/M | Block always replaces the field. |
| EuiSelectableTemplateSitewide | `colorModes` | templates/sitewide-search | S | Already noted unsupported in d02. |
| EuiSelectableTemplateSitewide | meta class hook for custom types (`--PINK`) | templates/sitewide-search | S | Unverified. |
