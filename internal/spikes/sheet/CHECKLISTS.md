# `@ember-eui/sheet`: checklists for real devices

READINESS.md "On the user's devices". Each list runs in a sitting; each
item is **do → expect**. Write down the item number of anything that
does not match, with the browser and device.

**Where:** the production docs build of `feat/sheet`. Paths below are
under `/docs/sheet/docs/sheet/` (written `…/`), e.g. `…/editing` is
`https://<host>/docs/sheet/docs/sheet/editing`. Until the branch is
deployed, use a Vercel preview of it; for a phone a `vite preview` on
the LAN also works, except the camera (list 2, item 9), which needs
HTTPS. "Mod" is Cmd on a Mac, Ctrl elsewhere.

## 1. Safari and Firefox on a Mac (about 30 min per browser)

1. `…/editing`: click a cell, type `abc`, Enter → the editor opens with
   `abc`, Enter saves and moves down. Escape while editing → the old value.
   Tab/Shift+Tab → right/left. Arrows, Home/End, Mod+Home/End → move.
2. Same page: select 2 × 2 cells, Mod+C, open TextEdit, paste → two
   tab-separated lines. Copy 3 lines × 2 columns from Numbers or a text
   file, click a cell, Mod+V → the block is written; Mod+Z → undone in
   one step; Mod+Shift+Z → redone.
3. Mouse-drag across cells → a blue range follows the mouse; drag past
   the bottom edge → the grid scrolls.
4. `…/selection/fill-handle`: drag the small square at the range's
   corner down 5 rows → values (or a series, 1, 2 → 3, 4, 5) fill in.
5. `…/rows/drag`: drag a row by its grip (hover the row number) → a
   drop line follows, the row lands there. `…/fields/columns`: drag a
   header → the column moves.
6. `…/fields/columns` (frozen example) and `…/data/large-sheet` with
   "Freeze the first field" on: scroll right and down with the trackpad →
   the frozen columns and the header stay put, no gap or overlap,
   nothing flickers.
7. `…/rows/expanded-record`: click a row's expand icon → the record
   opens; edit a field → the grid shows it; Escape → closed, focus back
   on the cell.
8. `…/more/full-screen`: Full screen on → the sheet fills the window;
   Escape → back.
9. `…/field-types/dates`: open a date and a date-time cell → the
   browser's picker; pick a value → saved and shown in the field's
   format; type a date by hand → read the same way.
10. `…/field-types/attachments`: drop a file on a cell, and use the
    picker → a progress bar, then the file's chip; remove it → gone.
11. `…/import-export/import-screen`: choose a CSV of a few hundred lines
    → the preview and counts ("N lines ready") within about a second;
    map a column, Import → the records are added; undo removes them.
