---
title: API reference
order: 13
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: API reference"/>
<EuiSpacer @size="l" />

<EuiText>

Every argument of `<EuiSheet>`, what the owner does, the blocks, the
sheet's API and its theme.

## Arguments

| Argument | Description |
| --- | --- |
| `@fields` | The visible columns, in order: `{ id, label?, type?, readOnly?, required?, validate?, description?, width?, sortable?, hideable?, manageable?, groupable?, importAliases?, ...options of the type }`. `readOnly` and `required` can be functions of the record. `description` is a tip in the header and help text in the expanded record; `width` a default width in px; `sortable: false` and `hideable: false` drop those menu items; `manageable: false` drops Edit, Duplicate and Delete field (a system field); `groupable: false` drops "Group by this field"; `importAliases` are other names the field has in files ([Import from CSV](/docs/sheet/docs/sheet/import-export#import-from-csv)). |
| `@records` | The rows. Pass a new array when they change. |
| `@getRecordId` | `(record) => id`. |
| `@onChange` | `(changeSet) => void`. Apply it to your records. |
| `@validate` | Record, cross-row and server rules: `({ records, changed, signal }) => errors`, sync or async. |
| `@cellErrors` | Your own errors: `{ [recordId]: { [fieldId]: message or messages } }`. |
| `@fieldTypes` | Your field types, merged over the built-in ones. Keep the object stable (not created in a template). |
| `@readOnly` | Every cell read-only. Copy still works. |
| `@messages` | Overrides of the built-in messages, for this sheet. |
| `@height` | The grid's height. |
| `@ariaLabel` | The grid's accessible name. Default `Sheet`. |
| `@registerApi` | `(api) => void`: receives the sheet's API once, after the first render (below). |
| `@hiddenFields` | Fields that exist but are not columns: shown in the expanded record after `@fields`, copied by duplicate, put back by undo, given to the blocks (`showField`). |
| `@onHiddenFieldsChange` | `(fieldIds) => void`: the new list of hidden ids after "Hide column" or a block's `hideField` / `showField`. With it, update `@fields` and `@hiddenFields`; without it the sheet hides and shows fields itself. |
| `@onFieldOrderChange` | `(fieldIds) => void`: the visible ids in their new order after "Move left/right" or a header drag. With it, update `@fields`; without it the sheet keeps its own order. |
| `@fieldDrag` | Drag a header to reorder the fields (also Space, the arrows and Space on a focused header). Default `true`; `false` turns it off. |
| `@headerLines` | `1` (default), `2` or `3`: the lines a header label may wrap to. The header row grows to fit; a cut label keeps its full text as the header's tooltip. |
| `@fieldWidths`, `@onFieldWidthChange` | Widths in px by field id (over `field.width`); `(fieldId, width) => void` after a resize or a fit to content ("Fit to content", a double-click on the resize edge, `api.fitField`). Without the handler the sheet keeps a resized or fitted width itself, over `@fieldWidths` and `field.width`, also when the columns are hidden, shown or moved; keep them in `@fieldWidths` to keep them across renders of the sheet. |
| `@rowHeight`, `@onRowHeightChange` | `'short'` (default, one line), `'medium'` (2 lines), `'tall'` (4), `'extraTall'` (6); changed by a block's `setRowHeight`. With the handler, update `@rowHeight`. |
| `@sort`, `@onSortChange` | Your sort, `[{ field, direction: 'asc' or 'desc' }]`, drawn as header arrows; the menu's "Sort" items call the handler with the whole new sort. Without the handler there are no sort items and no arrows. The sheet never sorts. |
| `@onFilterByField` | `(fieldId) => void`: adds "Filter by this field" to the column menu. |
| `@groups` | The group headers to draw, depth-first in display order ([Group by](/docs/sheet/docs/sheet/groups#group-by)). Absent or empty: no groups. |
| `@groupBy` | Your group-by, `[{ field, direction }]`, outermost first: picks the header menu item and names the header labels. |
| `@onGroupByChange` | `(groupBy) => void`: adds "Group by this field" (and "Remove grouping" on a grouped field) to the column menu. |
| `@onGroupToggle` | `(key, collapsed) => void`: gives each group header its toggle. |
| `@onFieldCreate` | `(draft, { index, after?, copyOf? }) => void or Promise`: adds the "+" column at the right, "Insert left/right" and "Duplicate field" to the column menu ([Fields](/docs/sheet/docs/sheet/fields#fields)). |
| `@onFieldUpdate` | `(fieldId, draft, { previous }) => void or Promise`: adds "Edit field". |
| `@onFieldDelete` | `(fieldId) => void or Promise`: adds "Delete field", after a confirmation. |
| `@fieldEditor` | A component that replaces the field editor's content (the sheet keeps its frame). |
| `@creatableFieldTypes` | The types the field editor offers, in order. Default: `text`, `longText`, `number`, `currency`, `percent`, `checkbox`, `singleSelect`, `multiSelect`, `date`, `duration`, `rating`, `url`, `email`, `phone`. `dateTime`, `button` and `barcode` have their options there too (zone, clock and seconds; text, icon and colour); list them to offer them. |
| `@highlight` | A term you searched for: matching text is marked in cells (any case, every match). |
| `@currentMatch` | `{ recordId, fieldId }` or `null`: your current search match. When it changes the sheet scrolls it into view and rings it, without moving focus or the selection ([Search matches](/docs/sheet/docs/sheet/search#search-matches)). |
| `@onSelectionChange` | `(selection or null) => void`: the selected cells' records and fields, after render, when they change ([Summary bar](/docs/sheet/docs/sheet/selection#summary-bar)). |
| `@onVisibleRangeChange` | `({ first, last, count }) => void`: the records on screen, as positions in `@records`, after render, when they change ([Loading more as you scroll](/docs/sheet/docs/sheet/groups#loading-more-as-you-scroll)). |
| `@fullScreen`, `@onFullScreenChange` | The sheet fills the window ([Full screen](/docs/sheet/docs/sheet/layout#full-screen)): `(on) => void` from the block's `setFullScreen`, `api.setFullScreen` and Escape. With the handler the sheet shows exactly `@fullScreen`; without it, `@fullScreen` is the start and the sheet keeps its own state. |
| `@isLoading` | A thin progress bar over the grid; the grid stays usable. |
| `@summary` | `{ [fieldId]: text }` (and `''` for the row-number column): shows the summary bar ([Summary bar](/docs/sheet/docs/sheet/selection#summary-bar)). |
| `@frozenFields` | Leading fields kept in view on horizontal scroll, with the row numbers. Default `0` (off); `1` freezes the first field. |
| `@rowNumbers` | The row-number column. Default `true`; `false` hides it. |
| `@rowLabel` | `(record, position) => string`: what a row number shows instead of its position (for example the record's id). The column widens to fit. |
| `@rowNumberOffset` | The position of the first record when `@records` is one page of your data: page 2 of 50 passes `50`. Default `0`. |
| `@canInsert`, `@canDelete` | The add row (grouped: the groups' add rows), Shift+Enter and the menu's insert and duplicate; the menu's delete. Default: `!@readOnly`. Without inserting, a paste stops at the last record. |
| `@canMove` | Row drag ([Records](/docs/sheet/docs/sheet/rows#records)): a grip in each row number, and Alt+Shift+ArrowUp/Down, emit change sets with `moves`. Off with `@readOnly`, a non-empty `@sort` or `@rowNumbers={{false}}` (the keys and `api.moveRecords` need no row numbers). Default `false`. |
| `@rowColor` | `(record) => colour or undefined`: a 4 px bar at the row's left edge ([Row and cell colours](/docs/sheet/docs/sheet/rows#row-and-cell-colours)). `colorByOption(field)` colours by a select's options. |
| `@cellColor` | `(record, field) => colour or undefined`: a 3 px bar along the cell's bottom edge, the same colours as `@rowColor` ([Row and cell colours](/docs/sheet/docs/sheet/rows#row-and-cell-colours)). Called for each rendered cell: keep it cheap, no lookups across rows. |
| `@onButtonPress` | `({ recordId, fieldId, record }, { signal }) => void or Promise`: a button field's press ([Field types](/docs/sheet/docs/sheet/field-types#field-types)), for every button field. |
| `@newRecordValues` | `({ above, below }) => values`: the values of a new record, from its neighbours. Default `{}`. |
| `@checkedRecordIds`, `@onCheckedChange` | The checked rows. With the handler, the sheet shows exactly `@checkedRecordIds` and calls the handler with the new list; without it, it keeps its own. |
| `@expandedRecordId`, `@onExpandedRecordChange` | The expanded record, controlled the same way. |
| `@expandedRecord` | `'flyout'` (default) or `'modal'`. |
| `@rowActions` | Your items of the row menu: `{ id, label, icon?, color?: 'danger', isDisabled?(records), onSelect(records) }`. |
| `@fieldActions` | Your items of every visible field's header menu, after the sheet's own and before "Delete field": `{ id, label, icon?, color?: 'danger', isDisabled?(field), onSelect(field) }` ([Fields](/docs/sheet/docs/sheet/fields#fields)). Keep the array stable. |
| `@copyWithFieldNames` | Adds "Copy with field names" to the row menu, next to Copy ([Records](/docs/sheet/docs/sheet/rows#records)). Default `false`. |
| `@onResolve` | `(requests, { signal }) => Promise<result>`: resolves typed or pasted text of linked-record, user and your own types through your API ([bulk resolve](/docs/sheet/docs/sheet/field-types#bulk-resolve)). Without it such text is rejected. |
| `@editIn` | Where a click on the selected cell, or Enter, edits: `'cell'` (the editor over the cell), `'record'` (the expanded record, with that field's editor open), or `'auto'` (default: the record on a touch screen when the sheet is narrower than 600 px, else the cell). Typing on a cell always edits in the cell. |

## The owner

The sheet is a view of the rows it is given. It never sorts, filters,
searches, groups, pages or summarizes: those are queries, and they are
yours (a store, a server, an EmberSearchUi driver). The sheet draws your
state and tells you what the user asked for:

| The user | The sheet calls | You |
| --- | --- | --- |
| Sort from a column's menu | `@onSortChange(sort)` | sort `@records`, pass `@sort` (the arrows) |
| "Group by this field", "Remove grouping" | `@onGroupByChange(groupBy)` | group `@records`, pass `@groups` and `@groupBy` |
| Collapses or expands a group | `@onGroupToggle(key, collapsed)` | drop or add its records, pass the header with `collapsed` |
| "Filter by this field" | `@onFilterByField(fieldId)` | open your filter UI |
| Types in your search box | (nothing: the box is yours) | filter `@records`, pass `@highlight` |
| Steps to the next match in your box | (nothing) | pass `@currentMatch` (expand its group or change the page first) |
| Selects cells | `@onSelectionChange(selection)` | show a summary of the selection (`summarizeCells`) |
| Changes page in your pager | (nothing) | pass that page as `@records`, and `@rowNumberOffset` |
| Scrolls near the end | `@onVisibleRangeChange({ first, last, count })` | load the next page, append it to `@records` |
| Waits | | pass `@isLoading` |
| Drags a row (with `@canMove`) | `@onChange` with `moves` | put the records in the new order, pass them |
| Presses a button cell | `@onButtonPress({ recordId, fieldId, record }, { signal })` | run your action; a promise shows it pending, a rejection as the cell's error |
| Hides, moves, resizes a column | `@onHiddenFieldsChange`, `@onFieldOrderChange`, `@onFieldWidthChange` | update `@fields`, `@hiddenFields`, `@fieldWidths` |
| Picks a row height in your control | `@onRowHeightChange` (through the block's `setRowHeight`) | update `@rowHeight` |
| Fits a column to its content | `@onFieldWidthChange` | update `@fieldWidths` |
| Presses your full-screen button, or Escape | `@onFullScreenChange` (through the block's `setFullScreen`) | update `@fullScreen` |

There is no built-in toolbar. Two blocks take your own controls, inside
the sheet (so they get its theme) and outside the grid (so they are normal
tabbable elements):

```gjs
<EuiSheet @fields={{this.fields}} @records={{this.records}} …>
  <:toolbar as |sheet|>
    {{! a search box, a field picker, a row-height control }}
  </:toolbar>
  <:footer as |sheet|>
    {{! a pager, a count }}
  </:footer>
</EuiSheet>
```

Each yields the same object: `api` (the sheet's API, below), `fields` (the
visible ones), `hiddenFields`, `sort`, `rowHeight`, `checkedRecords`,
`selection` (the selected cells, or `null`; [Summary bar](/docs/sheet/docs/sheet/selection#summary-bar)), `groupBy` and `groups` (`@groupBy` and `@groups`, or `[]`), `isFullScreen`, and
`hideField(id)`, `showField(id)`, `setRowHeight(rowHeight)`,
`setSort(sort)`, `setGroupBy(groupBy)`, `toggleGroup(key)` and `setFullScreen(on)`, which call
your handlers (or change the sheet's own state without them; `setSort`,
`setGroupBy` and `toggleGroup` do nothing without `@onSortChange`,
`@onGroupByChange` and `@onGroupToggle`).

## The sheet's API

`@registerApi` gives you one object to call from your own controls or
store:

| Method | |
| --- | --- |
| `undo()`, `redo()` | Ctrl/Cmd+Z and Ctrl/Cmd+Shift+Z, from outside the sheet. |
| `focusCell({ recordId, fieldId })` | Focuses that cell. Nothing happens when the record is not in `@records` or the field is not shown. |
| `scrollToCell({ recordId, fieldId })` | Scrolls that cell into view without focusing it or changing the selection (`@currentMatch` does this and draws the ring). |
| `getSelection()` | The selection now ([Summary bar](/docs/sheet/docs/sheet/selection#summary-bar)), or `null`. |
| `remapIds({ [tempId]: id })` | The ids your store gave to inserted (or restored) records. The undo history, rejected texts and a pending focus are rewritten. |
| `clearHistory()` | Drops the undo and redo history. |
| `expandRecord(id)` | Opens that record (`null` closes it). |
| `insertRecord({ anchor?, values? })` | Emits the insert of one record, next to `anchor` (`{ recordId, position: 'before' or 'after' }`) or at the end. `values` default to `@newRecordValues`. |
| `deleteRecords(ids)` | Emits the delete of those records. |
| `showShortcuts()` | Opens the shortcut list (as Ctrl/Cmd+/ on the grid). The blocks have `showShortcuts()` too, for a toolbar button. |
| `addField({ index? })` | Opens the field editor to add a field at `index` among the visible fields (default: the end; never before the first field). With `@onFieldCreate`. The blocks have `addField()` too. |
| `moveRecords(ids, { recordId, position })` | Emits the move of those records before or after a record of `@records`, as a drag there would. With `@canMove`. |
| `editField(fieldId)` | Opens the field editor on a field, also a hidden one (it opens under the "+" header then). With `@onFieldUpdate`. |
| `fitField(fieldId)`, `fitFields()` | Fits a visible field's width to its content, or every visible field's ([Fit to content](/docs/sheet/docs/sheet/layout#presentation-state)): `@onFieldWidthChange` once per field, or the sheet keeps the widths. |
| `setFullScreen(on)` | Full screen on or off ([Full screen](/docs/sheet/docs/sheet/layout#full-screen)): `@onFullScreenChange`, or the sheet's own state. |
| `appendRows(rows, fieldIds, { fields? })` | Adds the rows as records after the last one, as a paste on the add row: one change set and one undo step ([Import from CSV](/docs/sheet/docs/sheet/import-export#import-from-csv)). `false` with `@canInsert={{false}}`. |

When you replace `@records` with records the sheet did not change
(another sort, another page, a reload), the selection follows its record:
it collapses to the focused cell's record, wherever it is now (or the same
row, when that record is gone), and an open editor stays on its record (it
is closed without saving when the record is gone).

## Theme

The sheet takes its colours (selection, focus, errors, the editor's input
and the checkbox) from the EUI theme, so it follows light and dark: put
it inside an `EuiEmotionProvider` with `@colorMode="dark"` (or set the
`eui-emotion` service's `colorMode`). The colours are CSS custom
properties set by a class on the sheet's wrapper (`--euiSheet-primary`,
`--euiSheet-selected`, `--euiSheet-hover`, `--euiSheet-plain`,
`--euiSheet-text`, `--euiSheet-textSubdued`, `--euiSheet-danger`,
`--euiSheet-textDanger`, `--euiSheet-dangerFilled`,
`--euiSheet-textInverse`, `--euiSheet-shadow`, `--euiSheet-subdued`,
`--euiSheet-border`, `--euiSheet-link` (link text and file names),
`--euiSheet-star` (a rating's stars), `--euiSheet-checked` (checked rows),
`--euiSheet-elevation` (the open editor's and the row menu's shadow),
`--euiSheet-textSuccess` (a success button's text), `--euiSheet-match`
(the current search match's ring, the theme's warning), the row colours
`--euiSheet-rowPrimary`, `-rowAccent`, `-rowSuccess`, `-rowWarning`,
`-rowDanger` and `-rowNeutral`, and `--euiSheet-highlight` for what is
coming). `--euiSheet-selected`, the
range tint, is the theme's primary at 12 % (20 % in dark). To change
one, set it on the sheet itself, which takes attributes
(`<EuiSheet style="--euiSheet-selected: #E6F0FF" …>`) or a more specific
selector; set on a parent element, it loses to the sheet's class. The
expanded record's flyout or modal, the row menu, the field editor and the
panel editors (`editorLayout: 'panel'`: the selects, linked records,
users, attachments, an app type's picker) are rendered at the end
of `<body>`, placed by their cell or header (below it, above it when there
is no room below in the window), so a card, panel or tab with
`overflow: hidden` around the sheet does not cut them off. They get the
class too, and the overrides set on the sheet's own `style` when they
open; CSS for an app's panel editor should not be scoped under
`.euiSheet`. An editor gets that class as `@themeClass`: one that renders a part of
itself outside the sheet (a wormholed list) adds it there; without it
that part uses the light colours.

</EuiText>

<EuiSpacer @size="xl" />

<EuiText>

## Examples

</EuiText>

[[demos-all]]
