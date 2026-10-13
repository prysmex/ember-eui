---
title: Selectable
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Selectable"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiSelectable` is a list of options to pick one or several from, with an
optional search field. It is the building block of many pickers: in an
`EuiPopover` it makes a filter menu, in a panel a "choose fields" list.

```hbs
<EuiSelectable
  @options={{this.options}}
  @onChange={{this.setOptions}}
  @searchable={{true}}
  aria-label="Fruits"
/>
```

```js
options = [{ label: 'Apple', checked: 'on' }, { label: 'Banana' }];
setOptions = (options) => (this.options = options);
```

Options are `{ label, checked, disabled, isGroupLabel, prepend, append }`
objects; `checked` is `'on'` (selected), `'off'` (excluded, with
`@allowExclusions`) or nothing. `@onChange` gets **all** options back with
the change applied, so keep them in a tracked property.

- `@singleSelection={{true}}` allows one option at most;
  `@singleSelection="always"` exactly one.
- `@searchable` adds a search field; the keyboard (up, down, Enter) works
  from it.
- `@isLoading`, `@errorMessage`, `@emptyMessage` and `@noMatchesMessage`
  replace the list with a message.
- `@searchProps.value` + `onChange` control the search; `@optionMatcher`
  changes how options match it.
- Options can have `toolTipContent`, `hasAriaDisabled`, `textWrap` and
  `truncationProps`; `@listProps.isVirtualized={{false}}` lets rows fit
  their content.
- `@onChange` gets the options, the event and the changed option; options
  are never mutated, so frozen arrays work.
- The `<:option>` block renders labels (it yields the option and the
  search); `<:optionPrepend>` / `<:optionAppend>` add content around them.
- With a block, it yields `{ list, search }` to lay them out yourself.
- As upstream, `aria-label` / `aria-describedby` name the search and the
  listbox, not the root: `aria-label` labels both; `aria-describedby`
  describes the search (with the message) and the list (with the
  keyboard instructions). `@searchProps` / `@listProps` keys of the same
  names win. Without any, the search and a searchable list are labelled
  "Filter options".

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiSelectable

A list of options to pick one or several from, optionally with a search
field. It is the building block of pickers: put it in a popover for a
filter menu, or in a panel for a "choose fields" list. Options are
`{ label, checked }` objects; `@onChange` gets them all back with the
change applied.

