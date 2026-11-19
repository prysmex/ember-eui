# `@ember-eui/sheet` v0.2: results

Results of the batches of `V02-DESIGN.md`, on branch `feat/sheet`. Each
section says what was built, what was verified (and how), and what was not.

## Batch 1: foundations

Built 2026-11-19 on `7f02013a` (uncommitted when this was written). Scope:
theme tokens, quoted TSV, change set v2, `colOffset` and add-row plumbing
(no add row yet), `pendingFocus`, `SheetApi` (`undo`, `redo`, `focusCell`,
`remapIds`, `clearHistory`). Nothing of batch 2 was started.

### What was built (files, under `packages/sheet/`)

| File | Change |
| --- | --- |
| `src/core/tsv.ts` | Rewritten: quoted cells as Excel and Google Sheets write them (4.2). |
| `src/core/types.ts` | `RecordInsert.anchor`, `RecordInsert.restore`, new `RecordRemoval`, `ChangeSet.removed`, four new `source` values (C1). |
| `src/core/change-set.ts` | `applyChangeSet` positions inserts by anchor, then index, and restores (`restoreRecord` option) (C2); `pasteMatrix` anchors its inserts; new `insertRecords`, `deleteRecords`, `duplicateRecords`. |
| `src/core/history.ts` | `invertChangeSet(set, fieldIds?)` turns `removed` into positioned restores; `withoutConflicts` keeps a re-insert's position (C3) and takes `equals`; `undoChangeSet`/`redoChangeSet` take `options` (`fieldIds`, `equals`); redo carries `deletes` and `removed`; new `mergeChangeSets`. Types `ValueEquals`, `HistoryOptions`. |
| `src/-private/theme.ts` (new) | `sheetThemeVars`: the 14 `--euiSheet-*` custom properties from `euiTheme.colors` (4.3). |
| `src/-private/styles.ts` | Every fixed colour is `var(--euiSheet-x, <v0.1 value>)`; the editor input now has a background and a text colour (it had none). |
| `src/-private/remap.ts` (new) | `remapChangeSet`, `toIdMap`, `composeIdMaps`, `remapId` for `remapIds` (plain TypeScript, not exported). |
| `src/components/eui-sheet.gts` | Theme class on the wrapper and passed to editors as `@themeClass`; `colOffset` (0), `hasAddRow` (false), `rowCount`, `recordAt`, `focusGridCell`; `SheetApi` and `@registerApi`; following `@records` (3.2): own-change detection, `followRecords`, `pendingFocus`; the editor (`Editing`, now a class with tracked `pos`/`rect`/`placement`) finds its record by id; history records delete-only sets and merges a `'resolve'` into the last entry; `emit` drops a deleted record's rejections. The grid's API field is renamed `gridApi`/`registerGridApi` (it clashed with the new `SheetApi`). |
| `src/-private/sheet-cell.gts` | Subtracts `colOffset` from the grid's column index. |
| `src/-private/editors/date-editor.gts` | Passes `@themeClass` to the text editor it wraps. |
| `src/types.ts` | `SheetApi`, `EuiSheetSignature.Args.registerApi`, `SheetEditorSignature.Args.themeClass?`. |
| `src/index.ts` | Exports the `SheetApi` type (the core functions come through `export *`). |
| `src/local-records.ts` | Option `restoreRecord`, passed to `applyChangeSet`. |
| `tests/helpers/sheet.ts` | `COL_OFFSET` (0); `cell(row, col, root?)` adds it; `selected()` subtracts it. |
| Tests | See below. |
| `docs/sheet.md`, `README.md`, `docs/sheet-demo/d01-basics.md`, `d06-date-picker.md`, new `d09-own-store.md` | See "Docs". |

### API changes

Additive: `EuiSheetSignature.Args.registerApi`; type `SheetApi`; core
`insertRecords`, `deleteRecords`, `duplicateRecords`, `mergeChangeSets`,
`RecordRemoval`, `ValueEquals`, `HistoryOptions`; `RecordInsert.anchor`,
`RecordInsert.restore`, `ChangeSet.removed`; optional parameters
`invertChangeSet(set, fieldIds?)`, `undoChangeSet(…, options?)`,
`redoChangeSet(…, options?)`, `withoutConflicts(…, { equals })`;
`applyChangeSet` option `restoreRecord`; `LocalRecordsOptions.restoreRecord`;
`SheetEditorSignature.Args.themeClass` (optional, see deviations).

