# Props: button family and tag choice (eui-wave/props-buttons)

## Closed

Shared: `@contentProps` / `@textProps` are hashes with `class` / `className`,
`css` (an `EuiCss`, composed into the element's class) and HTML attributes
(strings, numbers, `true`; applied by the private modifier
`-private/eui-apply-props.ts`, which also exports `propsClasses` and
`euiMinInlineSize`). Event handlers and `textProps={false}` are not supported.

| Component | Closed |
| --- | --- |
| EuiButton, EuiButtonEmpty (EuiButtonContent gets `@textProps`) | `contentProps`, `textProps` |
| EuiHeaderLink | `contentProps`, `textProps`, plus forwarding `hasAriaDisabled`, `contentCss`, `css` (they were typed but not forwarded) |
| EuiSkipLink | `color`, `contentProps`, `textProps`, `element`, `fill` (default true), `fullWidth`, `hasAriaDisabled`, `iconSide`, `iconSize`, `iconType`, `isDisabled`, `isLoading`, `isSelected`, `minWidth`, `size` (default s) |
| EuiHeaderSectionItemButton | `color` (default text), `contentProps`, `textProps`, `flush`, `hasAriaDisabled`, `iconSide`, `iconSize`, `iconType`, `isDisabled` (alias of `disabled`), `isLoading`, `isSelected`, `size`, `css` |
| EuiPaginationButton | `color`, `contentProps`, `textProps`, `flush`, `hasAriaDisabled`, `iconSide`, `iconSize`, `iconType`, `isDisabled`, `isLoading`, `isSelected`, `size` |
| EuiDataGridToolbarControl | `color`, `contentProps`, `flush`, `hasAriaDisabled`, `iconSide`, `iconSize`, `isLoading`, `isSelected`, `size`; `textProps` applies to the always-present truncating label span (upstream passes `textProps={false}` down and spreads them on its own span) |
| EuiFacetButton | `contentProps`, `element` (button / a / span), `fullWidth`, `hasAriaDisabled`, `minWidth`, `size` (s / m) |
| EuiFilterButton | `contentProps`, `textProps` (`title` wins over the text title, as upstream's spread), `hasAriaDisabled`, `iconSize`, `isLoading` (spinner replaces the icon, disables) |
| EuiFormControlButton | `contentProps`, `textProps` (on the value / placeholder span), `hasAriaDisabled` |
| EuiModalHeaderTitle | `tagName` (upstream `component`), `size`, `textTransform` |
| EuiPanel | `element="button"` renders a native `<button type="button">` when `@onClick` is set |

## Skipped, with reason

- `component` on EuiFlexGroup / EuiFlexGrid / EuiFlexItem / EuiForm / EuiTextColor / EuiTextAlign:
  already covered by `@tagName`, the repo's name for upstream's `component` (all
  five render the tags upstream's docs use). Not renamed or aliased.
- `cloneElement` on EuiTextColor / EuiTextAlign: applies the classes to the child
  element instead of a wrapper. There is no clean Ember equivalent (a block
  yields content, not an element a component could re-class). Use `@tagName`.
- EuiFacetButton `iconType`, `iconSide`, `iconSize`, `textProps`: facet does not use EuiButtonContent
  (its icon is the `icon` block, its text span is its own), so there is nothing to forward to.
  `color` and `fill` are not facet props upstream either. `isSelected` / `isLoading` already existed.
- EuiFilterButton `color`, `isSelected`, `iconType`, `iconSide`, `isDisabled` already existed.

## Decisions for the coordinator

- Names: modal title uses `@tagName`, not `@component`, to match the repo.
- EuiPanel: default with `@onClick` stays `<div role="button">` (upstream's default is a
  native `<button>`); `@element="button"` opts in. A default flip would change existing markup.
- EuiModalHeaderTitle: default stays a `<div>` wrapping the consumer's heading (upstream renders
  an `h1` itself); set `@tagName="h1"` to get upstream's DOM.
- For other agents: EuiSuperUpdateButton / EuiAutoRefreshButton / EuiQuickSelectPanel can now pass
  `@contentProps` / `@textProps` to EuiButton / EuiButtonEmpty. EuiButton `element` already existed.

## Behaviour changes / tests

No existing test assertion changed. New: `tests/integration/components/eui-button-props-test.gts`
(15 tests). Docs: a paragraph and example on the Button page; API tables regenerated.
