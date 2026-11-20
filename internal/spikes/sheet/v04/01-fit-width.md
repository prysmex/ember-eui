# 01. Fit a column to its content

## Why

Wide text gets cut off, and narrow numbers waste space. Fixing that by
dragging every column is a daily chore. AG Grid does it on a double-click
of the resize edge, Glide and RevoGrid have an auto-size
(`../FEATURE-RESEARCH.md` row 1).

## API

- A header menu item, "Fit to content" (`messages.fitToContent`), on every
  field.
- A double-click on a column's resize edge does the same.
- `api.fitField(fieldId)` fits one field. `api.fitFields()` fits every
  visible field.
- No new argument. The width goes out the way a drag-resize does:
  `@onFieldWidthChange(fieldId, width)` when that handler is passed, and
  the sheet's own kept width without it.

## Behaviour

- The width is the larger of the header's and the content's:
  - the header: the label's text width, plus the header's chrome (the sort
    arrow and the menu button), read once from a rendered header;
  - the content: the widest cell over the loaded records (at most the
    first 2,000; the docs say so), plus the cell's horizontal padding,
    plus the opener button's width for types with an `opener` (select,
    date).
- The result is clamped between 80 and 480 px.
- A cell's text is the type's `format(value)`, measured with a canvas
  `measureText` in the cell's font (read once from a rendered cell's
  computed style).
- Some cells are not plain text. Their type gives an optional
  `contentWidth(value, field, measure) => number`. The built-in ones:
  - `checkbox`: 24;
  - `rating`: `max × 18`;
  - `multiSelect`, `user` (multiple), `linkedRecord`: the sum of the chip
    labels, plus 24 per chip;
  - `attachment`: 28 per thumbnail.
  An app type without `contentWidth` is measured as text.
- A frozen field can be fitted. Its new width moves the frozen layout, as
  a drag-resize does.

## Code

- `src/-private/fit-width.ts` (new, about 90 lines). It has three parts:
  - `measureText(font)`: one canvas, reused;
  - `fieldWidth(ctx, field, measure, chrome)`: pure apart from `measure`,
    and unit-tested with a fake;
  - `onResizerDoubleClick(event)`: finds
    `.euiDataGridColumnResizer` → its header cell's
    `data-gridcell-column-id` (`header-cell.gts:449`) and returns the
    field id.
- The header-menu module adds the item (the place of today's
  `fieldMenuItems`, `eui-sheet.gts:1238`).
- The component adds one `dblclick` listener on the wrapper, capture
  phase, and the two API methods.
- `contentWidth` goes on the five built-in types in
  `src/core/field-types/*`, about 30 lines.

## Tests (`eui-sheet-fit-width-test.gts`)

- **FW1 (gate):** a double-click on a column's resize edge calls
  `@onFieldWidthChange` once with that field. The core resizer starts a
  drag on `mousedown`; the test checks that the double-click still arrives
  and that the width it ends with is the fitted one, not a dragged one.
- **FW2:** after "Fit to content" on a text field, the cell with the
  longest value is not cut off (its content's `scrollWidth` is at most its
  `clientWidth`), and the width is at most 480.
- **FW6:** a single-select field leaves room for its ▾ button: the label
  and the button do not overlap.
- **FW3:** with no handler, the column takes the width (local).
- **FW4:** a checkbox field fits to its header label.
- **FW5:** `api.fitFields()` emits once per visible field.
- **Unit (`fit-width-test.ts`):** `fieldWidth` with a fake `measure`:
  clamping, the header winning, and `contentWidth` being used.

## Docs

The "Fields" section of the README: one sentence and the API rows. Add
"Fit to content" to the header menu list.

## Risks

- **FW1 may fail**: the core resizer could swallow the second click. If it
  does, drop the double-click and keep the menu item and the API. Do not
  change the core.
- Fonts that are still loading measure wrong. Measure at the click, not on
  the first render.
- Values that are not loaded (other pages) are not measured. The docs say
  so.