As upstream, `aria-label` / `aria-describedby` attributes name the
search and the listbox, not the root (`searchProps` / `listProps` keys of
the same names win).

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@options` (required) | `EuiSelectableOption[]` |  | The options: `{ label, checked, disabled, isGroupLabel, prepend, append }`. |
| `@onChange` |  |  | Called with all options after one is checked or unchecked (new objects; the given ones are not mutated), the click or keyboard event, and the changed option. |
| `@onActiveOptionChange` | `(option: EuiSelectableOption \| null) => void` |  | Called with the current option (or `null`) whenever it changes through the keyboard, focus or searching. |
| `@searchable` | `boolean` |  | Adds a search field that filters the options. |
| `@searchProps` |  |  | Options of the search field: `{ placeholder, compressed, isLoading, isClearable, value, defaultValue, onChange(searchValue, matchingOptions), onSearch (same as onChange, not called on render), onKeyDown, onKeyUpCapture, onInput, onClick, onFocus, onBlur, inputRef, className, prepend, append, 'data-test-subj', fullWidth, incremental, disabled, isDisabled, readOnly, isInvalid, id }`; other keys become attributes of the `<input>` (upstream's rest spread). With `value` the search is controlled: update it from `onChange`. `onChange` is also called once after the first render. |
| `@optionMatcher` | `EuiSelectableOptionMatcher` | the label (or `searchableLabel`) containing the search, ignoring case | Decides whether an option matches the search: `({ option, searchValue, normalizedSearchValue }) => boolean`. |
| `@selectableScreenReaderText` | `string` |  | Screen reader text read before the keyboard instructions of the search field. |
| `@singleSelection` | `boolean \| 'always'` | `false` | `true`: one option at most; `'always'`: exactly one (clicking the checked option keeps it); `false`: several, shown with check boxes and `aria-checked`. |
| `@allowExclusions` | `boolean` |  | Pressing a checked option excludes it (`checked: 'off'`, a cross). |
| `@isLoading` | `boolean` |  | Shows a loading message instead of the list. |
| `@isPreFiltered` | `boolean \| { highlightSearch?: boolean }` |  | The options are already filtered (e.g. by a server): the search does not filter. `{ highlightSearch: false }` also turns off highlighting the search in the labels. |
| `@height` | `number \| 'full'` |  | Height of the list in px, or `'full'` to fill the container. |
| `@listProps` |  |  | Options of the list: `{ bordered, paddingSize, showIcons, rowHeight, onFocusBadge, isVirtualized, textWrap, truncationProps, css, 'aria-label', 'aria-describedby' }` (`onFocusBadge` defaults to `false`, upstream). See `EuiSelectableList`. |
| `@loadingMessage` | `string` | "Loading options" | Message while `@isLoading`. |
| `@noMatchesMessage` | `string` |  | Message when the search matches nothing. |
| `@emptyMessage` | `string` | "No options available" | Message when there are no options. |
| `@errorMessage` | `string \| null` |  | Error message shown instead of the list (before any other message) when not `null` / `undefined`. |
| `@css` | `EuiCss` |  | Styles composed last into the root's class (upstream's `css` prop), e.g. from a template built on EuiSelectable. |

| Block | Description |
| --- | --- |
| default block | Lays out the parts yourself: yields `{ list, search }` components, e.g. `as \|parts\|` → `<parts.search />` … `<parts.list />`. Without it, the search (if any) comes above the list. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiSelectableList

The list of an `EuiSelectable`: renders the options, checks and
unchecks them on click, and scrolls the keyboard's current option into
view. Usually rendered for you by `EuiSelectable`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@options` (required) | `EuiSelectableOption[]` |  | All options; `@onOptionClick` gets them with the change applied. |
| `@visibleOptions` | `EuiSelectableOption[]` | all | The options to show (e.g. those matching a search). |
| `@searchValue` | `string` |  | The search, highlighted in the labels. |
| `@activeOptionIndex` | `number` |  | Index (in the visible options) of the keyboard's current option. |
| `@setActiveOptionIndex` | `(index: number) => void` |  | Called when an option is pressed, to make it the current one. |
| `@onOptionClick` (required) |  |  | Called with all options after one is checked or unchecked, the click or keyboard event, and the changed option. |
| `@singleSelection` | `boolean \| 'always'` |  | `true`: one option at most; `'always'`: exactly one (it cannot be unchecked); `false`: several, with check box indicators. Left undefined, options look single (upstream EuiSelectableList) while the listbox stays multiselectable; `EuiSelectable` passes `false`. |
| `@allowExclusions` | `boolean` |  | Pressing a checked option excludes it (`checked: 'off'`) first. |
| `@showIcons` | `boolean` | `true` | Shows the selection indicator column. |
| `@onFocusBadge` |  | `false` (upstream) | Shows the "return key" badge on the current option: `true`, `false` or `{ text, iconSide }`. |
| `@bordered` | `boolean` |  | Adds a border around the list. |
| `@paddingSize` | `'none' \| 's'` | `'none'` | `'s'` pads the list. |
| `@rowHeight` | `number` | `32` | Height of each option in px. Has no effect when `@isVirtualized` is `false`. |
| `@isVirtualized` | `boolean` |  | `true` (default): every row is `@rowHeight` tall and the list height is computed from it (upstream renders with react-window). `false`: rows fit their content and the list is only as tall as `@height` (when a number), so text can wrap. |
| `@textWrap` | `'truncate' \| 'wrap'` |  | `'truncate'` (default) or `'wrap'` the labels; an option's own `textWrap` wins. Wrapping only works with `@isVirtualized={{false}}`. |
| `@truncationProps` | `EuiSelectableTruncationProps` |  | EuiTextTruncate arguments (`truncation`, `truncationOffset`, …) for truncated labels; an option's own `truncationProps` are merged over them. While searching, the match is kept visible instead. |
| `@isPreFiltered` | `boolean \| { highlightSearch?: boolean }` |  | Every option matches the search (filtered elsewhere); `{ highlightSearch: false }` also turns off the search highlighting. |
| `@css` | `EuiCss` |  | Styles composed last into the root's class (upstream `css`). |
| `@height` | `number \| 'full'` |  | Height of the list in px, or `'full'` to fill its container. By default it shows up to 7 options (and half of the next one). |
| `@listId` | `string` |  | `id` of the `<ul role="listbox">`. |
| `@makeOptionId` | `(index: number) => string` |  | Id of each option's `<li>`, for `aria-activedescendant`. |
| `@searchable` | `boolean` |  | The list is driven from a search field (which keeps focus). |
| `@ariaLabel` | `string` |  | `aria-label` of the listbox. |
| `@ariaDescribedby` | `string` |  | `aria-describedby` of the listbox. |

