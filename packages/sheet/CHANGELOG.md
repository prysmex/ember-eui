# @ember-eui/sheet

## 16.3.0

### Minor Changes

- a825d3f: New package: `EuiSheet`, an Airtable-like data-entry grid built on `EuiDataGrid`.

  - **Controlled data:** `@records` in, `@onChange(changeSet)` out. Every write (typing, clearing, pasting, filling, inserting, deleting, moving rows) is a change set your store applies. `localRecords` is a ready store for local data; `EuiSheetSearch` (`@ember-eui/sheet/search-ui`) connects it to EmberSearchUi.
  - **Editing like a spreadsheet:** keyboard editing, range selection, copy and paste as TSV to and from spreadsheets, cut, the fill handle and fill series, Ctrl+D / Ctrl+R, undo and redo, insert, duplicate and delete records, the expanded record view.
  - **Field types:** text, long text, number, currency, percent, duration, rating, checkbox, single and multiple select, date, date with a time in a zone, links, linked records, users, attachments (with upload progress), buttons that run your action, and barcodes (typed, pasted or scanned). Custom cells and editors through a documented contract.
  - **Fields from the grid:** add, edit, duplicate, hide and delete fields (the "+" column and the header menu), sort and row-height intents, frozen fields, fit a column to its content, your own header-menu items.
  - **Group by:** collapsible group headers with counts and per-group summaries, group add rows, keys, paste and fill across groups (`groupRecords` for local data).
  - **Rows:** drag to reorder (`@canMove`, a change set with `moves`), row colours (`@rowColor`) and cell colours (`@cellColor`).
  - **Data at scale:** load more as you scroll (`@onVisibleRangeChange`), the current search match (`@currentMatch`, `findMatches`), the selection for summaries (`@onSelectionChange`, `summarizeCells`).
  - **Import and export:** `toCsv`, `parseCsv`, `importMatrix`, `api.appendRows`, and an import screen (`EuiSheetImport`) that reads a file, maps its columns to fields, guesses types, previews errors and can create fields.
  - **Errors and validation:** cell errors (a text a type cannot read is kept and shown, not saved), `@validate` for record, cross-row and async rules.
  - **Also:** full screen, touch selection handles and IME input, messages through `eui-i18n`, light and dark themes.
