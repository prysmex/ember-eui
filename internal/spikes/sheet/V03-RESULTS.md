# `@ember-eui/sheet` v0.3: results

Results of the batches of `V03-DESIGN.md`, on branch `feat/sheet`. Each
section says what was built, what was verified (and how), and what was not.

## Batch 1: add row, column drag, header wrap, shortcut list

Built 2026-11-19 on `5f659546` (uncommitted when this was written), in a
scratch copy of the repository. Scope: V03-DESIGN.md section 5, plus the
selection and feedback items the user asked for during the batch (range
feedback, the active cell at the anchor, the visibility pass), each in its
own section below. Baseline before any change: 335/335 tests pass. After:
**381/381**, three full runs in a row (`pnpm lint` clean, `prettier
--check` clean, the tests' `ember-tsc` has the same 19 errors as the
baseline, `docs:api:check` passes). `packages/core/src` is unchanged
(`diff -rq` against the repository).

Screenshots (headless Chromium, the built docs site): `v03-b1/light-*.png`
and `v03-b1/dark-*.png` next to this file. d01's dark shots use its Dark
switch; the others the site's dark theme.

### The add row: causes seen in Chromium (5.2)

Reproduced on the built docs site (d01, its Dark switch, headless Chromium
through CDP, real `Input.dispatchMouseEvent` hover), computed styles read
with `getComputedStyle` on each cell of `.euiSheet__addRow` and on its
`::before` / `::after`. Nothing frozen in d01.

| Seen | Computed cause |
| --- | --- |
| Two plus signs | As the design says: `.euiSheet__rowAdd` in the row-number cell and an `EuiIcon` inside `[data-test-subj=euiSheetAddRecord]`. |
| The row-number plus at the top left | Its `[data-datagrid-cellcontent]` (`.euiDataGridRowCell__content`) is `display:flex; justify-content:space-between` (sheet) and only 24 px high (the grid's control-column content, `max-height:100%`, not `height:100%`) at the top of a 35 px wrapper: the plus box was at (296, 578) in a cell whose centre is (321, 590). |
| Two backgrounds at rest | The row-number cell has `background-color` `--euiSheet-subdued` (dark `rgb(11, 22, 40)`, light `rgb(246, 249, 252)`). The data cells are transparent and show the row's own background, the grid's (dark `rgb(17, 28, 44)`, light white = `--euiSheet-plain`). |
| On hover | `.euiSheet .euiDataGridRow:hover .euiDataGridRowCell` sets every cell, the row-number cell included, to the translucent `--euiSheet-hover` (dark `rgba(255, 255, 255, 0.08)`, light `rgba(23, 80, 186, 0.04)`) over the row's background, so in this headless run the row was one tone on hover; the two tones are at rest. With a frozen field the frozen hover rule paints `--euiSheetFrozenBase` (subdued for the row-number cell, plain for a data cell) under the tint, so the two tones stay on hover (read from `styles.ts`, not seen: d01 has no frozen field; AR3 covers it in a test). |
| Column dividers | The grid's cell borders (`euiDataGrid--bordersAll`): every cell has `border-right: 1px solid` (dark `rgb(43, 57, 79)`, light `rgb(227, 232, 242)`) and `border-bottom` the same; the first column (the row-number cell) also has `border-left`, which is the grid's outer left edge. |
| Pale grey box on the cell under the mouse | The grid's own cell outline, not the sheet's: `euiDataGridCellOutlineStyles` (core `styles.generated/shared/VRGXM52Z.ts`) draws a `::after` (`position:absolute; inset:0; z-index:2; border: 2px solid`) on `.euiDataGridRowCell:is(:hover, :focus, .euiDataGridRowCell--open, …)`, coloured `euiTheme.components.dataGridRowBorderHover` on `:hover:not(:focus, :focus-within, .euiDataGridRowCell--open)` (dark `rgb(142, 159, 188)`, light `rgb(90, 109, 140)`). It shows on every hovered cell of every row, ordinary rows included. |
| Focus | Two rings on top of each other: the sheet's `outline: 2px solid --euiSheet-primary; outline-offset:-2px` and the same grid `::after`, coloured `dataGridRowBorderActive` (the same blue as `--euiSheet-primary` in both themes). |
| Focus ring under the keyboard | Found while writing AR6: the grid's `:is(:hover, :focus, …):focus-visible { outline: none }` (specificity 0,3,0, inserted after the sheet's style) beats the sheet's `.euiSheet .euiDataGridRowCell:focus` outline (0,3,0). Under keyboard focus (and programmatic focus, as in tests) the only ring on any cell is the grid's `::after`; the sheet's outline shows only after a pointer focus. On ordinary cells both are the same blue, so nothing looks wrong there; on the add row, whose `::after` is removed, the sheet's outline needed a stronger selector; the 3 px active ring (below) now uses one everywhere. |