| Block | Description |
| --- | --- |
| `<:option>` | Renders an option's label yourself; yields the option and the search. |
| `<:optionPrepend>` | Content before each label (e.g. an icon); yields the option. |
| `<:optionAppend>` | Content after each label (e.g. a badge); yields the option. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiSelectableListItem

One option of an `EuiSelectable` list: a selection indicator, the label,
and optional prepend / append content. Usually rendered for you by
`EuiSelectable`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@isFocused` | `boolean` |  | Highlights it as the keyboard's current option. |
| `@disabled` | `boolean` |  | Disables the option. |
| `@hasAriaDisabled` | `boolean` |  | With `@disabled`: keeps focus styles, the focus badge and the tooltip (upstream `hasAriaDisabled`); the option still cannot be selected. |
| `@textWrap` | `'truncate' \| 'wrap'` |  | `'truncate'` (default, CSS ellipsis) or `'wrap'` the label (upstream `textWrap`; EuiSelectable only wraps when not virtualized). |
| `@toolTipContent` | `string` |  | Tooltip text, shown on hover and while `@isFocused` (upstream). |
| `@toolTipProps` | `EuiSelectableToolTipProps` |  | EuiToolTip arguments of that tooltip; `position` defaults to `'left'`. |
| `@checked` | `boolean \| 'on' \| 'off' \| 'mixed'` |  | `'on'` (checked), `'off'` (excluded), `'mixed'` (checked for some) or nothing. `true` is treated as `'on'`. |
| `@showIcons` | `boolean` | `true` | Shows the selection indicator: a check box for multiple selection, else a check mark / cross / dash. |
| `@prepend` | `string` |  | Text before the label. Use the `<:prepend>` block for markup. |
| `@append` | `string` |  | Text after the label. Use the `<:append>` block for markup. |
| `@allowExclusions` | `boolean` |  | Tells screen readers that Enter excludes the option. |
| `@singleSelection` | `boolean \| 'always'` |  | `false` for an option of a multiple selection list: a check box indicator and `aria-checked`. Otherwise (the default, as upstream) a single selection option: an icon indicator, the selected background and `aria-selected`. |
| `@searchable` | `boolean` |  | The list is driven from a search field: adds the "press Enter" instructions for screen readers. |
| `@onFocusBadge` |  | `false` (upstream) | Shows a "return key" badge on the focused option, to hint that Enter selects it: `true`, `false`, or `{ text, iconSide }` for a badge with text (e.g. "Go to"). |
| `@role` | `string` | `'option'` | `role` of the `<li>`. |
| `@isInteractive` | `boolean` |  | Hover styles and pointer cursor (set when the list handles clicks). |
| `@title` | `string` |  | Text of the label's `title` (on the text, not the option). |
| `@hasPrepend` | `boolean` |  | Renders the prepend wrapper (for blocks that may be empty). |
| `@hasAppend` | `boolean` |  | Renders the append wrapper (for blocks that may be empty). |

| Block | Description |
| --- | --- |
| default block | The label. |
| `<:prepend>` | Content before the label, e.g. an icon or avatar. |
| `<:append>` | Content after the label, e.g. a count badge. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<li>`.