Not purely additive, as the design lists them: C1 (new `source` values),
C2 (`applyChangeSet` honours `anchor`/`index`), C3 (a re-insert keeps its
position), C4 (quoted TSV), C12 (needs `@ember-eui/core/theming`), and C14
(the selection, focus and an open editor follow their record when the owner
replaces `@records`). Also: pasted inserts now carry `anchor` (3.4), so a
`deepEqual` on a paste's inserts sees one more key.

### Verification items (section 12)

| # | Item | Outcome |
| --- | --- | --- |
| N1 | `@ember-eui/core/theming` in the lowest core the peer allows (`^16.0.0`). | Seen in git only: `packages/core/src/theming.ts` exports `getEuiThemeContext`, `euiClass`, `useEuiBorealisStyles` and the type `EuiThemeStyleContext` at the `@ember-eui/core@16.0.0` tag and at the version bump commit `52e1af5d` ("bump v16.0.0"); `5087be1e` (which added the entry) is an ancestor of it. Oddity: the tag's `package.json` says `15.0.0` (the tag was made before the bump commit). The published npm tarball was not inspected (no network used for it). Core's `exports` has `"./*"` → `dist/*.js`, which serves `./theming`. The peer range was not changed. |
| N2 | The provider's component name and its colour-mode argument. | `EuiEmotionProvider` (`@ember-eui/core/components/eui-emotion-provider`, also in `@ember-eui/core/components`), `@colorMode="light" \| "dark"`; a root provider also has `@globalStyles`. Read from `eui-emotion-provider.gts`. **But** in the sheet's test app a provider is not seen by `getContext`: the strict resolver does not run `ember-provide-consume-context`'s `glimmer-overrides` initializer, which core's own test helper registers by hand (`packages/core/tests/test-helper.ts:49-53`), and the sheet does not depend on that package. A first TH2 with a dark provider got the light class on both sheets (log `b1-run3.log`). TH2 now switches the `eui-emotion` service's `colorMode` (tracked) instead, which also shows the class follows a mode change. The provider path is used by the d01 demo: to check on the docs site. |
| N14 | No performance number was measured. | For 4.9's "10,000 ids under 2 ms": the per-change id work of `recordsRendered` (map to ids, compare, own-change check), as a copy in node 10,000 records: 0.11 ms (same ids), 0.61 ms (own paste of 2 rows), 0.09 ms (reversed) per change (`b1-perf.mjs`, `b1-perf.log`). Not measured in the browser or in d08. |

### Tests

Baseline at HEAD in the scratch copy: 113/113 (`b1-baseline.log`). After
the plumbing and the core, before new tests: 113/113 (`b1-run1.log`).
Final: **149/149**, 0 failed (`b1-final2.log`, 06:45 UTC; an earlier
147/147 in `b1-final.log` before T25 and TH5 were added). Logs are in the session scratchpad
(`/tmp/claude-1000/-Users-betocantu93-prysmex/df04f7e2-a347-4eab-a276-4d9974f4dbc1/scratchpad/`).

New (36): `tests/unit/tsv-test.ts` Q1–Q8; `tests/unit/change-set-test.ts`
S1, S2, S2b, S3–S8; `tests/unit/history-test.ts` H6–H10;
`tests/integration/components/eui-sheet-theme-test.gts` (new) TH1–TH4, and
TH5 (a `--euiSheet-*` property set on the sheet element overrides the
theme; set on a parent it does not, as the docs say);
`tests/integration/components/eui-sheet-test.gts`, new module "v0.2
foundations", T17–T24, and T25 (an insert-only redo focuses the
re-inserted row: the `pendingFocus` path).

Not executed by any test, because batch 1 has no UI that emits them: a
delete-only history entry and its undo (restores) through the sheet, and
the `'resolve'` merge. They are covered by the core unit tests only
(S3, S5, S8, H6–H8).

Changed on purpose (each assertion made exact, none loosened):

- **U6, U13** (`change-set-test.ts`): their `deepEqual` of a paste's
  inserts now includes `anchor` (after the last record, then after the
  previous insert), as 3.4 specifies for `pasteMatrix`.
- **H4** (`history-test.ts`): a re-insert without an anchor keeps its index,
  clamped (`Math.min(1, 2) = 1`), instead of going to the end (`2`): C3.

Design inconsistency: 4.6 says the 113 tests pass unchanged except maybe
`tsv-test.ts` U2. U2 passes unchanged; U6, U13 and H4 had to change,
because 3.4 (anchored paste inserts) and C3 change exactly what they assert.

