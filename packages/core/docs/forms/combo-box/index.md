---
order: 1
title: Combo box
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Combo box"/>

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
| `@onCreateOption` | `(search: string) => boolean \| undefined` |  | Lets the user add the typed text as a new option: shows an "add" option when nothing matches (or always, with `@alwaysShowCreateOption`). Called with the search text; return `false` to reject it, or a value to use instead of the text. Add the result to `@options` / `@selectedOptions` yourself. |
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
| `@rowHeight` | `number` |  | Height in px of each option in the (virtualized) list. |
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
| default block | Renders each option, with its index: `as \|option\|` → `{{option.label}}`. Strings can be rendered as they are. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