12. `…/example-app`: two-digit and larger row numbers are whole, beside
    the checkbox (on hover) and the expand icon; light and dark (the
    header's theme switch).

## 2. iPhone (Safari) and Android phone (Chrome) (about 30 min per phone)

Hold the phone upright (a sheet under 600 px wide).

1. `…/example-app`: the row-number column shows every number whole
   (`10`, `11`, … not `1..`), with a gap before the checkbox and the
   expand icon. On `…/data/large-sheet`, scroll to the end → `10000` is
   whole too. Dark mode (theme switch) → the same.
2. `…/selection/touch`: tap a cell → it is selected and two round
   handles show at its corners; a drag on the grid scrolls (no
   selection).
3. Drag the bottom-right handle down and right → the range grows; drag
   it to the grid's edge → the grid scrolls; drag the top-left handle →
   the other corner moves.
4. Tap a text cell that is already selected → the expanded record opens
   with that field's editor; type, close → saved in the grid.
5. Tap a **select** cell (`…/field-types/selects`) → the expanded record
   opens with the field's picker (this is intended); pick an option →
   saved.
6. Long press a range → a menu with Copy and Paste; Copy, then long
   press another cell, Paste → the text is written (the browser may ask
   permission once). Long press a cell or a row number → the row menu.
7. Scroll fast up, down and sideways on `…/data/large-sheet` → smooth,
   no blank rows staying blank, the header stays on top.
8. Editors on `…/field-types` pages: number (numeric keyboard),
   date and date-time (native wheels / calendar), multi-select, rating,
   checkbox → each saves; the keyboard does not cover the field being
   edited.
9. **Android Chrome only**, `…/field-types` ("More field types", SKU,
   over HTTPS): tap the camera icon of an SKU cell → the rear camera
   opens; show a product barcode (EAN-13) → the code is saved and the
   camera stops; Cancel → stops without saving. (The Barcode page's own
   example uses a stand-in scanner on purpose.) On iPhone: no camera
   icon, typing works.
10. `…/field-types/attachments`: upload a photo from the gallery and from
    the camera → a progress bar, then the chip; the grid stays usable
    meanwhile.
11. The row checkbox and the expand icon are always visible and easy to
    hit; the fill handle (small square) never shows on the phone.

## 3. Screen readers (about 45 min)

VoiceOver on the Mac (Safari; Cmd+F5) and NVDA on Windows (Firefox or
Chrome). Arrow keys inside the grid (VoiceOver: interact with the grid,
VO+Shift+↓, or use plain arrows after focusing a cell).

1. `…/editing`: Tab into the sheet → the grid's name ("People") and the
   first header; arrows → each cell with its column header.
   `…/editing/read-only`: a locked cell → "read only".
2. A row number → "Row 3"; Space → "Row 3, checked" (VoiceOver may need a
   move away and back).
3. The row-number header (Tab into the sheet, or Mod+Home, ArrowLeft,
   ArrowUp) → "Row number, Select all rows"; Space → every row checked, the
   header says "All rows checked"; Enter → none again. Check one row
   first → the header says "Some rows checked".
4. A row number on `…/data/large-sheet`: PageDown, PageUp → focus moves
   a page in the row-number column and is read (not lost to the page).
5. Edit a cell (Enter, type, Enter) → the editor is read with the field's
   name; then the next cell. Clear a required Name and Enter → "Name:
   Required" announced **once** (not twice with the cell's error box).
6. The live region (a polite status), on `…/editing`: copy two cells,
   paste → "2 cells pasted"; Mod+Z → "Undone"; Mod+Shift+Z → "Redone";
   type `abc` in a number cell → '"abc" is not a number'; paste 3
   unreadable values → "3 values could not be read".
7. `…/validation/field-rules`: move onto an invalid cell → its value,
   "invalid", and its message: once or twice?
8. Shift+F10 on a cell → "Row menu", items read as menu items, arrows
   move, Escape → back on the cell.
9. Space on a cell → the expanded record, read as a dialog with the
   record's title; each field as label and value; Escape → back on the
   cell. Paste or undo inside it → is the live region heard from inside
   the modal?
10. A header: Enter → the column menu, read as a dialog named by the
    column; Escape → where does focus land? (known core issue: `<body>`.)
11. `…/fields`, the "+" header: Enter → "Add field" dialog; delete a
    field → its question is read.
12. Mod+/ → the shortcut list: its tables and captions read; the arrows
    scroll the list.
13. `…/import-export/import-screen`, choose a file → "Checking the lines…"
    then the totals announced (despite `aria-busy`)?
14. A range of cells (Shift+arrows) → NVDA says "selected" on the
    range's cells and nothing noisy on the others?

## 4. Prysmex (one real screen, about half a day)

1. Pick one screen that is a table people edit today (many rows,
   a few field types, a save to the server). Replace its table with
   `<EuiSheet>`: `@records`, `@fields`, `@getRecordId`, `@onChange` that
   sends the change set to the API; `@cellErrors` from the server's
   refusals.
2. Use it for real work for a day: editing, paste from Excel, undo,
   the expanded record, on a desktop and a phone.
3. Report back, for each problem: what you did, what you expected, what
   happened (a screenshot), browser/device, and the field types and
   record count. Also: how long the integration took, which arguments
   you needed that the docs did not lead you to, any message text you
   had to translate or reword, anything slow (with the record count),
   and anything you had to work around in your own code.

## Known issues and decisions left

- **Dark, a checked row under the mouse:** danger text 4.10:1 and links
  4.42:1 on the hover tint over the checked tint (under 4.5:1 while the
  mouse is on the row; a dark checked tint low enough to pass would hardly
  show). Decide: accept, or a darker hover on checked rows.
- **Core (reported, not changed):** Escape in a column (field) menu
  leaves focus on `<body>` (also on core's own data grid page);
  `aria-rowcount` leaves out the header and footer rows and the first
  body row is `aria-rowindex=1`; axe `scrollable-region-focusable` on the
  grid scroller (not a barrier: Tab reaches the grid); EuiSelectable's
  active option in dark 4.41:1 (the select editor); EuiPagination's "…"
  colour.
- **The import screen's open time:** 245-261 ms warm against the 300 ms
  target on this sandbox, two of seven earlier rounds over 300; 350 ms
  would be the safe target. Putting each column's options behind a button
  is blocked by existing tests (they use the options without an opening
  click): allow that, or keep the target.
- **44 of the 52 docs pages have one example** (asked: 2-4 each). More
  examples per page, or merging small pages (the per-type field pages)?
- **The row-number column is wider:** it now fits the last record's
  number beside the checkbox and the expand icon (one width for mouse and
  touch): 64 px up to 9 records, 73 px for 10-99, 102 px for 10,000.
- **Left in the sheet:** no `aria-selected="false"` on unselected cells
  (on purpose: NVDA noise); a group header's `aria-expanded` on a
  gridcell; the expanded record's read-only boxes keep `aria-labelledby`
  on a plain `div` (a `role=group` breaks RF7's assertion); no warning
  level for messages (a validation message never blocks but an unreadable
  text).
- **Not tried anywhere yet:** real IMEs and dead keys on macOS, the
  StackBlitz playgrounds, Vercel's handling of slashless group URLs.
