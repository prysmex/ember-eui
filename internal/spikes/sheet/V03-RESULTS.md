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

## Batch 2: field management

Built 2026-11-19 on `8e5305fc` (batch 1 committed), in a scratch copy of
the repository. Scope: V03-DESIGN.md section 6, then the "Visibility pass,
part 2" the user asked for once the main scope was green (its own section
below). Baseline before any change: 381/381. After: **415/415**: 381 + 34 new
(FC1-FC6, LF1-LF3, H11-H12, FM1-FM20, VP4-VP6). Of the last three full
runs two passed and one failed only P7 (a `waitUntil` timeout; P7 also
failed in several of batch 1's own runs, before this batch)
(`pnpm lint` clean, `prettier --check` clean on the changed files and
README, the tests' `ember-tsc` has the baseline's 19 errors,
`docs:api:check` passes). `packages/core/src` is unchanged (`diff -rq`
against the repository).

Screenshots (headless Chromium through CDP, the built docs site, the
site's light and dark themes): `v03-b2/light-*.png` and `v03-b2/dark-*.png`
next to this file. `*-editor-edit-warning.png` were taken before the
panel's height was clamped: the demo's frame cuts the panel there (it now
scrolls inside the wrapper, as `*-editor-select.png` shows).

### What was built

- **Core** (`src/core`): `SheetFieldDraft` and `EuiSheetField.manageable`
  (`types.ts`); `convertField` (`convert.ts`, new): per record the old
  type's copy text through the new type's `parse` with `source: 'paste'`;
  a value is a patch (none when equal), an error or unresolved text is a
  patch to the new type's empty value plus a `rejected` entry, created
  options are collected once in `newOptions`, empty values give nothing.
  Its change set has `source: 'paste'`. `withoutField(entry, fieldId)`
  (`history.ts`): drops the field from patches, inserts' values,
  rejections and new options; `null` when nothing is left (deletes keep
  an entry). 53 message keys, and `cellReadOnly` from the visibility
  pass (below).
- **`localRecords`**: bound `createField` (slug id made unique, placed
  after `position.after` when it is in `fields`, else at `index`; with
  `copyOf` the values are copied), `updateField` (`{ ...field, ...draft }`;
  on a type change it applies `convertField`, adds the created options and
  pushes the change set to `log`) and `deleteField` (the field and the key
  in every record). New options `types` and `messages` (the conversion's
  registry and texts; default the built-ins and English).
- **The "+" column** (W8): a trailing control column
  `euiSheet-addField`, 40 px, only with `@onFieldCreate`. Its header is a
  span with a plus and a screen-reader label; a click, Enter or Space
  opens the editor to create at the end. The three control blocks switch
  on `columnId` (the row-number components are not rendered in it).
  `headerCell()` excludes it; `addFieldHeader()` / `addFieldCell()` find
  it. Its body cells are empty; a focus on one (a click, ArrowDown from
  its header) moves to the row's last field (the 6.12 fallback, taken at
  once: an inert focused cell that swallows typing looked worse than the
  redirect). ArrowRight on the last field is stopped, End and Ctrl/Cmd+End
  land on the last field (also from a row number). `overscanColumnCount`
  counts it.
- **Header menu items** (`fieldMenuItems`, after "Filter by this field"):
  Edit field, Duplicate field, Insert left (not on the first field),
  Insert right, Delete field (not on the first field), each only with its
  handler; Edit, Duplicate and Delete not with `manageable: false`. They
  run in `next()`, after the popover closed and returned focus to its
  button. Duplicate calls `@onFieldCreate` at once with the field's draft,
  `duplicateFieldLabel`, `index + 1`, `after` and `copyOf`.
- **The field editor** (`src/-private/field-editor.gts`, new): the frame
  (`FieldEditor`: under the header it belongs to, clamped to the wrapper's
  width, scrolling past the wrapper's bottom with at least 280 px,
  `EuiFocusTrap` with `@returnFocus={{false}}`, Escape and a click outside
  close it; a scroll of the grid body cancels it) and the built-in content
  (`FieldEditorForm`: name, focused, required, Enter saves; type select;
  the type-change warning on edit; the type's `fieldOptions`, keyed by the
  type; description; Required, hidden when `field.required` is a
  function; Cancel and Save, busy while the handler's promise is
  pending; the rejection's message). While the promise is pending,
  Escape, Cancel, a click outside and a grid scroll do not close it, so a
  rejection is still shown. Delete's confirmation is a third mode
  of the frame (the text, Cancel focused, a danger "Delete field"). Focus
  returns to the header it was opened from (the "+" header, the field's
  header, or after a delete the header now at that place). A field's
  draft (`draftOf`) is its plain own values without `id` and without
  functions.
- **Option forms** (`src/-private/field-options/`, new): `SelectOptions`
  (single and multi select: name and one of EuiBadge's named colours per
  option, add, remove; existing options keep their `value`, a new one is
  valued by its label made unique; hidden when `options` is a function),
  and `CurrencyOptions` (code, decimals), `PercentOptions` (decimals),
  `RatingOptions` (stars), `DateOptions` (day/month order),
  `DurationOptions` (format). Switching the type to a select adds
  `options: []`, to currency `currency: 'USD'`.
- **Arguments and API**: `@onFieldCreate`, `@onFieldUpdate`,
  `@onFieldDelete`, `@fieldEditor`, `@creatableFieldTypes` (default the
  14 of 6.4; on edit the field's own type is put first when it is not
  listed); `EuiSheetFieldType.label` and `.fieldOptions`; `api.addField({
  index })` (clamped, never before the first field), `api.editField(id)`
  (also a hidden field: under the "+" header, else the wrapper's top
  right); the blocks' `addField()`. `EuiSheetSearch` forwards the five
  arguments.
- **History pruning** (6.6): a `watchFields` modifier (`@fields` and
  `@hiddenFields` together, so a hide is not a loss) compares ids and
  types after each render; a field gone or retyped is dropped from the
  undo and redo entries (`withoutField`; a replaced entry goes through
  `replaceEntry` so pending resolves follow it; an empty one is removed),
  its rejected texts, its pending cells, an open cell editor on it and an
  open field editor on it (not one whose own save is in flight). The
  selection is clamped to the fields left.
- **Styles**: the "+" header (subdued plus, primary on hover and focus, a
  primary 6 % hover tint, the selection tint and a 3 px bottom bar while
  its editor is open, the 3 px ring under the keyboard), the panel (the
  row menu's elevation and hairline), the forms, and in the header menu a
  line before the first field item and before Delete, Delete in EUI's
  danger text colour. The menu is portaled, so those rules read EUI's
  root `--eui-color-*` variables with the sheet's variables as the
  fallback (TH3 holds).

### Messages

`addField`, `editField`, `insertFieldLeft`, `insertFieldRight`,
`duplicateField`, `duplicateFieldLabel(label)`, `deleteField`,
`deleteFieldConfirm(label)`, `fieldName`, `fieldType`,
`fieldDescription`, `fieldRequired`, `fieldOptions`, `addOption`,
`removeOption`, `save`, `cancel`, `fieldNameRequired`,
`fieldTypeChangeWarning` (19) and `fieldType_<name>` for the 17 built-in
types, as 4.6 lists. **Added beyond 4.6** (the option forms need labels):
`optionLabel(n)`, `optionColor`, `colorNone`, `color_<name>` for the 7
named colours, `fieldCurrency`, `fieldPrecision`, `fieldRatingMax`,
`fieldDateOrder`, `dateOrderDmy`, `dateOrderMdy`, `fieldDurationFormat`
(17). The visibility pass added `cellReadOnly`.

### Tests

New: FC1-FC6 and LF1-LF3 (`tests/unit/convert-test.ts`; the design's
`tests/unit/core/` does not exist, the unit tests are flat), H11-H12
(`withoutField`, `history-test.ts`), FM1-FM20 (FM20: a created field in
the sheet's own order; FM14 also covers a type change)
(`tests/integration/components/eui-sheet-fields-test.gts`), and from the
visibility pass VP4-VP6 (`eui-sheet-polish-test.gts`).

Existing tests changed, and why:

| Test | Change |
| --- | --- |
| A2 (`eui-sheet-types2-test.gts`) | A text cell under a file drag now answers the drag itself (`dragover` prevented, `dropEffect: 'none'`, visibility item 6): `defaultPrevented` on the text cell is now asserted true (was false), with no drop-target class on it. Added: the drop target's 3 px outline and tint. (`dropEffect` is not asserted: a synthetic `DataTransfer` keeps `'none'` whatever is set.) |
| SS3 (`eui-sheet-search-test.gts`) | One assertion added: the button is an `EuiButton` (visibility item 10). |
| AC1 (`eui-sheet-polish-test.gts`) | The focused invalid cell's error band is now `inset 0 0 0 5px` (2 px inside the ring, visibility item 7), was 4px: the assertion reads `5px`. |

No other existing test changed; FM1 confirms nothing shows without the
handlers.

### Deviations from the design

1. **`convertField`'s change set has `source: 'paste'`.** The design gives
   no source; adding `'convert'` to the union would be a change that is
   not additive (X3-like), and it is the paste path.
2. **Messages beyond 4.6** (listed above) for the option forms' labels.
3. **`SheetFieldEditorSignature['Args']['types']` entries carry the
   type's `fieldOptions`** (`SheetFieldEditorType`), so an app editor can
   render a type's options form; **`SheetFieldOptionsSignature` has
   `field?`** (the field on edit), so the select form can hide itself
   when `options` is a function. Both additive.
4. **A focus on a "+" body cell moves to the row's last field** at once
   (the 6.12 fallback), rather than an invisible focused cell.
5. **The sheet's own column order** (no `@onFieldOrderChange`, after a
   local drag or move): a created field is put after `position.after` in
   it (`placeCreated`); without this, Insert left/right would land the
   field at the end of the local order.
6. **`localRecords` options `types` and `messages`**: `updateField`
   converts with the built-in types by default, so a store whose fields
   use app types must be given them (d04 does).
7. **The panel's height** is clamped to the wrapper's bottom (at least
   280 px, then it scrolls); 6.4 says "clamped to the wrapper" without
   saying how.
8. **Unit tests** are in `tests/unit/convert-test.ts`, not
   `tests/unit/core/` (no such folder).

### Visibility pass, part 2 (the user's request after the main scope)

Judged from the light and dark screenshots (`v03-b2/*`) and computed
styles (WCAG contrast computed in the page, the background composited
under the element).

| # | Item | Found | Done |
| --- | --- | --- | --- |
| 6 | File drop target | A 2 px inset ring only; a text cell let the browser's default drag handling run (it opens a dropped file). | **Done.** The attachment cell under files gets the 3 px primary outline and the range tint (light and dark checked). Over any other data cell `dragover` is prevented with `dropEffect: 'none'`: the "not allowed" cursor, and no drop (nor the browser opening the file). A2 extended. The cursor itself is on the real-input list (a synthetic `DataTransfer` keeps `dropEffect` `'none'` whatever is set). |
| 7a | Invalid marker | 1 px danger inset and danger text: visible at rest and inside a range (light 6.3:1, dark 4.3:1 for the text on the tint). With focus the error line was 1 px under the 3 px ring and did not read. | **Done** for the active cell: a 2 px danger band just inside the ring (`inset 0 0 0 5px`). At rest and in a range: left as is (clear in both themes). |
| 7b | Pending cells | Grey italic text (light 4.8:1, dark 4.0:1). | **Skipped**: reads as pending in both themes (`*-pending.png`); no spinner added. |
| 7c | Read-only cue | Typing, Enter or F2 on a read-only cell did nothing. | **Done**, the lightest option: the focused cell's message box (the error box's place and live region) says "Read only" with a lock, in a neutral colour (`--euiSheet-text` on `--euiSheet-plain`, 9.3:1), until focus moves. Also Delete on a single read-only cell. The key is not taken (not prevented, not stopped, as before), so an app's own single-key shortcuts around a read-only sheet still get it. New message `cellReadOnly`. VP4. |
| 8 | Keyboard focus on headers and row numbers | Row numbers already had the 3 px ring (batch 1). Headers kept the grid's own focus look. | **Done** for headers: the same 3 px `--euiSheet-primary` ring, over the grid's `:focus-visible { outline: none }`, and the grid's `::after` made transparent. VP5 (both). |
| 9 | Contrast in dark | Checkbox border 1.5 px is drawn as 1 px by Chromium at 1× (borders snap to device pixels), at 6.1:1 (light) / 7.1:1 (dark): enough. Link text 7.3:1 / 6.6:1 (4.7:1 dark on the range tint). Filled stars 6.3:1 / 12.5:1. **Empty stars were 1.2:1 on white** (the border colour). | **Done** for empty stars: the subdued text colour at 45 % opacity (visible in both themes, still clearly not filled). Checkbox and links: left as is. |
| 10 | "Re-apply" and the loading bar | "Re-apply" was an `EuiButtonEmpty` (a text link look); the bar was EUI's `xs` (2 px). | **Done.** "Re-apply" is a small `EuiButton` (primary, with its light background; text 5.9:1 / 5.1:1). The bar is 3 px (checked in dark during a d12 sort). VP6; the search test asserts the button. |

### Not done

- Field management inside the expanded record (not in v0.3, 6.8).
- P7 ("PageDown moves by the rows in view") times out now and then: twice
  in this batch's runs (once with `ember-tsc` beside it, once alone), and
  in batch 1's own runs before any batch 2 change. Not looked into.
- Undo of field operations (D6: by design).
- The "+" column with `@groups` (batch 3b).
- A handler's rejected promise on **Duplicate** has no UI (there is no
  editor open); it is the owner's to report.
- The field editor's position is computed when it opens; a resize of the
  window while it is open does not move it (a grid scroll closes it).

### For real-input checking (Mac, real mouse and keyboard)

- The "+" header: hover, click, the open state while its editor is open;
  Tab/ArrowRight into it from the last header, Enter and Space; light and
  dark (d20).
- A click on a "+" body cell (focus goes to the row's last field);
  ArrowRight, End and Ctrl/Cmd+End on the last field.
- The column menu: the line before the field items and before Delete, the
  red Delete; inside a nested dark `EuiEmotionProvider` (d01's switch) the
  portaled menu follows the root theme's variables, not the nested one.
- The field editor: typing in the name and in option names (each
  keystroke kept), Enter saves, Escape and a click outside cancel, focus
  back on the header; the type select with the keyboard; the panel at the
  right edge (clamped) and in a short sheet (d04, 220 px: it scrolls).
- Edit field → change the type → the warning; Save in d20 converts
  (`rejected` in the log panel).
- Delete field: the confirmation, Cancel focused, then focus on the
  header that took its place.
- A file dragged from the desktop over a text cell (the "not allowed"
  cursor, nothing opens) and over an attachment cell (the ring and tint)
  in d17.
- The read-only cue: type on Company in d04's first row; it goes away
  when you move.
- Header keyboard ring (ArrowUp from a cell); empty rating stars in d15;
  "Re-apply" in d14 after an edit; the 3 px loading bar in d12 while it
  sorts.

### Files

Under `packages/sheet/`:

| File | Change |
| --- | --- |
| `src/core/types.ts` | `SheetFieldDraft`, `EuiSheetField.manageable` |
| `src/core/convert.ts` (new), `src/core/index.ts` | `convertField`, exported |
| `src/core/history.ts` | `withoutField` |
| `src/core/messages.ts` | the batch 2 keys and `cellReadOnly` |
| `src/types.ts`, `src/index.ts` | the five arguments, `SheetFieldEditorSignature`, `SheetFieldEditorType`, `SheetFieldOptionsSignature`, `EuiSheetFieldType.label` / `fieldOptions`, `SheetApi.addField` / `editField`, block `addField` |
| `src/components/eui-sheet.gts` | the "+" column (trailing column, control blocks, lookups, keys, click, focus redirect), menu items, `FieldEditorState` and the editor methods, `watchFields` pruning, `api` and block methods; visibility: read-only cue, drop "not allowed" |
| `src/-private/field-editor.gts` (new) | the frame, the built-in form, `draftOf` |
| `src/-private/field-options/select-options.gts`, `simple-options.gts` (new) | the built-in options forms |
| `src/field-types.ts` | `fieldOptions` on singleSelect, multiSelect, currency, percent, duration, rating, date |
| `src/local-records.ts` | `createField`, `updateField`, `deleteField`; `types`, `messages` options |
| `src/search-ui/eui-sheet-search.gts` | forwards the five arguments; "Re-apply" is an `EuiButton` |
| `src/-private/styles.ts` | the "+" column, the panel and forms, the menu items; visibility: drop target, invalid focus band, read-only cue, header ring, loading bar, empty stars |
| `tests/unit/convert-test.ts` (new), `tests/unit/history-test.ts` | FC1-FC6, LF1-LF3; H11-H12 |
| `tests/integration/components/eui-sheet-fields-test.gts` (new) | FM1-FM20 |
| `tests/integration/components/eui-sheet-polish-test.gts` | VP4-VP6 (and AC1, below) |
| `tests/integration/components/eui-sheet-types2-test.gts`, `eui-sheet-search-test.gts`, `eui-sheet-polish-test.gts` | A2, SS3, AC1 (above) |
| `docs/sheet.md` | Fields section, arguments, API, "In the field editor" under Field types |
| `docs/sheet-demo/d20-fields.md` (new), `d04-custom-cells.md` | the demo; an app type with `label` and `fieldOptions` |
| `README.md` | feature line, Fields section, API rows |

And `internal/spikes/sheet/v03-b2/*.png`, this section.

## Batch 2: fixes after the real-input check

Done 2026-11-19 in the same scratch copy, on top of batch 2's work.
Before: 415/415 (P7 failing now and then). After: **422/422**: 415 + 7
new (LY1-LY7). `pnpm lint` clean, `prettier --check` clean on the changed
files and README, the tests' `ember-tsc` has the baseline's 19 errors (none
new), `docs:api:check` passes. `packages/core/src` unchanged (`diff -rq`
against the repository).

### The bug: floating layers cut off by an ancestor's `overflow: hidden`

On the docs site d04 (`@height={{220}}`) sits in a demo frame, an
`EuiPanel` with `overflow: hidden`. The field editor was positioned inside
the sheet's wrapper, so the frame cut off its lower part (Description,
Required, Save, the type-change warning). The row menu, the panel editors
and the delete confirmation had the same problem.

**Fix.** These layers now render in a **sheet layer** (`src/-private/layer.gts`):

- `SheetLayer` portals its content to `<body>` (`EuiPortal`). Its root
  carries `sheet.themeClass`, so the `--euiSheet-*` colours apply, also
  under a nested dark `EuiEmotionProvider`. EUI components inside keep
  their context, because it follows the component tree, not the DOM. The
  root also gets the `--euiSheet-*` overrides set on the sheet's own
  `style`, copied when it opens.
- The portal joins every active focus trap that contains the wrapper
  (`attachToFocusTraps`, the core registry `EuiPopover` uses). It joins
  from `EuiPortal`'s `@portalRef`, before the content renders: an editor
  focuses its input as it renders, so a modifier on the layer's root
  joined too late.
  - Without the join, a sheet inside an `EuiModal` or an own-focus
    `EuiFlyout` has focus pulled out of a portaled select panel back into
    the trap. LY7 fails without it (checked by removing it).
- The root has the wrapper's listeners, which call the sheet's own
  handlers: `keydown` (capture), `mousedown` (capture), `pointerdown`
  (capture), `pointermove`, `pointerup`, `pointercancel`, `click` (capture
  and bubble), `focusin`, `focusout` and `contextmenu`. Events from a
  portaled layer no longer bubble through the wrapper. The editors' keys
  (`onEditKeyDown`: Enter, Tab, Escape, `handlesKey`), the menu's
  Escape/Tab, `contextmenu` inside the menu, focus tracking and the
  long-press flags all run as before.
- `onFocusOut` treats focus moving into one of the sheet's own layers as
  staying in the sheet (`ownsNode`). Before, focus moving from a cell to a
  portaled editor read as leaving the grid (`gridHadFocus`).
- `placeLayer` (a modifier) places a layer with `position: fixed` from its
  anchor's box in the viewport. The anchor's box is kept relative to the
  wrapper (as before) and converted on each placement (`toViewport`), so
  the layer follows a page or ancestor scroll.
  - It goes below the anchor, or above when it does not fit below and
    fits, or has more room, above. A placement that still fits is kept.
  - Below, its top is set; above, its bottom (at the anchor), so content
    that grows or shrinks after the placement (a list being filtered, a
    menu laid out late) stays attached without waiting for a re-place.
  - It is clamped to the viewport horizontally, with an 8 px margin.
  - Where there is a scrolling part (the field editor's and the row
    menu's panel), its max height is the room on that side, at least
    280 px for the field editor, then it scrolls. The panel editors have
    no max height, as before.
  - It is placed again on a `scroll` anywhere in the document (capture;
    not the layer's own scrolling), on a window `resize`, and when its
    size changes (`ResizeObserver`, in the next frame; within the callback
    it was a resize loop).
  - Its z-index is 2000 above the wrapper's stacking context
    (`getElementZIndex`, as `EuiPopover` does).
  - It sets `data-placement="below|above"`.

Layers moved:

| Layer | File | Anchor |
| --- | --- | --- |
| Row menu | `row-menu.gts` | the pointer (no size), or the cell for Shift+F10 / the ContextMenu key |
| Field editor, with its delete confirmation (the same frame) | `field-editor.gts` | the header (its left edge still kept inside the wrapper), or the header row's right end for a hidden field; 4 px gap |
| Panel editors (`editorLayout: 'panel'`: single and multi select, linked record, user, attachment, d04's zone picker) | `editor-frame.gts` (portaled only for `'panel'` with `@sheet`) | the cell; `min-width` max(cell, 240 px) |

Unchanged:

- In-cell editors (`cell`, `expand`) and the expanded record's `inline`
  editors.
- The header menu (EUI's popover).
- The date editor. It is a cell-layout `<input type="date">`, not a panel,
  so there was nothing to move.
- The IME catcher and the error box. They stay in the wrapper.

What still works as before:

- the field editor's focus trap and focus return, Escape, and a click
  outside;
- a grid scroll closes the field editor and the row menu (`onScroll`, as
  before);
- panel editors follow their cell or save on a grid scroll. `editing.rect`
  still drives them; a change re-runs the modifier;
- the editor frame's commit-on-focusout (`staysInEditor` is DOM and
  selector based, and portaling does not change that);
- the long press and Shift+F10, which are covered by the touch tests and
  the docs check.

`Editing.placement` and `PANEL_SPACE` (the wrapper-based flip) are gone.
`FieldEditorState` and the menu state hold an `anchor` box instead of
`top` / `left` / `maxHeight`.

### Tests

New: `tests/integration/components/eui-sheet-layers-test.gts`. The sheet
is in a `div` with `overflow: hidden; height: 260px`. The test container
is fixed in the viewport where a test needs its anchor (`placeAt`), and
the layers get two frames to settle.

- LY1: the field editor is portaled, Save lies below the box and is in
  the viewport, and `elementFromPoint` at its centre hits it. It is under
  its header; Save with no name keeps it open; Escape closes it.
- LY2: the row menu on the last row. Its last item is reachable, and
  picking it closes the menu.
- LY3: the single-select panel on the last row. It is portaled, its last
  option is reachable, it sits below the cell and aligned with it, the
  search has focus, and Escape (a key reaching the sheet from the layer)
  cancels and returns focus to the cell.
- LY4: near the viewport's bottom, the row menu, the select panel and the
  field editor flip above their anchor, and the parts checked are
  reachable.
- LY5: a scroll of an ancestor (the test container) moves the open menu
  with its cell.
- LY6: the layer carries the wrapper's theme class in dark mode, with the
  same `--euiSheet-plain`, and gets an override set on the sheet's own
  style.
- LY7: inside an `EuiFocusTrap`, the select panel keeps focus in its
  search and the row menu (Shift+F10) keeps focus on its items; Escape
  brings focus back to the cell each time.

Existing tests changed. Most string selectors of `assert.dom()` / `click()` /
`select()` are rooted at `#ember-testing`, and the layers are now outside
it. Those now pass `document.body` or an element (`el(...)`):

| Test | Change |
| --- | --- |
| FM2, FM3, FM5-FM9, FM11, FM12, FM15-FM18 (`eui-sheet-fields-test.gts`) | 55 queries of the field editor rooted at `document.body` / `el()`; no assertion changed |
| K3 (`eui-sheet-click-test.gts`) | `[role=option]` rooted at `document.body` |
| RW12 (`eui-sheet-rows-test.gts`) | `euiSheetRowMenu-never` rooted at `document.body` |
| TC1 (`eui-sheet-touch-test.gts`) | `euiSheetRowMenu` rooted at `document.body` |
| A1 (`eui-sheet-types2-test.gts`) | `euiSheetAttachment`, `euiSheetUploadError` rooted at `document.body` |
| N11 (`eui-sheet-types-test.gts`) | "inside the wrapper" is now "not inside the wrapper, in the sheet's layer" |
| N21 (`eui-sheet-types-test.gts`) | renamed "...flips above near the viewport bottom". For the flip, the test container is fixed so that the last row ends 40 px above the viewport's bottom (the flip is decided by the viewport now, not the wrapper); restored in `afterEach` |

### Checked on the built docs site (real input through CDP)

A CDP script (`v3b2/layers.mjs` in the session's scratch folder, not in
the repository) drives `site/dist-d14` (rebuilt) on port 4174 with
CDP `Input` mouse, keyboard and wheel events, in the site's light and dark
themes. Result: 31/31 checks in each theme, and no page errors.

- **d04** (frame bottom 544): the field editor's bottom is at 641.
  - Save, Required and Description are reachable. Typing a name, a click
    on Required and a click on Save create the field, and focus returns
    to a header.
  - Edit field → Number: the warning and Save are reachable; Escape closes
    the editor.
  - The row menu on the last row: its last item is reachable. Escape
    returns focus to the cell; Shift+F10 opens the menu.
  - The Site select on the last row: the last option is reachable, the
    search has focus, and ArrowDown then Enter picks and closes. The zone
    picker opens in reach.
  - With the menu open, a wheel scroll of the page moved the menu with
    its cell (60 px).
- **d20**: the field editor's Save is reachable, the editor is inside the
  window horizontally, and the layer has the sheet's theme class. The
  delete confirmation is reachable, its Cancel has focus, and Cancel
  closes it. A click outside closes the editor.
- **d01 dark** (the switch, a nested dark provider): the row menu has the
  sheet's dark `--euiSheet-plain` (`#111C2C`), a dark panel
  (`rgb(17, 28, 44)`) and light item text (`rgb(180, 193, 213)`).

On the docs site, a flipped row menu (d04's last row 40 px above the
window's bottom) is in place from its first frame: its bottom sits at the
pointer (722 px) at the first frame, the second and after 300 ms. A menu
below its anchor is also stable from the first frame. This was measured
with `lf-flash.mjs` in the scratch folder.

Screenshots: `v03-b2/{light,dark}-layer-*.png`. These are `d04-create`,
`d04-edit-warning`, `d04-row-menu`, `d04-select`, `d04-zone`, `d20-create`,
`d20-delete` and `d01-dark-row-menu`.

### P7, the flaky PageDown test: a real race, fixed

Found with an instrumented copy of P7 run 15 times in isolation. Before
the fix, 5 to 7 of 15 failed. Each failure was at "focus comes back to the
active cell" after Shift+PageDown.

- Shift+PageDown scrolls the grid, and the grid re-inserts the active
  cell's row node. Chrome blurs a focused node that is moved, so a
  `focusout` with no `relatedTarget` fires and focus falls to `<body>`.
  The cell node is connected again by the next run loop.
- `onFocusOut` decided in `next()`: a connected target meant "focus left
  the grid (a click on the page)", so it set `gridHadFocus = false`.
  Otherwise it parked focus.
- Recovery depended on order:
  - When the grid's scroll event came before that `next()`, the scroll's
    `parkFocus` refocused the cell, and the test passed.
  - When it came after, `gridHadFocus` was already false. `onScroll` no
    longer parked, and focus stayed on `<body>`: the keys stopped
    reaching the sheet. A user could hit this too.

Fix (`eui-sheet.gts`):

- The sheet notes a press anywhere on the page (`mousedown` and
  `pointerdown`, document capture, until the end of the run loop:
  `pagePressed`).
- A `focusout` that goes nowhere, with no press, with focus on `<body>`
  and the window focused, is the grid moving the cell. It now parks focus
  (`parkFocus`, which refocuses the active cell when a range is selected)
  instead of clearing `gridHadFocus`.
- A click on the page and a window blur are handled as before.

After the fix: 31/31 runs of the instrumented copy, and P7 passed in
every full run since. The temporary instrumentation is removed; a copy of
the debug test is kept in the scratch folder
(`lf-zz-p7-debug-test.gts.keep`).

### Files

Under `packages/sheet/`:

| File | Change |
| --- | --- |
| `src/-private/layer.gts` (new) | `SheetLayer` (portal, theme class, overrides, focus traps, listeners), `placeLayer`, `LAYER_SELECTOR` |
| `src/-private/row-menu.gts` | in the layer, anchored, scrolling panel |
| `src/-private/field-editor.gts` | in the layer, anchored to the header, clamped to the viewport (at least 280 px) |
| `src/-private/editor-frame.gts` | `'panel'` with `@sheet` in the layer; `@placement` removed |
| `src/components/eui-sheet.gts` | `WrapperBox`; menu and field editor state hold an anchor; `toViewport`, `menuAnchor`, `ownsNode`; `onFocusOut` (layers, the P7 race); `pagePressed`; `PANEL_SPACE` and `Editing.placement` removed |
| `src/-private/styles.ts` | `.euiSheetLayer`; the layers `position: fixed`; `--euiSheetLayerMaxHeight` for the menu and the field editor |
| `tests/integration/components/eui-sheet-layers-test.gts` (new) | LY1-LY7 |
| `tests/integration/components/eui-sheet-{fields,click,rows,touch,types,types2}-test.gts` | listed above |
| `docs/sheet.md` (Theme), `README.md` (Theme) | the layers: at the end of `<body>`, they get the class and the overrides, app CSS not under `.euiSheet` |

And `v03-b2/*-layer-*.png`, and this section.

### Left

- **The layers no longer inherit a style set on an ancestor of the
  sheet**, which they did inside the wrapper. They get the theme class
  and the overrides set on the sheet's own `style`. An app's CSS for its
  own panel editor scoped under `.euiSheet` no longer matches (docs say
  so).
- **The overrides are copied when a layer opens**. A change while it is
  open is not followed.
- **A window resize while the field editor is open now re-places it**. It
  used to stay put. A grid scroll still closes it.
- **A layer is placed again in the next frame when its size changes**
  (ResizeObserver). The LY tests wait two frames. In the test container,
  LY4's one failing run fits a menu measured about 28 px at insertion
  that then grew; since a
  flipped layer is anchored by its bottom, that no longer moves it, but a
  layer that is laid out late and does not fit below can still pick its
  side one frame late. Not checked in Firefox or Safari, nor on a Mac with
  a real mouse.
- **Focus traps**: an `EuiFocusTrap` (and the modal and flyout, which use
  the same registry) takes the layers in. A focus trap of another library
  around the sheet does not.
- **The real-input check ran through CDP** (Chromium's synthetic input
  pipeline), not a person at a Mac.
- **The P7 fix keys on `document.hasFocus()`**: with the window not
  focused, the old rule applies.