How each was fixed (`src/-private/styles.ts`, the add-row block after the
frozen rules): every cell of `.euiSheet__addRow` gets `--euiSheet-plain`
as its background (and as `--euiSheetFrozenBase`, so frozen add-row cells
match), hover is a `linear-gradient` of `--euiSheet-hover` over it (the
background colour is re-asserted, since the general row-hover rule is more
specific than the design's sketch), the inner dividers are
`border-inline-end-color: transparent` on every cell but the last column
(**deviation from AR5 as written:** the grid frame's two outer edges, the
first cell's left border and the last cell's right border, stay; without
them the frame has a notch at the add row), the grid's `::after` is
removed on the row (`content: none`), the focus ring there uses a stronger
selector, and the row-number plus is centred with `justify-content:center;
height:100%` (the sketch's `justify-content` alone left it at the top).
`--euiSheet-plain` in dark is `rgb(17, 28, 44)`, the same as the grid's
row background, so the add row matches the record rows.

**Discrepancy to note:** the caller saw the row-number cell keep its darker
background on hover with nothing frozen; in this headless run (pointer on
the third cell, and on the row-number cell) the hover rule made every cell
the same translucent tint. At rest the two tones were there in both runs.
Fixed either way; hover is in the real-input list.

### Column drag (5.3) and the CD6 gate

`fieldDrag` (`@fieldDrag ?? true`, and more than one visible field) is
passed as `columnVisibility.canDragAndDropColumns`. `setVisibleColumns`
puts the current first field back in front of what the grid sent (a drop
before it puts the dragged field second; a drag of the first field is a
no-op, not emitted) and, after the next render (`next`), bumps
`orderEpoch` when the visible order is not the one the grid sent (a no-op
or an owner that ignores the intent): `columns` reads it, so the grid gets
a new array and drops its stale order state. Resized widths are also kept
in a plain `keptWidths` map (X6), used by `columns` (as `initialWidth`) and
by `frozenWidth` when `@fieldWidths` and `field.width` give none, only
without `@onFieldWidthChange` (with it the sheet shows exactly
`@fieldWidths`; VW8 checks a dropped width is not kept). `EuiSheetSearch`
forwards `@fieldDrag` and `@headerLines`. A
`dragstart` in the sheet saves an open editor (CD9).

With only `canDragAndDropColumns` added, 5 of 335 tests failed: FZ3 and
FZ12 (the frozen header conflict the design predicted), FZ5 and VW8 (they
looked for the resizer inside the header cell; with drag on it is the
cell's sibling, X2) and LK1 (see "Existing tests changed").

**CD6 gate: passed, no fallback.** `styles.ts` makes the draggable wrapper
sticky with `:has(.euiSheet__frozenHeader)`, its `left` from the same
per-index custom property (`frozenHeaderLefts()` now emits both rules), and
gives the droppable, the wrapper and its item `background-color: inherit`
so the sticky header stays opaque (the cell's `inherit` would otherwise
inherit transparent). FZ3, FZ5 and FZ12 pass with drag on, and CD6 (in
`eui-sheet-frozen-test.gts`, which has the wide setup) checks the wrapper
is sticky, keeps its `left` after a horizontal scroll, paints over the
scrolled headers and has an opaque background.

Not changeable without core: the grid's `autoScrollForElements` logs
"Auto scrolling has been attached to an element that appears not to be
scrollable" (pragmatic-drag-and-drop, development builds) for a sheet that
is not scrollable; it shows in every test's browser log with drag on.

### Header lines (5.4)

`@headerLines` 2 or 3 adds `euiSheet--headerLines2|3`. The grid's
`euiTextTruncate` sets `white-space: nowrap !important`, so the rule needs
`white-space: normal !important` (found by HW1 failing); then
`-webkit-line-clamp` 2 or 3. The header row grows (the grid measures it)
and the body follows. The first field's description icon wraps with it.

### Shortcut list (5.5)

Ctrl/Cmd+/ (also with Shift: `/` is Shift+7 on Spanish layouts; not `?`,
D11) on a cell, a row number or a header, with no editor open, opens
`src/-private/shortcut-list.gts`: an `EuiModal` with the sheet's theme
class, one table per section of `src/-private/shortcuts.ts`, rows of
features that are off left out (`@readOnly`, `@canInsert`, row numbers,
column drag). 59 new `SheetMessages` keys (sections, rows, key names, "or",
"Right-click, long press", and `noRecords`). `Mod` is ⌘ on Apple platforms.
`api.showShortcuts()` and the block's `showShortcuts()` open it; Escape
closes it and the modal's focus trap returns focus to the cell (KH1).
d18 has a "Shortcuts" toolbar button.

### Range feedback (user's request during the batch)

- The selected tint now wins over the row hover (the caller's patch,
  applied by hand: its third hunk's context had moved), so a range dragged
  within one row shows while it is dragged.
- **Range outline**: `src/-private/range-outline.gts`, drawn beside the
  grid like the fill handle and placed by `placeRangeOutline` (the union
  of the range's rendered cells; a side whose row or column is not
  rendered is put past the clip), in a box clipped to the body's visible
  area (right of the frozen columns when the range has none of them).
  **3 px** `--euiSheet-primary`, inside the range's box (border-box), no
  pointer events, hidden for one cell, while editing, and when the range
  is out of view. It follows drags, scrolls, column changes, resizes.
- **Active cell ring**: 3 px, offset −3 (inside the cell), with a selector
  that beats the grid's `:focus-visible { outline: none }`, and the grid's
  own `::after` ring is made transparent on the focused cell. On a range's
  edge the active ring and the outline cover the same 3 px band. Inside a
  range of more than one cell (`euiSheet--ranged`) the active cell keeps the
  plain background. A focused invalid cell keeps its error line just
  inside the ring (`inset 0 0 0 4px` danger).
- **Range tint**: `--euiSheet-selected` is now the primary at 12 % (light)
  / 20 % (dark). Borealis' `backgroundLightPrimary` is the same token as
  `backgroundBaseInteractiveSelect` in dark, so it was not stronger. From
  the 3×4 screenshots: text and checkboxes stay readable, it is clearly
  not the hover, and the plain active cell stands out. Kept. (d01 has no
  badges; badges on the tint were not looked at.)
- **Fill handle**: a 10 px square in a 2 px `--euiSheet-plain` ring (14 px
  drawn, `FILL_HANDLE_SIZE`), centred on the range's corner (the outline's
  outer corner), a 16 px `::before` hit area, `scale(1.2)` on hover,
  `z-index: 4` (above the outline's 3). Coarse pointers still hide it.
- **Header and row-number marks**: the selection's column headers get a
  rule written into the sheet's own `<style data-eui-sheet-marks>` (scoped
  by `data-eui-sheet-id`; the grid's header cells take no class from the
  sheet, and a class through `displayHeaderCellProps` would rebuild the
  columns and drop widths). Whole columns: the selection tint as an image
  over the header's background (frozen headers stay opaque), a 3 px bottom
  bar, the title in primary. A cell range (one cell included): a hover-
  strength tint and the title in primary. Row numbers: `--marked` (light,
  primary text) for a cell range's rows, `--selected` rows get the tint
  and a 3 px bar on the inner edge.
- **Checked rows**: `euiSheet__cell--checked` from `SheetCell` and the
  row number's `--checked` give a light tint (`--euiSheet-checked`, primary
  at 6 % / 10 %) and the row number the selection tint; frozen cells draw
  it as an image; a range over a checked row shows the range look.
- **Open editor**: the cell (and long-text) editor is lifted up to 2 px past
  its cell on each side, clamped where the body's visible area ends (the
  header, the frozen edge, the scroll bars; `growOf`), with a 3 px ring,
  2 px radius and `--euiSheet-elevation` (the theme's shadow at 25 % / 60 %)
  as a shadow; the padding keeps the text where the cell's text was (EG1).
  Inline and panel editors are unchanged. The range outline and the fill
  handle are hidden while editing.
- **Header menu trigger**: the grid draws it as `ellipsis` with no public
  way to choose the icon, so it stays (a chevron would need a core change).
  The sheet's CSS gives it the text colour, a 16 px icon and a 4 px-radius
  hover background, shows it always on the active cell's column and on
  selected columns (in the marks rule) and on coarse pointers. A right-
  click (or long press) on a header opens its menu (it clicks the header's
  own button). With column drag the drag icon is at the left of the title
  and the trigger at the right: no crowding at 150 px. Narrow columns and
  `@headerLines` 2 with the trigger were not looked at (real-input list).

### The active cell stays at the anchor (user's decision)

Focus (the ring) stays on the anchor through a drag, Shift+click,
Shift+arrows, Shift+Home/End, Shift+PageUp/PageDown and Shift+Ctrl/Cmd
jumps; only `head` moves (`extendHead`), and it is scrolled fully into the
body's visible area without a focus move (`revealCell`: `scrollToItem` to
bring it near, then an exact scroll once it is rendered; `scrollToItem`
alone left it under the bottom edge). Shift+click prevents the press's
focus move. A drag's release no longer focuses the head. Targets are
computed from the head; without Shift, from the active cell. Escape
collapses to the active cell (after ending a copy mark). A plain press on
the active cell inside a range collapses it and does not edit (a second
click edits). When records are replaced, the selection follows the active
cell's record (it was the head's).

