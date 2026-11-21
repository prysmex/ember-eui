---
title: Sheet
order: 0
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet"/>
<EuiSpacer @size="l" />

<EuiText>

`@ember-eui/sheet` is an Airtable-like grid for data entry, built on
`EuiDataGrid`. People edit cells with the keyboard, select ranges, and
copy and paste blocks to and from Excel or Google Sheets. It has
built-in field types for text, numbers, checkboxes, selects, dates,
linked records, users, attachments, currency, percent, duration, rating,
links and long text, and you can add your own cells and editors.

```bash
pnpm add @ember-eui/sheet
```

`@ember-eui/core` is a peer dependency: install and set it up first. The
sheet adds its few styles to the page itself; there is no stylesheet to
import.

Import the components in the `.gts` or `.gjs` files that render them:
`import { EuiSheet, EuiSheetImport } from '@ember-eui/sheet'`. The
package adds nothing to your app's tree (no `app-js`), so your app
bundles only what it imports: installed and not rendered, the sheet
costs nothing; `<EuiSheet>` alone does not bring the import screen; and
the barcode scan panel loads when a barcode editor that can scan opens.

A loose-mode template (`.hbs`) does not find `<EuiSheet />` by name. To
use it from one, re-export it in your own app tree; only the components
you re-export are bundled:

```js
// app/components/eui-sheet.js
export { default } from '@ember-eui/sheet/components/eui-sheet';
```

(`app/components/eui-sheet-import.js` the same way for
`<EuiSheetImport />`, from `@ember-eui/sheet/components/eui-sheet-import`.)
Without it, an Embroider build stops with an error that it cannot
resolve `eui-sheet`.

## The pages

Each page explains one part of the sheet and ends with its examples.

| Page                                                          | What it covers                                                                                | Examples                                                                                       |
| ------------------------------------------------------------- | --------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| [Editing and keyboard](/docs/sheet/docs/sheet/editing)        | change sets, undo and redo, every key, IME, errors                                            | Basics; Validation; Your own store, server ids                                                 |
| [Selection, copy and paste](/docs/sheet/docs/sheet/selection) | ranges, the fill handle, paste, the summary bar, touch                                        | Paste rules; Editing: fill handle, series, cut; Summary bar                                    |
| [Field types](/docs/sheet/docs/sheet/field-types)             | every built-in type, bulk resolve                                                             | Field types; More field types; Linked records and bulk resolve; Attachments                    |
| [Fields and custom types](/docs/sheet/docs/sheet/fields)      | the field editor, field actions, your own cells and editors                                   | Fields from the grid; Custom cells and editors; Another date picker                            |
| [Records and rows](/docs/sheet/docs/sheet/rows)               | the row menu, add, delete, row drag, the expanded record and its footer, row and cell colours | Records; Row order and colours; Cell colours; Expanded record; Comments in the expanded record |
| [Groups and loading more](/docs/sheet/docs/sheet/groups)      | group by, loading more as you scroll                                                          | Group by; Load more as you scroll                                                              |
| [Layout and full screen](/docs/sheet/docs/sheet/layout)       | hidden fields, order, widths, fit to content, row height, frozen fields, full screen          | View intents; Full screen and column tools                                                     |
| [Search and EmberSearchUi](/docs/sheet/docs/sheet/search)     | search matches, the EmberSearchUi connector                                                   | Search navigation; Sheet with EmberSearchUi                                                    |
| [Large data](/docs/sheet/docs/sheet/large-data)               | 10,000 records and 30 fields, frozen fields at scale                                          | Large data                                                                                     |
| [Import and export](/docs/sheet/docs/sheet/import-export)     | CSV export and import, the import screen                                                      | CSV export and import; Import screen                                                           |
| [API reference](/docs/sheet/docs/sheet/api)                   | arguments, the owner, the blocks, the sheet's API, theme                                      | Translations                                                                                   |

## Where the sections went

The sheet's docs were one page. Its sections are now on these pages:

| Section                                     | Page                                                                                |
| ------------------------------------------- | ----------------------------------------------------------------------------------- |
| Records in, change sets out                 | [Editing and keyboard](/docs/sheet/docs/sheet/editing#records-in-change-sets-out)   |
| Undo and redo                               | [Editing and keyboard](/docs/sheet/docs/sheet/editing#undo-and-redo)                |
| Arguments                                   | [API reference](/docs/sheet/docs/sheet/api#arguments)                               |
| The owner                                   | [API reference](/docs/sheet/docs/sheet/api#the-owner)                               |
| Search matches                              | [Search and EmberSearchUi](/docs/sheet/docs/sheet/search#search-matches)            |
| Loading more as you scroll                  | [Groups and loading more](/docs/sheet/docs/sheet/groups#loading-more-as-you-scroll) |
| EmberSearchUi                               | [Search and EmberSearchUi](/docs/sheet/docs/sheet/search#embersearchui)             |
| Presentation state                          | [Layout and full screen](/docs/sheet/docs/sheet/layout#presentation-state)          |
| Full screen                                 | [Layout and full screen](/docs/sheet/docs/sheet/layout#full-screen)                 |
| Summary bar                                 | [Selection, copy and paste](/docs/sheet/docs/sheet/selection#summary-bar)           |
| Export to CSV                               | [Import and export](/docs/sheet/docs/sheet/import-export#export-to-csv)             |
| Import from CSV, the import screen          | [Import and export](/docs/sheet/docs/sheet/import-export#import-from-csv)           |
| Group by                                    | [Groups and loading more](/docs/sheet/docs/sheet/groups#group-by)                   |
| Frozen field                                | [Layout and full screen](/docs/sheet/docs/sheet/layout#frozen-field)                |
| Frozen field: performance                   | [Large data](/docs/sheet/docs/sheet/large-data#performance-with-frozen-fields)      |
| The sheet's API                             | [API reference](/docs/sheet/docs/sheet/api#the-sheets-api)                          |
| Theme                                       | [API reference](/docs/sheet/docs/sheet/api#theme)                                   |
| Theme: row colours, cell colours            | [Records and rows](/docs/sheet/docs/sheet/rows#row-and-cell-colours)                |
| Records                                     | [Records and rows](/docs/sheet/docs/sheet/rows#records)                             |
| Fields                                      | [Fields and custom types](/docs/sheet/docs/sheet/fields#fields)                     |
| Expanded record                             | [Records and rows](/docs/sheet/docs/sheet/rows#expanded-record)                     |
| Field types                                 | [Field types](/docs/sheet/docs/sheet/field-types#field-types)                       |
| Field types: in the field editor            | [Fields and custom types](/docs/sheet/docs/sheet/fields#in-the-field-editor)        |
| Bulk resolve                                | [Field types](/docs/sheet/docs/sheet/field-types#bulk-resolve)                      |
| Keyboard                                    | [Editing and keyboard](/docs/sheet/docs/sheet/editing#keyboard)                     |
| Keyboard: the mouse, the fill handle, paste | [Selection, copy and paste](/docs/sheet/docs/sheet/selection#the-mouse-and-ranges)  |
| Touch                                       | [Selection, copy and paste](/docs/sheet/docs/sheet/selection#touch)                 |
| IME and dead keys                           | [Editing and keyboard](/docs/sheet/docs/sheet/editing#ime-and-dead-keys)            |
| Errors                                      | [Editing and keyboard](/docs/sheet/docs/sheet/editing#errors)                       |

## Not yet

These are not in yet:

- Dragging rows and columns by touch (a touch drag scrolls; the keys,
  the header menu's "Move left/right" and `api.moveRecords` work on a
  phone).
- Managing fields inside the expanded record, and reordering a select's
  options in the field editor.
- On group headers: checkboxes, collapsing without the owner's
  `@onGroupToggle`, taller headers, a colour per level.
- A group-by in EmberSearchUi's own state (its driver and memory
  backend): today the connector forwards your groups and your handlers
  write them with `setExtension` ([Group by](/docs/sheet/docs/sheet/groups#group-by)). Sorting, filtering, search,
  paging and grouping are not "not yet": they are the owner's ([The
  owner](/docs/sheet/docs/sheet/api#the-owner), and the [EmberSearchUi connector](/docs/sheet/docs/sheet/search#embersearchui)), and the sheet draws them.
- Date and time values without a zone ("floating" times).
- A tint of the whole row (`@rowColor` draws a bar).
- Undo of field operations (adding, editing or deleting a field).
- From v0.2: dead keys and IMEs in the expanded record's boxes,
  re-measuring the fill handle on a window resize, a keyboard way to
  choose copy over series in a fill, a cell larger than the visible body,
  one `@onResolve` answer per text, and a message when `maxFiles` drops
  files; and the checks on a Mac and on real phones.

Out of scope: formulas, rollups and lookups, comments, co-editing, and
other kinds of views (calendar, kanban, gallery).

</EuiText>
