# `@ember-eui/sheet`: the readiness batch (after v0.4)

Written 2026-11-20 at the user's request ("add that final batch after
v0.4"), plan only. It comes after every v0.4 batch (D, A, B, C, E). Its
aim is not new features: it is what has to be true before the package is
nice for Ember users, as listed in the session's review on 2026-11-20.

Two kinds of work: what can be done and checked in the Linux sandbox
(Chromium only), and checklists the user runs on real devices, with the
fixes coming back as commits.

## In the sandbox

1. **Bundle size.**
   - Measure the published build with `pnpm size`
     (`scripts/measure-bundle-size.mjs`): the sheet's main entry, the
     core helpers (`@ember-eui/sheet/core`), and what an app importing
     only `<EuiSheet>` pulls in.
   - The import screen (v0.4 batch E) and the barcode scan panel (V03
     batch 4) must not be in the main sheet's bundle when unused: a
     separate entry or a lazy import, whichever the build supports.
   - Record the numbers and set a budget in the results.
2. **Performance.**
   - The large-data demo at 10,000, 50,000 and 100,000 records and 30
     fields: first render, one scroll step, a range drag, a paste of 1,000
     lines, undo. Measured in Chromium with real input, also with CPU
     throttling (CDP, 4x).
   - The per-cell call count (`cellView`), as stage 2 of 3c measured it.
   - What is slow is either fixed in the batch or written down with its
     numbers.
3. **Accessibility, automated part.**
   - axe-core over every demo page in light and dark (contrast included).
   - A review of the grid's roles and labels: the row-number, group
     header and add rows, the editors, the menus, the field editor, the
     import screen, the shortcut list, and live announcements of an
     undo or an error.
   - Fixes for what is wrong.
4. **Getting started.**
   - A "working sheet in five minutes" page: `localRecords`, three
     arguments, one field of each common type.
   - Then one complete example app page that uses the main features
     together: groups, editing, import, CSV export, load more and the
     expanded record.
   - Both are linked first in the docs and the README.
5. **Loose ends.**
   - TR1 (the touch handles' placement test failed once in a full run):
     find the cause, and re-place the handles after a late layout change
     if that is it.
   - The EmberSearchUi connector (`EuiSheetSearch`) forwards the sheet's
     arguments one by one and passes none of v0.4's: `@onVisibleRangeChange`
     (batch D), `@fullScreen`, `@onFullScreenChange`, `@fieldActions`,
     `@copyWithFieldNames`, `<:recordFooter>` (A), `@cellColor` (C), nor
     batch 4's `@rowColor`. Forward them all, with a test that fails on a
     missing one.
   - The fill handle seen about 90 px above the selected cell's corner
     600 ms after a row-height change (v0.4 batch C's screenshot at the
     extra-tall height): find whether it is a placement bug (the handle
     not re-placed on a row-height change) or a screenshot taken too early.
   - A rejection on an inserted row is hidden when the owner's
     `createRecord` gives that field a default value (e.g. `qty: null`):
     the sheet shows a rejection only while the value is the one it saw
     when emitting it. Seen in v0.4 batch B, for `appendRows` and a paste
     on the add row alike; `localRecords`' default is not affected.
   - `url`'s `validate` accepts `19/11/2026` and `12` (the URL parser
     reads them as IPv4 hosts); the import guess works around it, the
     type itself does not (v0.4 batch E stage 1).
   - The import guess: ISO timestamps guess `date` (its `parse` drops a
     time part) and spaced phone numbers guess `number`; decide whether
     `dateTime` and `phone` should win there.
   - A paste from a record row whose lines run past the last record: the
     new records get no `@newRecordValues` (only a paste on an add row
     and `appendRows` do; PNV5 pins it). One call to change.
   - The import screen's messages have no plural forms ("Import 1
     lines"); and its value map lists the file's texts but is applied
     after the column's transform, so with a transform on a select or
     checkbox column the listed texts may stop matching (shown as
     errors, not silently).
   - The import screen opens in 377-446 ms on a 10,000-line, 20-column
     file (718 ms the first time); the design's target was 300 ms.
     Decide: defer the first dry run, put each column's options behind a
     button, or relax the target (v0.4 batch E stage 2, deviation 11).
   - Any open item the v0.4 batches leave.

## On the user's devices (checklists in the batch's results)

Each checklist says what to do and what to see, and is short enough to
run in a sitting:

1. **Safari and Firefox on a Mac:** editing and keys, copy and paste with
   the real clipboard, range drag, fill handle, row and column drag,
   frozen fields while scrolling, the expanded record, full screen,
   the date and dateTime pickers, attachments, import.
2. **A real iPhone (Safari) and an Android phone (Chrome):** tap to
   select, the touch selection handles, long press menu with Copy and
   Paste, scrolling, editors and pickers, the barcode camera scan
   (Android Chrome has `BarcodeDetector`), upload progress.
3. **Screen readers:** VoiceOver on the Mac, and NVDA on Windows if
   available: move through cells, edit a cell, the row menu, the
   expanded record, an error message.
4. **Prysmex:** use the sheet in one real Prysmex screen; what that shows
   comes back as issues for this batch.

## Done when

The sandbox items are committed with their numbers. The user has run the
checklists, and every problem they found is fixed or listed as known.
