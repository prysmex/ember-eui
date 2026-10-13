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
  Groups are `{ groupName, options: [...] }`.
- **Option keys:** besides `label` and `disabled`, objects can have
  `prepend` / `append` (text or a component, shown in the list and the
  pill), `toolTipContent` / `toolTipProps`, `truncationProps`, `title`
  and `color` (pill color), like upstream's `EuiComboBoxOptionOption`.
- **Custom values:** `@onCreateOption` lets users add what they typed
  (`@delimiter` splits pasted lists; `@noSuggestions` hides the list).
- **Async:** `@search` can return a promise, e.g. to query a server.

The options list renders in a portal: add
`<div id="ember-basic-dropdown-wormhole"></div>` to your `index.html` (see
Getting started) or pass `@renderInPlace={{true}}`.

**Ember EUI differences:** upstream React nodes (`prepend`, `append`) are
text or components here. Matching ignores case and accents by default
(ember-power-select); `@isCaseSensitive` uses upstream's matcher.
Selected options stay in the list (marked selected) instead of being
removed. Leaving the combo box only turns typed text into an option with
`@noSuggestions` or `@delimiter`. A highlighted option's tooltip also
shows when the list opens, since the first match is highlighted.

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
| `@singleSelection` | `\| boolean \| { asPlainText?: boolean; }` | multiple selection | Allows only one selected option (still passed to `@onChange` as a one-item array). `{ asPlainText: true }` shows the selection as plain text instead of a pill. |
| `@onCreateOption` | `EuiComboBoxOnCreateOption` |  | Lets the user add the typed text as a new option: shows an "add" option when nothing matches (or always, with `@alwaysShowCreateOption`). Called with the search text and all options (groups flattened); return `false` to reject it. Add the result to `@options` / `@selectedOptions` yourself. Text equal to a selected option is not added again, and text equal to the only matching option selects that option (upstream). |
| `@alwaysShowCreateOption` | `boolean` |  | Shows the "add" option even when some options match. |
| `@options` (required) | `any[]` |  | The options: strings, or objects shown by the default block (e.g. `{{option.label}}`). Groups are `{ groupName: 'Fruits', options: [...] }`. A promise is supported (shows `@loadingMessage` while pending). |
| `@search` |  |  | Custom search, e.g. to query a server: `(term, select) => results` (or a promise). Without it the options are filtered locally, by `@searchField` for objects. |
| `@searchField` | `string` |  | Key of object options to match the search text against, e.g. `'label'`. |
| `@isInvalid` | `boolean` |  | Shows the invalid state. |
| `@fullWidth` | `boolean` |  | Stretches the combo box to its container's width. |
| `@searchMessage` | `string` | "Type to search" | Message shown before typing when `@search` is set. |
| `@searchEnabled` | `boolean` | `true` | Allows typing to filter options. |
| `@isClearable` | `boolean` | `true` | Shows a button clearing the selection. |
| `@isLoading` | `boolean` |  | Shows a spinner in the input, e.g. while options load. |
| `@isDisabled` | `boolean` |  | Disables the combo box. |
| `@searchMessageComponent` | `any` |  | Component rendered instead of `@searchMessage`. |
| `@compressed` | `boolean` |  | Smaller combo box, for dense forms. |
| `@onFocus` | `(e: FocusEvent) => void` |  | Called when the input gets focus. |
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
| `@closeOnSelect` | `boolean` |  | Closes the options list after selecting one. |
| `@autoFocus` | `boolean` |  | Focuses the combo box and opens its options on render. |
| `@defaultHighlighted` | `any` |  | Option highlighted when the list opens. |
| `@matchTriggerWidth` | `boolean` |  | Makes the options list as wide as the input. |
| `@tabindex` | `number` |  | `tabindex` of the combo box. |
| `@initiallyOpen` | `boolean` |  | Opens the options list on render. |
| `@horizontalPosition` | `string` |  | Horizontal alignment of the options list: `'auto'`, `'left'`, `'right'` or `'center'`. |
| `@verticalPosition` | `string` |  | Vertical position of the options list: `'auto'`, `'above'` or `'below'`. |
| `@destination` | `string` |  | Id of the element the options list renders into. |
| `@preventScroll` | `boolean` |  | Prevents the page from scrolling while the options list is open. |
| `@noMatchesMessage` | `string` | "No results found" | Message when no option matches. |
| `@optionsClass` | `string` |  | Extra class for the element wrapping the options. |
| `@rowHeight` | `number \| 'auto'` | 29 | Height in px of each option in the (virtualized) list. Set it when the block renders taller options. `'auto'` turns virtualization off so long options wrap onto several lines (slower for long lists; no truncation). |
| `@noSuggestions` | `boolean` |  | Hides the options list: the combo box only takes typed values (`@onCreateOption`, added with Enter), and has no dropdown icon. |
| `@delimiter` | `string` |  | A character separating several values in the typed or pasted text, typically `','`. Typing it adds the text before it; Enter (or leaving the combo box) adds each value of pasted text. |
| `@isCaseSensitive` | `boolean` |  | Matches options case-sensitively. |
| `@sortMatchesBy` | `EuiComboBoxSortMatchesBy` | `'none'` | `'startsWith'` lists the matches starting with the search text first; `'none'` keeps the options' order. |
| `@truncationProps` | `EuiComboBoxTruncationProps` | CSS truncation at the end | Truncation of long option texts, any `EuiTextTruncate` argument but `text` (e.g. `{ truncation: 'middle' }`). Options can override it with their own `truncationProps`. While searching, the text is truncated around the match instead. |
| `@prepend` | `EuiComboBoxNode \| EuiComboBoxNode[]` |  | Text, a component, or an array of them before the input, e.g. a label. Only shown with `@singleSelection` (upstream), so pills never wrap onto taller rows. |
| `@append` | `EuiComboBoxNode \| EuiComboBoxNode[]` |  | Like `@prepend`, after the input. Only with `@singleSelection`. |
| `@matcher` | `(option: any, searchText: string) => number` |  | Custom matching for local filtering: `(option, searchText) => -1` for no match, anything else for a match. |
| `@typeAheadOptionMatcher` | `(option: any, searchText: string) => number` |  | Matching used when typing while the list is closed. |
| `@triggerIcon` | `any` |  | Icon in the input, anything `EuiIcon`'s `@type` accepts. |
| `@removeTag` | `(option: any) => void` |  | Called when a selected option's pill is removed. |
| `@onInput` | `(text: string, select: any, event: Event) => any` |  | Called on every input with the text and the select API. |
| `@onKeydown` | `(select: any, event: KeyboardEvent) => any` |  | Called on keydown; return `false` to prevent the default behavior. |
| `@registerApi` | `(select: any) => void` |  | Called with ember-power-select's API (`actions.open()`, `search`, …). |
| `@calculatePosition` | `(...args: any[]) => any` |  | Custom positioning of the options list, see ember-basic-dropdown. |
| `@eventType` | `string` |  | Event that opens the list: `'click'` or `'mousedown'`. |
| `@ariaLabel` | `string` |  | Accessible label of the combo box. |
| `@ariaLabelledBy` | `string` |  | Id of the element labelling the combo box. |
| `@required` | `boolean` |  | Marks the combo box as required for assistive technology. |
| `@triggerRole` | `string` |  | `role` of the input. |
| `@title` | `string` |  | `title` of the combo box. |
| `@triggerId` | `string` |  | Id of the input, e.g. for an `EuiFormRow`'s label. |

Deprecated: `@readOnly` (Has no effect; use `@isDisabled`.); `@noMatchesMessageComponent` (Has no effect; the "no matches" / "add" option is built in.).

| Block | Description |
| --- | --- |
| default block | Renders each option (in the list and in the pills), with its index and the search text (upstream `renderOption`): `as \|option i search\|` → `<EuiHighlight @text={{option.label}} @search={{search}} />`. In pills the second value is the select API and the search is empty. Optional: without a block, options show their text (strings, or `@searchField` / `label` of objects), with the search text highlighted in the list like upstream. Option `prepend` / `append` render around the block. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