Test notes:

- TH1 first asserted the focus ring colour; the computed `outline-color` of
  a focused cell is `rgb(0, 0, 0)`: the grid's own cell styles set
  `outline: none` on `:focus-visible` and draw their own ring (an `::after`
  border, `styles.generated/shared/VRGXM52Z.ts`), so the sheet's `:focus`
  outline rule is not what shows. Pre-existing (v0.1 had the same rule), not
  changed; TH1 checks the checked checkbox's background instead.
- T17 first focused the paste target with `focus()` after a Shift+Arrow,
  which extended the range (`extending` stays set after a Shift+arrow
  keydown until the next key or press): a test artefact, fixed with a click.
- T19 uses the `pressed()` helper (`triggerKeyEvent` refuses lower-case
  `z`).

Lint (`pnpm lint`: `ember-tsc --noEmit`, ESLint, stylelint): exit 0
(`b1-lint-final2.log`). Prettier `--check src tests/integration tests/unit
tests/helpers/sheet.ts README.md`: clean (`b1-prettier-final2.log`). `tests/helpers/index.js`
is not Prettier-clean at HEAD and was not touched.

### Deviations from the design

1. **pnpm store**: the install used the sandbox's existing store
   (`~/.local/share/pnpm/store`) instead of a new `scratchpad/pnpm-store`,
   to save disk (3.2 GB free, a fresh store would have downloaded the whole
   tree). `pnpm install --frozen-lockfile` passed; no dependency changed.
2. **`SheetEditorSignature.Args.themeClass` is optional** (`themeClass?:
   string`), not `string`: a required argument breaks the type check of
   every app that renders `SheetInputEditor` itself (the d06 demo, the
   README's flatpickr example, `eui-sheet-custom-type-test.gts`). The sheet
   always passes it; d06 and the README now pass it on.
3. **TSV round trip contract** (4.2): `parseTsv(toTsv(m))` equals `m` for
   matrices with at least one cell per row, whose last row is not `['']`,
   and with no `\r\n` inside a cell: 4.2 also says `\r\n` inside a quoted
   cell becomes `\n` (Q5), so such a cell cannot round-trip. A lone `\r` is
   quoted and round-trips.
4. **`remapIds`** rewrites the history, rejections, `pendingFocus`, the
   editor's record id, the last `@records` ids and the pending own-change
   deletes at once (3.6, "rewritten"), and also keeps the composed map and
   applies it to every later history entry (4.4, "a Map consulted"); both
   texts hold. The helpers are in `src/-private/remap.ts`, not exported, to
   keep the public API as 4.5 lists it.
5. **Restore `values`** (`invertChangeSet`): fields whose value is
   `undefined` are left out. `duplicateRecords` does the same.
6. **Own-change test** (4.4): the new ids must keep the old ids minus the
   pending deletes as an ordered subsequence, with *at most* (not exactly)
   as many new ids as pending inserts, so an owner that drops an insert is
   still "own". Pending inserts/deletes accumulate over the emits since the
   last `@records` change.
7. **Focus after an outside change**: "a data cell had DOM focus" also
   counts a cell whose focus was lost to nowhere in the same run loop
   (`focusDropped`, set on a focusout with no `relatedTarget`, cleared with
   `next()`): when the owner drops the focused row, the render removes the
   cell before the sheet's after-render step runs (T21 failed without it,
   `b1-run3.log`). When the edited record is gone and the editor had focus,
   the head cell is focused too (T23).
8. **`withoutConflicts` re-insert indexes** are computed by placing the kept
   inserts in ascending order over the current ids, as `applyChangeSet`
   does, so chained inserts (a paste) get consecutive indexes after their
   anchor, and an index counts inserts placed before it (H8).