When the scroll unmounts the focused anchor, focus would fall to the page
(Chromium fires `focusout` on the removal, no `relatedTarget`). The sheet
then parks focus on the grid's body element (`[role=grid]`, `parkFocus`),
or on the re-created cell when the grid rendered it again without
focusing it; keys pressed while parked act on the range
(`onParkedKeyDown`: the extending keys, Delete, the command keys, copy,
cut and paste; any other key brings the active cell back first, Escape
also collapses). The grid focuses the cell itself when it is rendered
again. `'rows'` ranges: a row drag's release focuses the anchor row's
number; Shift+ArrowUp/Down on row numbers still moves focus with the head
(left as it was). `'columns'` ranges are unchanged.

### Visibility pass

Done:

1. Row menu: lines between its groups (insert | duplicate, expand, open
   link | copy, the app's actions | delete), the theme's elevation shadow
   and a hairline border in both themes; the right-clicked cell is
   selected (a single cell: tint only, the ring is in the menu). No new
   trigger; the shortcut list lists Right-click and Shift+F10 for the row
   and header menus, and `docs/sheet.md` says so.
2. Row-number hover icons: the expand icon in `--euiSheet-text` with a
   4 px-radius hover background (primary on hover), the checkbox border
   1.5 px, primary on hover; both already had a `title`.
3. Copy feedback: after a copy or a cut the copied range has a 2 px dashed
   outline (the same overlay, `kind="copied"`) until Escape, a change, the
   next copy, or the owner replacing `@records`.
4. Paste / fill / undo / redo flash: the changed cells' bounding range gets
   a fading tint for 600 ms (a plain `setTimeout`, so `settled()` does not
   wait for it); with `prefers-reduced-motion` nothing is drawn. Inserts
   only (rows the owner has not added yet) flash nothing.
5. Fill drag preview: there was a 1 px dashed outline per cell; the target
   area now also gets one 2 px dashed outline (`kind="fill"`).
11. Empty state: with no records and not `@isLoading`, "No records" under
   the grid (`noRecords`, a status region); when inserting is allowed the
   add row above it stays the action (no second button). An `<:empty>`
   block replaces the message (not forwarded by `EmberSearchUi`'s
   `EuiSheetSearch`). Under the grid, not over its body: without `@height`
   the body has no room for an overlay. The connector passes its
   `isLoading`, so nothing shows during its first load; with no results
   it shows the same message (read from the code, not run). No
   screenshot: no demo has an empty sheet.

Not done (to keep the batch reviewable, as the caller allowed): 6 (file
drop target look), 7 (read-only cue; invalid and pending looked readable
in the screenshots next to the new ring and tint), 8 (keyboard ring on
headers: row-number cells already get the 3 px ring, the header keeps the
grid's), 9 (checkbox, rating and link contrast in dark: only the checkbox
border was thickened), 10 ("Re-apply" and the loading bar).

### Files

Under `packages/sheet/`:

| File | Change |
| --- | --- |
| `src/components/eui-sheet.gts` | `fieldDrag`, `headerLinesClass`, first-field rule and `orderEpoch` in `setVisibleColumns`, `keptWidths`, `dragstart` commit; Ctrl/Cmd+/, `showShortcuts` (API and block), `shortcutContext`; range outline, header marks (`headerMarkCss`, `sheetId`), `isRowMarked`; the anchor rule (`extendHead`, `revealCell`, `parkFocus`, `onParkedKeyDown`, Shift+click, release, Escape, press on the active cell, `followRecords` on the active cell); editor `growOf`; header right-click; copy mark, flash, fill outline, empty state |
| `src/-private/styles.ts` | add row, sticky drag wrappers, header lines, shortcut list, range outline and variants, active ring, tints, checked rows, marks (`headerMarkRules`), fill handle, editor, header trigger, row menu, row-number icons, empty state |
| `src/-private/theme.ts` | `--euiSheet-selected` (primary 12 % / 20 %), new `--euiSheet-checked`, `--euiSheet-elevation` |
| `src/-private/sheet-cell.gts` | the plus only without row numbers; `--checked` |
| `src/-private/row-number-cell.gts` | `--marked` |
| `src/-private/editor-frame.gts` | `@grow` |
| `src/-private/row-menu.gts` | group separators |
| `src/-private/range-outline.gts`, `shortcuts.ts`, `shortcut-list.gts` | new |
| `src/core/messages.ts` | 59 keys |
| `src/types.ts` | `fieldDrag`, `headerLines`, `SheetApi.showShortcuts`, block `showShortcuts`, `<:empty>` block |
| `src/search-ui/eui-sheet-search.gts` | forwards `@fieldDrag`, `@headerLines` |
| `tests/helpers/sheet.ts` | `resizerOf` |
| `tests/integration/components/*` | below |
| `docs/sheet.md`, `docs/sheet-demo/d12-view-intents.md`, `d18-editing.md`, `README.md` | arguments, presentation, keyboard, mouse, API |

### Tests

New (46): AR1-AR8 (rows), CD1-CD5, CD7-CD9, HW1/HW2 (×2), HW3, HM1, MT1/MT2,
MT3, EG1, EM2 (view), CD6 (frozen), KH1-KH4, RF1 (×2), RF2, FH1, AN5, AC1,
VP2, VP3 (polish), AN1-AN4 (ranges), HM2/HM3, HM4, CK1, VP1, EM1 (rows).

Existing tests changed, and why:

| Test | Change |
| --- | --- |
| FZ5, VW8 | The resizer is found with `resizerOf` (with drag on it is the header cell's sibling, X2). |
| VW8 | Last assertion inverted: a bare sheet now keeps a resized width when the columns change (X6). Added: with the handler a width dropped from `@fieldWidths` is not kept. |
| LK1 | Focus first goes to `cell(0, 8)`, not `cell(0, 0)`: after the clicks on columns 9-11 the grid is scrolled, and with drag on its column virtualization had already dropped the first field (it did not before, a timing difference; the window it rendered is the correct one for that scroll). |
| R1, T4, FZ12, P1, P6, P10 | Focus is on the anchor after a drag or Shift+keys, not the head. T4: a plain ArrowDown then moves from the anchor. |
| P5, P7 | Wait for the head's selection rather than the focus; a plain Ctrl+ArrowUp / PageUp now moves from the active cell (149 → 0, as in Excel), not from the head. P7 also waits for focus to settle after the scroll. |
| T7 | Focus is held by the grid's body while the active cell is unmounted (was: the page), and returns to the anchor cell `(2, 0)`. |
| T20, T24 | The selection follows the active cell's record (r0), not the head's. |
| FZ6, T11, VW9 | The editor box may be up to 2 px larger than its cell on each side. |

### For real-input checking (Mac, real mouse and keyboard)

- Hover the add row: one tone across the row, frozen field on and off,
  light and dark; no grey box; the ring on its cells.
- Drag a header with a mouse: drop between columns, before the first
  field, on itself; auto-scroll near the edges; with the frozen field (the
  frozen header must stay put); narrow columns (the drag icon and the
  trigger next to the label); a click on a title still selects the column.
- `@headerLines={{2}}` with long labels in d12 (narrow a column).
- Ctrl/Cmd+/ on a Mac (⌘) and on a Spanish layout; the list in dark.
- Ranges: drag in one row (the tint and outline while dragging), drag past
  the edge with auto-scroll (the view jumps back to the anchor at the
  release: the grid scrolls the pressed cell into view on pointerup),
  Shift+click, Shift+arrows past the view and back (focus parked, then the
  anchor refocused), Escape, typing after a drag.
- The fill handle: grab it (16 px hit area), hover growth, light/dark,
  frozen, scrolled; the dashed target area while dragging.
- The open editor's lift and shadow, at the grid's edges and the frozen
  edge, light and dark; long text.
- Header marks and the menu trigger: hover, the active column, a selected
  column; right-click on a header; a touch screen (always shown).
- Checked rows next to a range; the row menu's look in dark; the copy
  mark and the flash after a paste, fill, undo; reduced motion.
- The empty state in d09 or an empty search in d14.

### Open issues

- The grid's grey hover box (`::after`, `dataGridRowBorderHover`) still
  shows on every hovered cell of ordinary rows (removed on the add row
  only). Decide whether the sheet should hide it everywhere.
- The menu trigger stays the grid's `ellipsis` (no public API for the icon).
- The right-clicked single cell is marked only by the tint while its menu
  is open (focus is in the menu).
- With drag on, the dev-only auto-scroll warning (above).

### Batch 1: real input in Chromium (main session, 2026-11-19)

Checked on the docs site (`vite preview` of a production build), with a real
mouse and keyboard, light and dark (d01's Dark switch):

- Drag across row 1: the tint, the 3 px range outline and the column/row
  marks show during the drag; focus stays on the anchor after the release and
  after Shift+ArrowDown ×2 (3×4 range). Copy, then paste elsewhere: the pasted
  cells flash.
- Add row in dark: one centred plus, one background at rest and on hover, no
  inner dividers, no grid hover box.
- Column drag with the mouse: "Hours" dropped before "City" reorders the
  columns. Header menu trigger shows on the active and selected columns.
- Ctrl+/ on a selected cell opens the shortcut list.

Fixed during the check (tests 381/381 after them, lint clean):

1. **The grid's grey hover box on every cell** (the open decision of the
   batch): hidden everywhere, `.euiSheet .euiDataGrid .euiDataGridRow
   .euiDataGridRowCell::after { content: none; }`. The active ring and the
   range outline show where you are, as in Airtable.
2. **The copy mark was invisible while the copied range stayed selected**: it
   was drawn exactly under the 3 px range outline. It is now an outline 6 px
   inside the range box (`outline-offset: -6px`), above it. VP2 checks
   `outlineStyle` instead of `borderTopStyle`.
3. **The fill handle was cut off** when the range touched the body's right or
   bottom edge: `placeFillHandle` moves it in so it is whole.
4. **The open editor looked thinner than the active ring**: the global
   `:focus-visible` outline (2 px, light blue) was drawn over its 3 px border.
   `.euiSheet__input:focus(-visible)` and the textarea now have no outline.
5. **Right-click on a header opened the menu and closed it at once**: on
   Linux and macOS `contextmenu` fires on the press, and the release closed
   the popover as an outside click. The sheet now opens it after the right
   button's release (or after 1 s if no release comes). MT3 still passes.
6. The shortcut list's sections use one fixed key column (45 %), so the
   descriptions line up across sections.

Not checked here: Firefox, Safari, touch, a Mac keyboard (⌘/), a Spanish
layout, reduced motion.
