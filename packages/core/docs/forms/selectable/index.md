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
- `@isLoading`, `@emptyMessage` and `@noMatchesMessage` replace the list
  with a message.
- The `<:option>` block renders labels (it yields the option and the
  search); `<:optionPrepend>` / `<:optionAppend>` add content around them.
- With a block, it yields `{ list, search }` to lay them out yourself.

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

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@options` (required) | `EuiSelectableOption[]` |  | The options: `{ label, checked, disabled, isGroupLabel, prepend, append }`. |
| `@onChange` | `(options: EuiSelectableOption[]) => void` |  | Called with all options after one is checked or unchecked. |
| `@searchable` | `boolean` |  | Adds a search field that filters the options. |
| `@searchProps` |  |  | Options of the search field: `{ placeholder, compressed, defaultValue, onSearch(searchValue, matchingOptions) }`. |
| `@singleSelection` | `boolean \| 'always'` |  | `true`: one option at most; `'always'`: exactly one (clicking the checked option keeps it). |
| `@allowExclusions` | `boolean` |  | Pressing a checked option excludes it (`checked: 'off'`, a cross). |
| `@isLoading` | `boolean` |  | Shows a loading message instead of the list. |
| `@isPreFiltered` | `boolean` |  | The options are already filtered (e.g. by a server): the search does not filter. |
| `@height` | `number \| 'full'` |  | Height of the list in px, or `'full'` to fill the container. |
| `@listProps` |  |  | Options of the list: `{ bordered, showIcons, rowHeight, onFocusBadge }`. |
| `@loadingMessage` | `string` | "Loading options" | Message while `@isLoading`. |
| `@noMatchesMessage` | `string` |  | Message when the search matches nothing. |
| `@emptyMessage` | `string` | "No options available" | Message when there are no options. |

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
| `@onOptionClick` (required) | `(options: EuiSelectableOption[]) => void` |  | Called with all options after one is checked or unchecked. |
| `@singleSelection` | `boolean \| 'always'` |  | `true`: one option at most; `'always'`: exactly one (it cannot be unchecked). |
| `@allowExclusions` | `boolean` |  | Pressing a checked option excludes it (`checked: 'off'`) first. |
| `@showIcons` | `boolean` | `true` | Shows the check mark column. |
| `@onFocusBadge` |  | `true` | Shows the "return key" badge on the current option: `true`, `false` or `{ text, iconSide }`. |
| `@bordered` | `boolean` |  | Adds a border around the list. |
| `@rowHeight` | `number` | `32` | Height of each option in px. |
| `@height` | `number \| 'full'` |  | Height of the list in px, or `'full'` to fill its container. By default it shows up to 7 options (and half of the next one). |
| `@listId` | `string` |  | `id` of the `<ul role="listbox">`. |
| `@makeOptionId` | `(index: number) => string` |  | Id of each option's `<li>`, for `aria-activedescendant`. |
| `@searchable` | `boolean` |  | The list is driven from a search field (which keeps focus). |

| Block | Description |
| --- | --- |
| `<:option>` | Renders an option's label yourself; yields the option and the search. |
| `<:optionPrepend>` | Content before each label (e.g. an icon); yields the option. |
| `<:optionAppend>` | Content after each label (e.g. a badge); yields the option. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiSelectableListItem

One option of an `EuiSelectable` list: a check mark (or a cross when
excluded), the label, and optional prepend / append content. Usually
rendered for you by `EuiSelectable`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@isFocused` | `boolean` |  | Highlights it as the keyboard's current option. |
| `@disabled` | `boolean` |  | Disables the option. |
| `@checked` | `boolean \| 'on' \| 'off'` |  | `'on'` (check mark), `'off'` (cross, excluded) or nothing. |
| `@showIcons` | `boolean` | `true` | Shows the check mark / cross column. |
| `@prepend` | `string` |  | Text before the label. Use the `<:prepend>` block for markup. |
| `@append` | `string` |  | Text after the label. Use the `<:append>` block for markup. |
| `@allowExclusions` | `boolean` |  | Tells screen readers that Enter includes / excludes the option. |
| `@onFocusBadge` |  | `true` | Shows a "return key" badge on the focused option, to hint that Enter selects it: `true`, `false`, or `{ text, iconSide }` for a badge with text (e.g. "Go to"). |
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
| `@defaultValue` | `string` |  | Initial search. |
| `@isPreFiltered` | `boolean` |  | Every option matches (they were already filtered, e.g. by a server). |
| `@listId` | `string` |  | `id` of the list, to link the field to it for screen readers. |
| `@compressed` | `boolean` |  | Smaller field. |
| `@isLoading` | `boolean` |  | Shows a spinner. |

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
