# 02. Full screen

## Why

Big sheets on a laptop need the whole window. The README's Limits section
says "no fullscreen yet".

## Why not the grid's own full screen

EuiDataGrid has one (`setIsFullScreen`, `eui-data-grid.gts:807`). It does
not fit the sheet, for two reasons:

- its focus trap covers only the grid's wrapper, and the sheet's editor
  sits beside the grid, outside that trap (`../RESULTS.md:131-136`,
  `../DESIGN.md:403`);
- the toolbar, the footer and the summary bar are outside the grid too.

So the sheet makes its own wrapper full screen.

## API

- `@fullScreen` and `@onFullScreenChange(on)`. As with the other
  presentation state, they are controlled with the handler and local
  without it.
- Block API: `isFullScreen` and `setFullScreen(on)`. The app puts the
  button in `<:toolbar>`; the sheet draws no button. A docs example uses
  the icons `fullScreen` and `fullScreenExit`, with
  `messages.enterFullScreen` and `messages.exitFullScreen` as their labels.
- `api.setFullScreen(on)`.

## Behaviour

- The wrapper gets `euiSheet--fullScreen`:
  - `position: fixed; inset: 0`;
  - the plain background;
  - the same z-index as the grid's own full screen (`levels.header - 2`,
    `core/src/utils/eui/data-grid.ts:41`), so flyouts, modals and toasts
    stay above it.
- The floating layers (row menu, header menu, panel editors, the field
  editor) set their z-index to the wrapper's plus 2000 (`layer.gts:140`),
  so they open above the full-screen wrapper with no change.
- Inside it, the layout is a column. The toolbar and the footer keep their
  height, and the grid takes the rest: its `height` becomes `100%` of a
  `flex: 1; min-height: 0` box. `@height` is ignored while full screen.
- `document.body` gets `overflow: hidden` while full screen. It is
  restored on exit and when the sheet is destroyed.
- **Escape** leaves full screen only on a cell with nothing else to undo.
  The order, first match wins:
  1. an open editor, menu, field editor or shortcut list closes (today's
     handlers, which stop the event);
  2. a lifted column drops back;
  3. the copy marks clear;
  4. a range collapses to its active cell;
  5. otherwise, full screen ends.
  The grid's own Escape handling on a cell does nothing the sheet uses, so
  step 5 is the sheet's keydown on the wrapper, after the others.
- **Tab** stays as the grid's: from the last cell, focus leaves the grid
  and goes to the next focusable element in the wrapper (the footer), as
  today. The sheet sets no focus trap: Tab can leave the full-screen
  wrapper for the page behind. The docs say so; the app can put its own
  trap around the sheet if it needs one.
- The focused cell, the selection and the scroll position are kept.

## Code

- `src/-private/full-screen.ts` (new, about 60 lines):
  - `isOn(args, local)`;
  - `set(on)`, which calls the handler or the local state;
  - the body lock as a modifier;
  - `handleEscape(event)`, called at the end of the sheet's Escape chain.
- `styles.ts`: the class, about 6 lines.
- The component: the class on the wrapper, the grid height, the block API
  and the API method, about 30 lines.

## Tests (`eui-sheet-full-screen-test.gts`)

- **FS1:** `setFullScreen(true)` from the toolbar block makes the wrapper
  fill the window, and the grid's bottom is at the footer's top.
- **FS2:** Escape in an open editor only closes it. With a copy mark,
  the first Escape clears the mark, the second ends full screen.
- **FS3:** the controlled mode: with `@onFullScreenChange`, the sheet
  changes only when the argument changes.
- **FS4:** the expanded record, the row menu and a panel editor (a
  select) each open above the full-screen sheet (`elementFromPoint` at
  their centre is inside them).
- **FS5:** the body's overflow is restored on exit and on destroy.
- **FS6:** the focused cell is the same before and after.

## Docs

A README section "Full screen" with the toolbar example. Remove
"fullscreen" from Limits.

## Risks

- **The grid's height measuring.** The grid may keep its old height until
  a resize event. FS1 checks it; if the height is wrong, dispatch one
  `resize` after the class changes.
- **An app with its own fixed header above `levels.header - 2`** would
  cover the sheet. That is the same as the grid's own full screen, so it
  is acceptable.
