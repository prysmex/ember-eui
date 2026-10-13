---
order: 1
title: Combo box
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Combo box"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiComboBox` is a searchable select for picking one or many options from
a (possibly long) list, with optional custom values. It is built on
[ember-power-select](https://ember-power-select.com), so most of its
features (custom matching, async search, positioning) are available too.

```hbs
<EuiComboBox
  @options={{this.fruits}}
  @selectedOptions={{this.selected}}
  @searchField="label"
  @onChange={{this.select}}
  @placeholder="Pick fruits"
  as |fruit|
>
  {{fruit.label}}
</EuiComboBox>
```

- **Selection:** you keep `@selectedOptions` (an array) and replace it in
  `@onChange`, which receives the new array, also for
  `@singleSelection={{true}}` (a one-item array).
- **Options:** strings or objects; the block renders each option
  (`{{fruit.label}}`). `@searchField` names the key searched for objects.
  Groups are `{ groupName, options: [...] }` (or upstream's `{ label,
  options }`). In multiple selection the selected options are not listed;
  the list is derived from `@options`, `@selectedOptions` and the search
  text on every change, and neither array is changed.
- **Option keys:** besides `label` and `disabled`, objects can have
  `prepend` / `append` (text or a component, shown in the list and the
  pill), `toolTipContent` / `toolTipProps`, `truncationProps`, `title`
  and `color` (pill color), like upstream's `EuiComboBoxOptionOption`.
  As upstream, a selected option's other keys (`data-test-subj`, `id`,
  `aria-*`, `className`, …) are set on its pill, and an `onClick` makes
  the pill a "Change" button without a remove button. This applies to
  plain objects without `@searchField` (other objects are your data).
- **Toggle button:** pressing the chevron moves focus to it, as upstream:
  closing the list keeps focus there (arrows reopen and move through it,
  Escape closes it); opening it focuses the input.
- **Custom values:** `@onCreateOption` lets users add what they typed
  (`@delimiter` splits pasted lists; `@noSuggestions` hides the list).
- **Async:** `@async` with `@onSearchChange` (upstream), or `@search`,
  which can return a promise, e.g. to query a server.

The options list renders in a portal: add
`<div id="ember-basic-dropdown-wormhole"></div>` to your `index.html` (see
Getting started) or pass `@renderInPlace={{true}}`.

**Ember EUI differences:** upstream React nodes (`prepend`, `append`) are
text or components here. With `@sortMatchesBy="startsWith"` and groups,
a group title moved away from all of its options is not shown. While an
option is highlighted with the arrow keys, typing keeps that option
highlighted if it still matches (upstream keeps the position instead).

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiComboBox

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@singleSelection` | `\| boolean \| { asPlainText?: boolean; }` | multiple selection | Allows only one selected option (still passed to `@onChange` as a one-item array). `{ asPlainText: true }` shows the selection as the input's text instead of a pill. |
| `@onCreateOption` | `EuiComboBoxOnCreateOption` |  | Lets the user add the typed text as a new option: shows an "add" option when nothing matches (or always, with `@alwaysShowCreateOption`), and Enter or leaving the combo box adds the text (upstream). Called with the search text and all options (groups flattened); return `false` to reject it. Add the result to `@options` / `@selectedOptions` yourself. Text equal to a selected option is not added again, and text equal to the only matching option selects that option. |
| `@alwaysShowCreateOption` | `boolean` |  | Shows the "add" option even when some options match. |
| `@options` (required) | `any[]` |  | The options: strings, or objects with a `label` (or `@searchField`). Groups are `{ groupName: 'Fruits', options: [...] }` (or upstream's `{ label: 'Fruits', options: [...] }`). In multiple selection the selected options are not listed (upstream). A promise is supported (shows `@loadingMessage` while pending). Never changed by the combo box; pass a new array to change the options. |
| `@search` |  |  | Custom search, e.g. to query a server: `(term, select) => results` (or a promise). Without it the options are filtered locally, by `@searchField` for objects. Selected options are left out of the results in multiple selection. |
| `@searchField` | `string` |  | Key of object options to match the search text against, e.g. `'label'`. |
| `@isInvalid` | `boolean` |  | Shows the invalid state. |
| `@fullWidth` | `boolean` |  | Stretches the combo box to its container's width. |
| `@searchMessage` | `string` | "Type to search" | Message shown before typing when `@search` is set. |
| `@searchEnabled` | `boolean` | `true` | Allows typing to filter options. |
| `@isClearable` | `boolean` | `true` | Shows a button clearing the selection. |
| `@isLoading` | `boolean` |  | Shows a spinner in the input and the list, e.g. while options load. |
| `@isDisabled` | `boolean` |  | Disables the combo box. |
| `@searchMessageComponent` | `any` |  | Component rendered instead of `@searchMessage`. |
| `@compressed` | `boolean` |  | Smaller combo box, for dense forms. |
| `@onFocus` | `(e: FocusEvent) => void` |  | Called when the input gets focus (which opens the list, upstream). |
| `@onBlur` | `(e: FocusEvent) => void` |  | Called when the input loses focus. |
| `@onClose` | `(e: Event) => void` |  | Called when the options list closes; return `false` to keep it open. |
| `@onOpen` | `(e: Event) => void` |  | Called when the options list opens; return `false` to keep it closed. |
| `@renderInPlace` | `boolean` |  | Renders the options list next to the input instead of in a portal at the end of the page (e.g. inside modals with their own scrolling). |
| `@customOptionText` | `string` | "Add **{searchText}** as custom option" | Text (HTML) of the "add" option; `{searchText}` is replaced by the typed text. |
| `@loadingMessage` | `any` | "Loading options..." | Message while `@options` or `@search` load. |
| `@selectedItemComponent` | `any` |  | Component rendering each selected option (pill). |
| `@beforeOptionsComponent` | `any` |  | Component rendered above the options. |
| `@placeholderComponent` | `any` |  | Component rendered instead of `@placeholder`. |
| `@afterOptionsComponent` | `any` |  | Component rendered below the options. |
| `@searchPlaceholder` | `any` |  | Placeholder of the search input. |
| `@dropdownClass` | `string` |  | Extra class for the options list. |
| `@selectedOptions` | `any[]` |  | The selected options (items of `@options`). |
| `@onChange` (required) | `(selected: any[]) => void` |  | Called with the new selection (an array, also with `@singleSelection`). Update `@selectedOptions` here. |
| `@placeholder` | `string` |  | Text shown when nothing is selected. |
| `@extra` | `any` |  | Anything, passed to custom components as `@extra`. |
| `@closeOnSelect` | `boolean` | `true` for single selection and `false` for multiple selection (upstream) | Closes the options list after selecting one. |
| `@autoFocus` | `boolean` |  | Focuses the combo box and opens its options on render. |
| `@defaultHighlighted` | `any` |  | Option highlighted when the list opens, or an ember-power-select `defaultHighlighted` function. By default nothing is highlighted until the arrow keys are used (upstream), except single selection's option when the list is opened by clicking. |
| `@matchTriggerWidth` | `boolean` |  | Makes the options list as wide as the input. |
| `@tabindex` | `number` |  | `tabindex` of the search input. |
| `@initiallyOpen` | `boolean` |  | Opens the options list on render. |
| `@horizontalPosition` | `string` |  | Horizontal alignment of the options list: `'auto'`, `'left'`, `'right'` or `'center'`. |
| `@verticalPosition` | `string` |  | Vertical position of the options list: `'auto'`, `'above'` or `'below'`. |
| `@destination` | `string` |  | Id of the element the options list renders into. |
| `@preventScroll` | `boolean` |  | Prevents the page from scrolling while the options list is open. |
| `@noMatchesMessage` | `string` | upstream's "{searchValue} doesn't match any options" / "There aren't any options available" | Message when no option matches the search (or when there are no options). |
| `@optionsClass` | `string` |  | Extra class for the element wrapping the options. |
| `@rowHeight` | `number \| 'auto'` | 29 | Height in px of each option in the (virtualized) list. Set it when the block renders taller options. `'auto'` turns virtualization off so long options wrap onto several lines (slower for long lists; no truncation). |
| `@noSuggestions` | `boolean` |  | Hides the options list: the combo box only takes typed values (`@onCreateOption`, added with Enter), and has no dropdown icon. |
| `@delimiter` | `string` |  | A character separating several values in the typed or pasted text, typically `','`. Typing it adds the text before it; Enter (or leaving the combo box) adds each value of pasted text. |
| `@isCaseSensitive` | `boolean` |  | Matches options case-sensitively. |
| `@sortMatchesBy` | `EuiComboBoxSortMatchesBy` | `'none'` | `'startsWith'` lists the matches starting with the search text first; `'none'` keeps the options' order. |
| `@truncationProps` | `EuiComboBoxTruncationProps` | CSS truncation at the end | Truncation of long option texts, any `EuiTextTruncate` argument but `text` (e.g. `{ truncation: 'middle' }`). Options can override it with their own `truncationProps`. While searching, the text is truncated around the match instead. |
| `@prepend` | `EuiComboBoxNode \| EuiComboBoxNode[]` |  | Text, a component, or an array of them before the input, e.g. a label. Only shown with `@singleSelection` (upstream), so pills never wrap onto taller rows. |
| `@append` | `EuiComboBoxNode \| EuiComboBoxNode[]` |  | Like `@prepend`, after the input. Only with `@singleSelection`. |
| `@matcher` | `(option: any, searchText: string) => number` | upstream's matching (the label includes the search text, ignoring case unless `@isCaseSensitive`) | Custom matching for local filtering: `(option, searchText) => -1` for no match, anything else for a match. |
| `@optionMatcher` | `EuiComboBoxOptionMatcher` |  | Upstream's custom matching, used before `@matcher`: `({ option, searchValue, normalizedSearchValue, isCaseSensitive }) => boolean`. |
| `@async` | `boolean` |  | The options are already filtered for the search text (e.g. loaded from a server in `@onSearchChange`): they are listed as they are, without the selected options. |
| `@onSearchChange` |  |  | Called whenever the search text changes, with the text and whether any option matches it. |
| `@onFocusBadge` | `boolean` |  | Shows a "return" badge on the highlighted option. |
| `@typeAheadOptionMatcher` | `(option: any, searchText: string) => number` |  | Matching used when typing while the list is closed. |
| `@triggerIcon` | `any` |  | Icon in the input, anything `EuiIcon`'s `@type` accepts. |
| `@removeTag` | `(option: any) => void` |  | Called when a selected option's pill is removed. |
| `@onInput` | `(text: string, select: any, event: Event) => any` |  | Called on every input with the text and the select API. |
| `@onKeydown` | `(select: any, event: KeyboardEvent) => any` |  | Called on keydown (with the select API and the event) before the combo box handles the key; return `false` to prevent that. |
| `@registerApi` | `(select: any) => void` |  | Called with ember-power-select's API (`actions.open()`, `search`, …). |
| `@calculatePosition` | `(...args: any[]) => any` |  | Custom positioning of the options list, see ember-basic-dropdown. |
| `@eventType` | `string` |  | Event that opens the list: `'click'` or `'mousedown'`. |
| `@ariaLabel` | `string` |  | Accessible label of the combo box. |
| `@ariaLabelledBy` | `string` |  | Id of the element labelling the combo box. |
| `@required` | `boolean` |  | Marks the combo box as required for assistive technology. |
| `@triggerRole` | `string` | `combobox` | `role` of the search input. |
| `@title` | `string` |  | `title` of the combo box. |
| `@triggerId` | `string` |  | Id of the input, e.g. for an `EuiFormRow`'s label. |

Deprecated: `@readOnly` (Has no effect; use `@isDisabled`.); `@noMatchesMessageComponent` (Has no effect; the "no matches" / "add" option is built in.).

| Block | Description |
| --- | --- |
| default block | Renders each option (in the list and in the pills), with its index and the search text (upstream `renderOption`): `as \|option i search\|` → `<EuiHighlight @text={{option.label}} @search={{search}} />`. In pills the second value is the select API and the search is empty. Optional: without a block, options show their text (strings, or `@searchField` / `label` of objects), with the search text highlighted in the list like upstream. Option `prepend` / `append` render around the block. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