9. **`'resolve'`** merges into the *last* undo entry (no link to "the paste
   that asked for it" exists yet); nothing emits `'resolve'` in batch 1.
10. **Undo `equals`**: no field type has an `equals` yet, so the sheet
    passes only `fieldIds` (`@fields`); batch 5 adds `equals` from types.
11. **TH2 does not use a dark `EuiEmotionProvider`** (4.7 asks for one): the
    sheet's test app does not run `ember-provide-consume-context`'s
    initializer, so a provider is not seen there (N2). TH2 switches the
    `eui-emotion` service's `colorMode`. The provider path, which d01 and
    real apps use, has no automated test: the docs-site check of d01's Dark
    switch is its only verification.
12. The docs' new "Theme" section lists all 14 properties; `subdued`,
    `border` and `highlight` are defined but not used by any style yet.

### Docs

- `docs/sheet.md`: change set block (new sources, `anchor`, `restore`,
  `removed`), where an insert goes (`index`, `anchor`, `restore`,
  `restoreRecord`), `remapIds` in "Undo and redo", `@registerApi` argument,
  new sections "The sheet's API" (including C14) and "Theme"; "Not yet"
  loses quoted cells and dark colours.
- `README.md`: the same, plus `@themeClass` in the editor row and in the
  flatpickr example; "Limits (v0.1)" became "Limits".
- `d01-basics`: a Dark switch wraps the sheet in `EuiEmotionProvider
  @colorMode`; text on multi-line cells.
- `d06-date-picker`: passes `@themeClass` to `SheetInputEditor`.
- New `d09-own-store`: a store on `applyChangeSet` whose "server" renames
  inserted rows after 300 ms (`remapIds` first, then the new records),
  buttons for `undo`, `redo`, `focusCell`, `clearHistory`, and an event log.

### Docs site build

In the scratch copy: `build:js` of sheet, flatpickr, pikaday,
changeset-form and validated-form (core was built first), then in `site`
`pnpm clean:docfy && node ../scripts/generate-llms-txt.mjs && pnpm exec
vite build --mode production`: exit 0 (`b1-site.log`,
`b1-site-summary.log`; rebuilt after a docs wording fix: `b1-site2.log`);
the d09 chunk
(`docfy-demo-docs-sheet-d09-own-store-*.js`) is in `site/dist/assets`. The
log has docfy's `getRepoEditUrl` TypeError (edit URLs; the scratch copy has
no `.git`), which earlier site builds in this scratchpad show too. The demos
were built, not run: `site/dist` is left in the scratch copy.

### For the orchestrator to check with real input (docs site)

- d01: the Dark switch: selection, hover, focused-cell errors, the editor
  input (not white) and checkboxes in dark; switching back.
- d01: copy a cell with a line break from Excel/Sheets (or type one), paste
  it into the sheet and back out: one cell, quoted on the clipboard.
- d09: paste three lines on the last row, wait for the `srv-…` ids, Ctrl/Cmd+Z
  removes them, Ctrl/Cmd+Shift+Z re-inserts them (new ids again); the
  buttons work with focus outside the grid.
- Any sheet: re-sorting `@records` from outside is not in a demo (only
  T20–T24 cover it).

### Open issues for later batches

- The sheet's `:focus` outline is hidden by the grid's own focus ring (see
  TH1 note); batch 3's frozen cells and batch 2's row-number column should
  check which ring shows.
- The test app cannot use `EuiEmotionProvider` (no context initializer);
  batch 2's flyout/modal tests may need theme or context from a provider:
  register `ember-provide-consume-context`'s initializer in
  `tests/test-helper.ts` (needs it as a devDependency, a lockfile change)
  or keep using the service.
- `'resolve'` must find the entry of the paste that asked for it (batch 5);
  `equals` from field types (batch 5); `fieldIds` should include
  `@hiddenFields` (batch 3).
- `pendingFocus` is applied only after a render with a new `@records` (or
  right after an undo that only inserts); batch 2's inserts can reuse it.
- `extending` stays set after a Shift+arrow keydown until the next key or
  press (pre-existing), so a programmatic focus after it extends the range.

### Batch 1: real input in Chromium (orchestrator, 2026-11-19)

Production docs build, Playwright keyboard and mouse:
- d01 Dark switch: the grid, the selected invalid cell's border, the editor
  input and the checkboxes follow the dark theme (screenshot
  `v02-b1-dark.png`); the focused error box shows "Required"; switching off
  restores light.
- d01 multi-line paste: a quoted two-line cell copied from a textarea pastes
  into one cell, the next field gets "Lima", the next row is untouched;
  copying the two cells back gives `"line one\nline two"\tLima` (quoted).
- d09: pasting three lines on the last row's Item: `srv-3` becomes "Vest" and
  two rows appear as `new-1`, `new-2`, then `srv-101`, `srv-102` after the fake
  save; Ctrl/Cmd+Z removes both rows and restores "Goggles"; Ctrl/Cmd+Shift+Z
  re-inserts them (new server ids); the Undo and Redo buttons do the same;
  "Focus last row" focuses the last row's Item cell; after "Clear history",
  Undo does nothing.
