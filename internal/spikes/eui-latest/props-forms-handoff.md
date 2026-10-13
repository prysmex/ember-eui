# Upstream prop gaps: forms, date pickers, markdown, selectable (handoff)

Branch `eui-wave/props-forms`, commits `a4029ca7..eb087eaa` (5 commits + this
handoff) on top of `fc1a64f8`.

## Checks

- Full core suite: **1996/1996** (main 1974 + 22 new tests).
- Filtered while iterating: forms props 14/14, markdown 43/43, refresh 28/28,
  date 167/167, selectable 75/75, form 151/151, progress 8/8, filter 22/22,
  card 35/35.
- `ember-tsc --noEmit` clean; eslint clean on changed files.
- `node --test scripts/eui-upstream-parity.test.mjs`: 357/357.
- `node scripts/generate-api-docs.mjs`: 13 pages updated (committed).
- `rollup --config`: no package.json change (no new modules).
- No style generator changes (no new styles). Companion suites not run (their
  APIs are unchanged: only args/blocks were added).
- Prop audit rerun: all my candidates closed except those listed as skipped
  below.

## Closed, per component

| Component | Closed | Ember API |
|---|---|---|
| EuiMarkdownFormat | `component`, `grow`, `textAlign` | `@component` (`div`/`span`/`p`, via `(element)`, as EuiText), `@grow`, `@textAlign` |
| EuiMarkdownEditor | `markdownFormatProps` now also takes `grow`, `textAlign`, `component` | forwarded to the preview |
| EuiDatePickerRange | `prepend`, `append`, `iconSide`, `isCustom` | `<:prepend>` / `<:append>` blocks (yield the class; dropped `@inline`, as upstream), `@iconSide` (only for an icon type, not the default calendar, as upstream), `@isCustom` (start/end blocks yield only the delimited input class) |
| EuiDatePopoverButton | `buttonProps` | `@buttonProps`: `className`, `css`, `id`, `aria-label`, `data-test-subj` (replaces the default), `onFocus` (called before `@onFocus`) |
| EuiAutoRefresh | `append`, `isInvalid`, `isLoading` | `<:append>` block (yields class, input id), `@isInvalid`, `@isLoading` |
| EuiAutoRefreshButton | `hasAriaDisabled` | `@hasAriaDisabled`, defaults to `@isDisabled` (upstream) |
| EuiSuperUpdateButton | `element`, `fullWidth`, `hasAriaDisabled`, `iconSide`, `iconSize`, `isSelected` | passed to both EuiButtons; also forwarded from EuiSuperDatePicker `@updateButtonProps` |
| EuiQuickSelectPanel | `component` | `@component` (`div`/`fieldset`), `@tagName` kept as alias |
| EuiFormControlLayout | `wrapperProps` | `@wrapperProps`: `className`, `id`, `aria-label`, `data-test-subj`, `css` (composed into the wrapper class) |
| EuiFormControlLayoutDelimited | `iconsPosition`, `isDropdown`, `inputId`, `wrapperProps` | same names; `@iconsPosition` defaults to `'static'`; `wrapperProps.css` composed in upstream order (before the read-only styles) |
| EuiFieldPassword | `dualToggleProps` | `@dualToggleProps`: `iconType`, `iconSize`, `color`, `display`, `size`, `isDisabled`/`disabled`, `css`, `id`, `className`, `aria-label`, `data-test-subj` override the defaults; `onClick` called after the toggle |
| EuiFilePicker | `files` | `@files` (File[] or null): prompt derived from it; the user's pick wins until `@files` gets a new identity (upstream effect on `files`). No copying of consumer data |
| EuiFormRow | `describedByIds` | `@describedByIds` listed first in the control's `aria-describedby` (kept even if not rendered, as upstream), via `-private/link-form-row-control.ts` |
| EuiCheckableCard | `labelProps` | `@labelProps`: `id`, `title`, `data-test-subj` (upstream overrides `className`/`css` with its own, so those aren't supported) |
| EuiFilterSelectItem | `toolTipContent`, `toolTipProps` | `@toolTipContent` (string), `@toolTipProps`: `position` (default `left`), `delay`, `title`, `offset`, `className`, `css`, `anchorClassName`, `anchorCss`. Not when disabled; shown while `@isFocused` (upstream show/hide on focus) |
| EuiProgress | `labelProps` | `@labelProps`: `className`, `id`, `title`, `data-test-subj`, `css` |
| EuiSelectableList | `windowProps` | `@windowProps` (and EuiSelectable `listProps.windowProps`): `height`, `width`, `className` (added, upstream replaces), `initialScrollOffset`, `onScroll({ scrollDirection, scrollOffset, scrollUpdateWasRequested })`. Only while virtualized (upstream). Our list renders every row, so `overscanCount`, `itemSize`, … don't apply |
| EuiSelectableTemplateSitewide | `renderOption` | `<:option as |option searchValue|>` block replaces the label/meta content; icon and avatar stay (upstream formats them into prepend/append) |

## Skipped, and why

- **EuiMarkdownEditor**: all audit candidates (`autoExpandPreview`, `dropHandlers`,
  `editorId`, `errors`, `height`, `initialViewMode`, `markdownFormatProps`,
  `maxHeight`, `onParse`, `parsingPluginList`, `processingPluginList`,
  `readOnly`, `showFooter`, `toolbarProps`, `uiPlugins`) **already exist**. The
  audit is a false positive: `scripts/upstream-prop-audit.mjs` registers the
  first variable statement typed with a signature in a file under the barrel
  name, and `eui-markdown-editor.gts` declares `getCursorNodeModifier`
  (a modifier with `{ Positional, Named }`) before the class. Fix for the
  coordinator: in the variable branch only use `nameByFile[f]` when the file
  default-exports that variable. I added tests for the ones without coverage
  (`showFooter`, `toolbarProps`, `onParse`, `parsingPluginList`,
  `processingPluginList`, `markdownFormatProps`, `autoExpandPreview`).
- **EuiDatePickerRange** `startDateControl` / `endDateControl`: covered by the
  `<:start>` / `<:end>` blocks.
- **EuiAutoRefreshButton / EuiSuperUpdateButton** `contentProps`, `textProps`:
  not on EuiButton/EuiButtonEmpty on main (the button agent is adding them).
  Pass them through once they land.
- **EuiSelectableTemplateSitewide** `searchable`: upstream forces `searchable`
  after the rest props, so it can't be changed. Not applicable.
- **EuiDatePickerRange** upstream's `wrapperProps['data-test-subj'] =
  `${dataTestSubj}-range-wrapper``: our `data-test-subj` goes through
  `...attributes`, which the component can't read. Not ported.
- **wrapperProps.style / labelProps.style / anchorProps.style** (React style
  objects): not supported; use `css`.

## Behaviour changes

- `EuiAutoRefreshButton @isDisabled` now renders `aria-disabled="true"`
  (focusable, tooltip still shows) instead of native `disabled`, as upstream
  (`hasAriaDisabled={isDisabled}`). The old handoff noted this as a limitation
  because EuiButtonEmpty lacked `hasAriaDisabled`. Test changed in
  `eui-refresh-flyout-test.gts` ("shorthand, size, color and disabled"):
  old `isDisabled()` + `hasAttribute('disabled')`, new
  `hasAttribute('aria-disabled', 'true')` + `doesNotHaveAttribute('disabled')`.
  `@hasAriaDisabled={{false}}` restores the native attribute.
- `EuiDatePopoverButton buttonProps.className` is added to the classes; upstream
  spreads it after `className`, which would replace the state classes.
- No other existing test changed.

## Docs

- New demos: `editors/markdown-editor/base-editor-demo/d13-format-alignment-and-tag.md`,
  `forms/date-picker-range/demo/d05-prepend-append-icon.md`,
  `forms/form-controls/file-picker/demo/d03-keeping-files.md`. Upstream's docs
  have no examples for the other props.
- API tables regenerated.
- docs-audit-gaps.md not edited (coordinator's job).

## Files

- src: `eui-markdown-format.gts`, `eui-markdown-editor.gts`,
  `eui-date-picker-range.gts`, `eui-auto-refresh.gts`,
  `eui-auto-refresh-button.gts`, `eui-super-date-picker.gts`,
  `eui-super-date-picker/{eui-super-update-button,date-popover/eui-date-popover-button,eui-quick-select-popover/eui-quick-select-panel}.gts`,
  `eui-form-control-layout.gts`, `eui-form-control-layout-delimited.gts`,
  `eui-field-password.gts`, `eui-file-picker.gts`, `eui-form-row.gts`,
  `-private/link-form-row-control.ts`, `eui-checkable-card.gts`,
  `eui-filter-select-item.gts`, `eui-progress.gts`, `eui-selectable-list.gts`,
  `eui-selectable.gts`, `eui-selectable-template-sitewide.gts`.
- tests: new `eui-props-forms-test.gts` (14), plus additions to
  `eui-markdown-editor-test.gts` (5), `eui-markdown-format-test.gts` (1),
  `eui-refresh-flyout-test.gts` (2 new, 1 changed).
