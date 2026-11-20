# 05. Copy with field names

## Why

To paste rows into a report or an email with the column names on top.
AG Grid has `copyHeadersToClipboard` (`../FEATURE-RESEARCH.md` row 5).

## API

- A row-menu item, "Copy with field names" (`messages.copyWithFieldNames`),
  placed next to "Copy".
- No shortcut. Ctrl/Cmd+Shift+C opens Chrome's element inspector, so it is
  not available.

## Behaviour

- It copies what the menu's "Copy" copies: whole rows (every visible
  field), the checked rows when any are checked, else the selected rows
  (`rowsTsv`, `eui-sheet.gts:2654`). A cell range is copied with Ctrl/Cmd+C
  as today, without names.
- The first line is every visible field's label (`label ?? id`), in
  display order. The rest is exactly what "Copy" gives.
- It is written with the same `writeClipboard` that the row menu's copy
  uses (`eui-sheet.gts:2648`).
- A paste of that text back into the sheet pastes the label line as a row,
  like any text. `importMatrix` (07) is the way to read a header line.

## Code

- `core/tsv.ts`: `headerLine(fields)`, which returns `string[]`. About
  5 lines.
- The row-menu module: the item, and a `copyWithNames` next to today's
  `copyRows`. It prepends `headerLine` to the matrix. About 20 lines.

## Tests (`eui-sheet-copy-names-test.gts`)

- **CN1:** from the menu on one selected row, the clipboard holds every
  visible field's label, then that row.
- **CN2:** with two checked rows, it holds the labels, then those two
  rows, in order.
- **CN3:** a label with a tab is quoted, like any cell.

## Docs

The "Records" section's menu list.

## Risks

None known.