### EuiSelectableSearch

The search field of an `EuiSelectable`: filters the options as you type.
Usually rendered for you by `EuiSelectable` with `@searchable={{true}}`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@options` (required) | `EuiSelectableOption[]` |  | The options to filter. |
| `@onChange` (required) |  |  | Called with the matching options and the search. |
| `@placeholder` | `string` |  | Placeholder of the field. |
| `@value` | `string` |  | The search (controlled, upstream: managed by the parent `EuiSelectable`). Changing it updates the field. |
| `@defaultValue` | `string` |  | Initial search, when `@value` is not given. |
| `@isPreFiltered` | `unknown` |  | Every option matches (they were already filtered, e.g. by a server). |
| `@optionMatcher` | `EuiSelectableOptionMatcher` |  | Decides which options match the search. |
| `@listId` | `string` |  | `id` of the list, to link the field to it for screen readers. |
| `@compressed` | `boolean` | `true` (upstream) | Smaller field. |
| `@isLoading` | `boolean` |  | Shows a spinner. |
| `@isClearable` | `boolean` | `true` | Shows the clear button when there is text. |
| `@inputRef` | `(input: HTMLInputElement) => void` |  | Called with the `<input>` once rendered (upstream `inputRef`). |
| `@onKeyDown` | `(event: KeyboardEvent) => void` |  | Called on `keydown` in the field (before EuiSelectable handles it). |
| `@onClick` | `(event: MouseEvent) => void` |  | Called on `click` in the field. |
| `@onFocus` | `(event: FocusEvent) => void` |  | Called when the field gets focus. |
| `@onBlur` | `(event: FocusEvent) => void` |  | Called when the field loses focus. |
| `@dataTestSubj` | `string` |  | `data-test-subj` of the field. |
| `@className` | `string` |  | Extra class name(s) of the field (upstream `className`). |
| `@prepend` | `string \| ComponentLike` |  | Content before the field (upstream `prepend`): a string is shown as a label, a component is rendered as is. |
| `@append` | `string \| ComponentLike` |  | Content after the field (upstream `append`): a string is shown as a label, a component is rendered as is. |
| `@onKeyUpCapture` | `(event: KeyboardEvent) => void` |  | Called on `keyup` in the field, in the capture phase. |
| `@onInput` | `(event: Event) => void` |  | Called on `input` in the field, before the search is updated. |
| `@fullWidth` | `boolean` | `true` (upstream) | Full width of its container. |
| `@incremental` | `boolean` | `true` (upstream) | Searches on every keystroke. |
| `@disabled` | `boolean` |  | Disables the field. |
| `@isDisabled` | `boolean` |  | Disables the field (same as `@disabled`). |
| `@readOnly` | `boolean` |  | Read-only field. |
| `@isInvalid` | `boolean` |  | Invalid look. |
| `@id` | `string` |  | `id` of the `<input>`. |
| `@rest` | `Record<string, unknown>` |  | Other props of `searchProps` (upstream spreads them onto the field): the ones that are not arguments are set as attributes of the `<input>` (e.g. `name`, `maxlength`); functions are skipped. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<input>`.

### EuiSelectableMessage

A message shown by `EuiSelectable` instead of its list: while loading,
when nothing matches the search, or when there are no options.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@bordered` | `boolean` |  | Adds the list's border, for bordered lists. |

| Block | Description |
| --- | --- |
| default block | The message. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
