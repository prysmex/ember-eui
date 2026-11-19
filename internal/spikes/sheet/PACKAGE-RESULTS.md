# `@ember-eui/sheet` v0.1: implementation results

Written 2026-11-19 on branch `feat/sheet` (working tree, nothing
committed). It implements `PACKAGE-DESIGN.md` with the user's answers to
its section 16, which the brief gave. Every claim below comes from a log
in the scratchpad:
`S=/tmp/claude-1000/-Users-betocantu93-prysmex/df04f7e2-a347-4eab-a276-4d9974f4dbc1/scratchpad`.

## Short answer

- `packages/sheet` exists and builds.
- Its `Sheet` filter passes **80/80** (`$S/test-sheet-final-2.log`, long testem config): 54 integration tests and 26 unit tests.
- ESLint, `ember-tsc`, stylelint and Prettier pass on the package.
- After the spike code was deleted from core's tests, core's `EuiDataGrid` filter still passes 88/88.
- `scripts/dist-hygiene.test.mjs`, with `'sheet'` added, passes 9/9. `docs:api:check` passes.
- **The lockfile was not copied back.** The one non-frozen install also changed one line outside the new importer (section 8). Following design 11.2, I stopped that step and am reporting it.

## 1. What was built

`packages/sheet/` (all new):

| Path | What |
| --- | --- |
| `package.json` | `@ember-eui/sheet` 16.1.4, not private, peer `@ember-eui/core ^16.0.0`, deps `@babel/core`, `@ember/test-waiters`, `@embroider/addon-shim`, `decorator-transforms`, `ember-modifier`; devDependencies copied from validated-form; exports `.`, `./core`, `./*`, `./addon-main.js`; `app-js` only `components/eui-sheet.js` (unchanged by the build). |
| `.env.development`, `.gitignore`, `.npmignore`, `.stylelintignore`, `.stylelintrc.cjs`, `LICENSE.md`, `addon-main.cjs`, `babel*.cjs`, `config/ember-cli-update.json`, `rollup.config.mjs`, `testem.cjs`, `tsconfig*.json`, `vite.config.mjs`, `tests/deprecations.ts`, `tests/helpers/index.js`, `tests/test-helper.ts`, `unpublished-development-types/**` | Copied unchanged from `packages/validated-form`. |
| `tests/index.html` | Copied; title `@ember-eui/sheet Tests`. |
| `eslint.config.mjs` | Copied, plus the `src/core` block of design 3.2. |
| `README.md` | Design 13 plus "Using another date picker", messages and `@validate`. |
| `src/index.ts` | Barrel: the core, `EuiSheet`, `localRecords`/`LocalRecords`, the Ember-layer built-in types (`textType`, `numberType`, `checkboxType`, `singleSelectType`, `dateType`, `builtInSheetFieldTypes`), `SheetInputEditor`, and the types. |
| `src/core/{index,types,messages,tsv,fields,change-set,errors}.ts`, `src/core/field-types/{index,text,number,checkbox,single-select,date}.ts` | The plain-TS core (1,071 lines with comments). Core type objects are named `textFieldType` and so on, so they don't clash with the Ember-layer `textType` and so on. |
| `src/local-records.ts`, `src/field-types.ts`, `src/types.ts` | Ember layer. |
| `src/components/eui-sheet.gts` | `EuiSheet`. |
| `src/-private/{sheet-cell,editor-frame}.gts`, `cells/{checkbox,select}-cell.gts`, `editors/{input,select,date}-editor.gts`, `styles.ts` | Cell renderer, editor frame, built-in cells and editors, `ensureStyles()`. |
| `tests/helpers/sheet.ts`, `tests/unit/*-test.ts` (5), `tests/integration/components/eui-sheet{,-types,-custom-type,-i18n,-validate}-test.gts` | Tests. |

Source: 2,813 lines including comments (the design estimated 1,700). Tests: 3,364 lines.

Outside the package:

| File | Change |
| --- | --- |
| `.changeset/sheet-initial-release.md` | New, `'@ember-eui/sheet': minor`. |
| `scripts/dist-hygiene.test.mjs` | `'sheet'` added to `PACKAGES`. |
| `packages/core/tests/spikes/**`, `tests/integration/spikes/**`, `tests/unit/spikes/**` | Deleted (7 files, unstaged deletions). |
| `internal/spikes/sheet/RESULTS.md` | Section 8 appended. |
| `pnpm-lock.yaml` | **Unchanged** (section 8). |

`packages/core/src` is untouched (`git status` shows no change under it).

## 2. The user's four decisions

| Q | Decision | Implementation |
| --- | --- | --- |
| Q10 | `@validate` in v0.1 | It is one optional argument, `@validate(ctx: ValidateContext<T>) => CellErrors \| Promise<CellErrors>`, with `{ records, changed, signal }`. There is no `@recordRules`: record rules are written inside `validate`. A function modifier on the wrapper schedules a run on first render and whenever `@records` is a new array. `emit()` also schedules one after each change set. Both go through `debounce` from `@ember/runloop` (50 ms), so they merge and `settled()` sees them. Each run has a sequence number and an `AbortController`: a new run aborts the previous one, and its result is applied only if its number is still the latest and it was not aborted. The result is stored with the record objects the run started with, and the render drops an error for a record whose object changed since (the per-cell identity check of 9.4, applied at render time). An async run holds an `@ember/test-waiters` waiter, ended when the run settles, is superseded or the sheet is destroyed. `willDestroy` cancels the debounce and aborts. Merge order: rejection or (required, type, field rules), then `@validate`, then `@cellErrors`. Tests VA1–VA6 cover a record rule, a unique email, the merge order, stale async plus abort, the identity drop and abort on destroy. Two mutations confirmed that VA4 and VA5 fail without their guard (section 4). `@onResolve` is not implemented. |
| Q2 | Native + text date editor, easy to swap | `DateEditor` renders `<input type="date">` for Enter, F2 and double-click, and `InputEditor` when opened with a digit. **Primary way to swap it: `@fieldTypes` with `{ ...dateType, editor: MyEditor }`** under `date` or another name. No per-field `editor` override: fields stay plain data, as P11 intends. `dateType` and the other built-ins are exported, and so is `SheetInputEditor`, so a custom editor can keep the typed-digit path. Test C4 replaces the date editor with a fake picker whose calendar is rendered outside the wrapper and marked `euiSheetEditorSurface`. The README has the section "Using another date picker (e.g. @ember-eui/flatpickr)". flatpickr is not a dependency. |
| Q6 | Messages through `eui-i18n` | The core has `sheetMessageTokens` (`euiSheet.<key>` → English default with `{placeholders}` and the parameter names) and `createMessages(translate?)`, where `translate` is `(token, default, values) => string`. Without it the English defaults are used (`defaultMessages`). The core imports nothing from Ember. `EuiSheet` builds its messages once with `euiI18n.lookupToken(token, default, values)`, the same call core's components make, so `addTranslations({ euiSheet: { … } })` translates them. `@messages` is spread over them, so the precedence is `@messages` > translation > English. Change-set `rejected[].message` is translated too. The English defaults are asserted in a unit test and in I1. I2 provides Spanish for two tokens; I3 shows `@messages` wins. |
| Q1 | Shared 16.x version, publishable | `version: "16.1.4"`, no `private`, `publishConfig.access: public` (copied). `.changeset/config.json` has no fixed or linked groups. Siblings add a changeset only for the package that changed, and the release commit then bumps the others by hand to the same version (the "Released with … to keep all packages on the same version" entries in 16.1.4). So the changeset names only `@ember-eui/sheet` (`minor`): `changeset version` would make it 16.2.0 while the siblings stay 16.1.4 unless they get their usual entries. The core peer range is `^16.0.0`, following the siblings as the brief says; the design had `^16.1.4`. The sheet is only tested against core 16.1.4. Nothing was published, and `changeset version` was not run. |

## 3. Verification items V1–V7

| # | Outcome |
| --- | --- |
| V1 | `scripts/sync-injected.mjs` **fails in scratch, but not because of the sheet**. It throws ENOENT on validated-form's injected copy (`@ember-eui+validated-form@file+packages+validated-form_…`): the lockfile already had that snapshot before the sheet (`$S/pnpm-lock.before.yaml`), but this install did not create it (`$S/sync-injected.log`, `$S/sync-injected-2.log`). It also showed that **the sheet needs the step**: pnpm resolved the sheet's `@ember-eui/core` as an injected copy (`file:packages/core(b756…)`), not `link:../core` as for the siblings. That copy only gets core's `dist`/`declarations` through the injected-deps sync. In scratch I synced core alone with the same pnpm API (`$S/sync-core.mjs`, `$S/sync-core.log`). Per package, with the same API (`$S/sync-one-<pkg>.log`): `sheet` (the package no one injects) passes, and so do `core`, `changeset-form`, `flatpickr` and `pikaday`; only `validated-form` fails. So the step works for the sheet and stays in its `test` script, as in the siblings. |
| V2 | `node scripts/generate-api-docs.mjs --check` exits 0 with the sheet's undocumented `eui-sheet.gts` in the tree (`$S/docs-api-check.log`). No docs page added. |
| V3 | validated-form's `tests/test-helper.ts` is enough: `EuiDataGrid`, `EuiSelectable`, `EuiBadge` and `EuiPanel` render and work (smoke test, then all 80 tests). Nothing was added; the helper is unchanged. |
| V4 | Not run: the brief forbids `changeset version`. It does not apply any more, since the package is not private. |
| V5 | Measured (`$S/test-smoke-4.log`, N11, N12). (a) Opened with Enter (empty search), the **checked option is current** at once (`aria-activedescendant` set), not "no option" as the design expected. N11 therefore needs 1 ArrowDown to reach `Closed`, not 2, and Enter on a cell's current value picks it directly. (b) Opened by typing (seeded `defaultValue`), **no option is current** and Enter would pick nothing. I used the design's fallback: `SelectEditor` keeps the matching options from `searchProps.onChange` and EuiSelectable's current option from `@onActiveOptionChange`. When there is no current option and the search is not empty, its capture listener commits the first match on Enter and Tab. Tested in N12 (Tab) and the new "N12 … Enter after typing". (c) The option passed to `@onChange` keeps `data` (N11, N12 click). (d) `inputRef` runs once, with the input focused. (e) On an empty cell (value `null`) opened with Enter, no option is current, and Enter does nothing; the editor stays open, as in the design's key table (scratch-only check, `$S/test-smoke-empty-select.log`). |
| V6 | The panel is neither clipped nor covered. N21 renders 30 rows at 400 px and checks with `elementFromPoint`: below row 0, the panel's top and bottom are painted. On the last fully visible row it flips above (its bottom is at or above the cell's top) and is painted. Headless Chrome 1440×900 with the package's test page; a real app layout is not covered. |
| V7 | `setCellProps({ title, 'aria-invalid', className })` reaches the cell element as attributes (smoke test, then every `cellTitle`/`isInvalid` assertion). No grid change was needed. |

V8 (trusted events) is left to the orchestrator. The demo test `Integration | Component | EuiSheet: demo (manual)` renders one field of each type, 50 records and `@height={{400}}`, and pauses only with `?sheetdemo`. It also sets `window.sheetStore` (the `localRecords` store) for inspection. I loaded it once (headless Chrome `--dump-dom` through `vite preview`, `$S/demo-dom.html`): 5 column headers, 55 rendered cells (11 rows), 11 chips, 11 checkboxes, dates shown as `DD/11/2026`, no QUnit failure. The built page is at `$S/ember-eui/packages/sheet/dist-tests` (from the final run, `$S/test-sheet-final-2.log`): `cd $S/ember-eui/packages/sheet && pnpm exec vite preview --outDir dist-tests --port 4173 --host 0.0.0.0`, then `/tests/index.html?filter=demo&sheetdemo`.

## 4. Tests (final run `$S/test-sheet-final-2.log`: 80 pass, 0 fail)

| # | Module | Test | Result |
| --- | --- | --- | --- |
| 1 | Integration \| Component \| EuiSheet custom type | C1 a cell component and navKey | pass |
| 2 | Integration \| Component \| EuiSheet custom type | C2 an editor that claims keys and commits itself | pass |
| 3 | Integration \| Component \| EuiSheet custom type | C3 an editor surface outside the wrapper | pass |
| 4 | Integration \| Component \| EuiSheet custom type | C4 the date type with another date picker | pass |
| 5 | Integration \| Component \| EuiSheet messages | I1 English defaults | pass |
| 6 | Integration \| Component \| EuiSheet messages | I2 a translation through eui-i18n | pass |
| 7 | Integration \| Component \| EuiSheet messages | I3 @messages wins over a translation | pass |
| 8 | Integration \| Component \| EuiSheet | T1 type-to-edit, Enter saves and moves down | pass |
| 9 | Integration \| Component \| EuiSheet | T2 Enter and F2 edit the current value, Esc cancels | pass |
| 10 | Integration \| Component \| EuiSheet | T3 Tab saves and moves right, Shift+Tab left, clamps | pass |
| 11 | Integration \| Component \| EuiSheet | T4 Shift+arrows select a range, Delete clears it | pass |
| 12 | Integration \| Component \| EuiSheet | T5 copy gives the range as TSV | pass |
| 13 | Integration \| Component \| EuiSheet | T6 paste a 2x3 block at the last row inserts a row | pass |
| 14 | Integration \| Component \| EuiSheet | T7 the selection class survives virtualization | pass |
| 15 | Integration \| Component \| EuiSheet | T8 the grid's Enter/F2 popover stays closed | pass |
| 16 | Integration \| Component \| EuiSheet | T9 clicking another cell commits and does not steal focus | pass |
| 17 | Integration \| Component \| EuiSheet | T10 scrolling while editing commits without a focus fight | pass |
| 18 | Integration \| Component \| EuiSheet | T11 the editor is outside the grid and tabbable | pass |
| 19 | Integration \| Component \| EuiSheet | T12 arrows while editing do not move grid focus | pass |
| 20 | Integration \| Component \| EuiSheet | T13 header cells keep their keys | pass |
| 21 | Integration \| Component \| EuiSheet | T14 read-only fields | pass |
| 22 | Integration \| Component \| EuiSheet | T15 Enter on the last row keeps focus there | pass |
| 23 | Integration \| Component \| EuiSheet | T16 copy and paste dispatched on the cell content | pass |
| 24 | Integration \| Component \| EuiSheet | demo (manual) | pass |
| 25 | Integration \| Component \| EuiSheet field types | N1 number: typing saves a number | pass |
| 26 | Integration \| Component \| EuiSheet field types | N2 number: paste of abc gives a cell error | pass |
| 27 | Integration \| Component \| EuiSheet field types | N3 number: typing an invalid text | pass |
| 28 | Integration \| Component \| EuiSheet field types | N4 a rejection is cleared by Delete | pass |
| 29 | Integration \| Component \| EuiSheet field types | N5 a mixed paste | pass |
| 30 | Integration \| Component \| EuiSheet field types | N6 checkbox: Space toggles | pass |
| 31 | Integration \| Component \| EuiSheet field types | N7 checkbox: click toggles, other keys do nothing | pass |
| 32 | Integration \| Component \| EuiSheet field types | N8 checkbox: paste | pass |
| 33 | Integration \| Component \| EuiSheet field types | N9 Space on a text cell does nothing | pass |
| 34 | Integration \| Component \| EuiSheet field types | N10 select: the cell shows a chip | pass |
| 35 | Integration \| Component \| EuiSheet field types | N11 select: pick with the keyboard | pass |
| 36 | Integration \| Component \| EuiSheet field types | N12 select: type to filter, Tab, Escape, click | pass |
| 37 | Integration \| Component \| EuiSheet field types | N12 select: Enter after typing takes the first match | pass |
| 38 | Integration \| Component \| EuiSheet field types | N21 the select panel is not clipped and flips above near the bottom (V6) | pass |
| 39 | Integration \| Component \| EuiSheet field types | N13 select: options that depend on the record | pass |
| 40 | Integration \| Component \| EuiSheet field types | N14 select: paste of an unknown value | pass |
| 41 | Integration \| Component \| EuiSheet field types | N15 select: createOnPaste | pass |
| 42 | Integration \| Component \| EuiSheet field types | N16 date: paste | pass |
| 43 | Integration \| Component \| EuiSheet field types | N17 date: editors | pass |
| 44 | Integration \| Component \| EuiSheet field types | N18 required field cleared | pass |
| 45 | Integration \| Component \| EuiSheet field types | N18 required as a function of the record | pass |
| 46 | Integration \| Component \| EuiSheet field types | N19 owner @cellErrors | pass |
| 47 | Integration \| Component \| EuiSheet field types | N20 @readOnly and a read-only function | pass |
| 48 | Integration \| Component \| EuiSheet field types | N20 a read-only function on one field | pass |
| 49 | Integration \| Component \| EuiSheet validate | VA1 a record rule puts the error on the end date | pass |
| 50 | Integration \| Component \| EuiSheet validate | VA2 a cross-row rule: unique emails | pass |
| 51 | Integration \| Component \| EuiSheet validate | VA3 merge order: type rules, then @validate, then @cellErrors | pass |
| 52 | Integration \| Component \| EuiSheet validate | VA4 async: a stale slow response is discarded, the older run is aborted | pass |
| 53 | Integration \| Component \| EuiSheet validate | VA5 async: an error of a record changed since its run started is dropped | pass |
| 54 | Integration \| Component \| EuiSheet validate | VA6 destroying the sheet aborts a pending run | pass |
| 55 | Unit \| Sheet \| change sets | U1 toRange normalizes two positions | pass |
| 56 | Unit \| Sheet \| change sets | U4 commitText | pass |
| 57 | Unit \| Sheet \| change sets | U5 clearRange | pass |
| 58 | Unit \| Sheet \| change sets | U6 pasteMatrix | pass |
| 59 | Unit \| Sheet \| change sets | U7 rangeMatrix | pass |
| 60 | Unit \| Sheet \| change sets | U8 localRecords().apply | pass |
| 61 | Unit \| Sheet \| change sets | U9 commitText of an unreadable text gives a rejection, no patch | pass |
| 62 | Unit \| Sheet \| change sets | U10 commitValue | pass |
| 63 | Unit \| Sheet \| change sets | U11 readOnly as a function of the record, and sheet-level readOnly | pass |
| 64 | Unit \| Sheet \| change sets | U12 pasteMatrix with createOnPaste | pass |
| 65 | Unit \| Sheet \| change sets | U13 pasteMatrix past the end with a rejected cell | pass |
| 66 | Unit \| Sheet \| change sets | U14 applyNewOptions and localRecords({ fields }) | pass |
| 67 | Unit \| Sheet \| core boundary | B1 src/core has no Ember imports | pass |
| 68 | Unit \| Sheet \| errors | E1 validateCell: required | pass |
| 69 | Unit \| Sheet \| errors | E2 validateCell: type rules, then field.validate | pass |
| 70 | Unit \| Sheet \| errors | E3 mergeErrors and compareValues | pass |
| 71 | Unit \| Sheet \| errors | messages: English defaults, tokens, a translate function | pass |
| 72 | Unit \| Sheet \| field types | F1 text | pass |
| 73 | Unit \| Sheet \| field types | F2 number | pass |
| 74 | Unit \| Sheet \| field types | F3 checkbox | pass |
| 75 | Unit \| Sheet \| field types | F4 singleSelect | pass |
| 76 | Unit \| Sheet \| field types | F5 singleSelect with options from the record | pass |
| 77 | Unit \| Sheet \| field types | F6 date | pass |
| 78 | Unit \| Sheet \| field types | F7 parse(copyText(v)) gives v; the registry | pass |
| 79 | Unit \| Sheet \| tsv | U2 parseTsv | pass |
| 80 | Unit \| Sheet \| tsv | U3 toTsv(parseTsv(x)) round-trips a block without trailing newline | pass |

New beyond the design: the second N12 (Enter fallback), N21 (V6), C4 (Q2), I1–I3 (Q6), VA1–VA6 (Q10), the messages unit test. N18 and N20 are two tests each. The same 80 names passed in `$S/test-sheet-final.log` before the last README change.

Earlier runs and what they found: `$S/test-unit-1.log` 26/26; `$S/test-int-1.log` 43/43; `$S/test-int-2.log` 25/29 (option-label helper read EuiSelectable's screen-reader text, and N11's V5 expectation); `$S/test-int-3.log` 19/22 (a real bug, D1 below); `$S/test-int-5.log` 22/22; `$S/test-int-6.log` 78/78; `$S/test-sheet-full-1.log` 80/80 (after Prettier).

Mutation checks of the `@validate` guards, run in scratch only and then restored:

- `$S/test-mutation-A.log`: without the sequence/abort check, VA4 fails (5/6).
- `$S/test-mutation-B.log`: without the record-identity check, VA5 fails (5/6).

## 5. Regression and root checks

| Check | Result | Log |
| --- | --- | --- |
| Core `EuiDataGrid` filter, after deleting the spike tests, long config | 88/88 | `$S/test-core-grid.log` |
| `node --test scripts/dist-hygiene.test.mjs` with `'sheet'` (the scratch copy has it at line 106); all six packages built (core `build:js`, the sheet `pnpm build`, the four siblings `build:js`) | 9/9 | `$S/test-dist-hygiene.log` |
| `node scripts/generate-api-docs.mjs --check` (`pnpm docs:api:check`) | exit 0 | `$S/docs-api-check.log` |
| Sheet `pnpm build` (rollup + ember-tsc) | exit 0. `dist/index.js`, `dist/core/index.js`, `dist/components/eui-sheet.js` and `dist/_app_/components/eui-sheet.js` exist, along with `declarations/index.d.ts` and `declarations/core/index.d.ts`. `package.json` is byte-identical after the build. | `$S/sheet-build.log` |

`scripts/generate-llms-txt.mjs` was not changed (no docs folder, design 13).

## 6. Lint, types, Prettier (the sheet)

- `pnpm lint` (stylelint, `eslint .`, `ember-tsc --noEmit`): all exit 0 (`$S/sheet-lint-final.log`).
- The `src/core` import rule fires on an added `@ember/object` import and on `../local-records.ts` (`$S/static-eslint-boundary.log`, scratch only, reverted).
- Prettier is clean on `src`, `tests/helpers/sheet.ts`, `tests/unit`, `tests/integration` and `README.md` (formatted in scratch, copied back).
- Not formatted: the copied `tests/deprecations.ts`, `tests/helpers/index.js` and `tests/index.html`, which fail Prettier identically in `packages/validated-form`. They are kept as copies.
- `ember-tsc -p tsconfig.eslint.json`, which also checks the tests: the only errors are in the copied `tests/deprecations.ts` and `tests/test-helper.ts` (`$S/static-tsc-tests-2.log`). `packages/validated-form` has the same two errors and 21 more (`$S/static-tsc-tests-validated-form.log`). The repo does not type-check tests.

## 7. Deviations (from the design or the brief), with reasons

| # | What | Why |
| --- | --- | --- |
| D1 | The editor is rendered with `{{#each this.editingList key="@identity"}}` instead of `{{#if this.editing}}`. | With `#if`, EuiSelectable's blur handler, scheduled in the `actions` queue, read `@options` after the edit ended and before teardown. `@field` was then `undefined` and `fieldOptions` threw (`$S/test-int-3.log`, N11/N13). Keyed `#each` gives each edit its own editor instance whose args stay those of its edit. |
| D2 | `EditorFrame` also listens to `focusout` on `document` (capture) for focus leaving an editor surface outside the frame. | The frame's own `focusout` cannot see focus moving from a wormholed surface to a grid cell, so design case C3 ("focusing a grid cell closes it") would fail. |
| D3 | `SelectEditor` commits the first match on Enter and Tab when no option is current and the search is not empty. | V5 fallback (section 3). |
| D4 | N11 expects 1 ArrowDown, not 2, and its second part presses Enter directly. N12's mouse pick clicks `Closed`, not `Open`. | V5(a): the checked option is current on open. In N12, row 1 is already `open`, so a click on `Open` gives no patch while the design expects one. |
| D5 | A rejected cell also skips `@validate` results; it shows only the rejection and `@cellErrors`. | Design 9.4 skips layers 2–4 for a rejected cell. Layer 4 now lives inside `@validate` and cannot be separated from 5–6, and all of them describe the old stored value. |
| D6 | `@ember/test-waiters` added to `dependencies`. | So `settled()` waits for async `@validate` runs (Q10). Same specifier as validated-form's (`^4.1.1`). |
| D7 | Peer `@ember-eui/core ^16.0.0` (design `^16.1.4`), version 16.1.4, not private (design 0.0.0, private). | Brief (Q1): follow the siblings. |
| D8 | Messages: `SheetMessages` stays the interface; the core adds `sheetMessageTokens`, `createMessages(translate)` and `interpolate`. `@messages` is merged over the translated messages. | Brief (Q6). |
| D9 | `@validate` debounce is a fixed 50 ms; there is no argument for it. | The brief allows one argument. |
| D10 | Extra class `euiSheet__editor--cell` next to `--panel`. `SheetEditorRect` has `wrapperHeight`, needed for the "above" placement. `CellView` is exported. | Implementation detail. |
| D11 | New tests beyond the design: N12 Enter fallback, N21 (V6), C4 (Q2), I1–I3 (Q6), VA1–VA6 (Q10), a messages unit test. Two-part cases are split (two N18, two N20). | Brief. |
| D12 | En dashes removed from comments in `.gts` files. | `ember-eslint-parser` reported "Unterminated string literal" in every `.gts` file with a non-ASCII character before its first `<template>` (a byte/char offset mismatch). |
| D13 | **The lockfile was not copied back** (section 8). | Design 11.2 / brief: stop and report when the diff has anything but the new importer. |
| D15 | Two more `pnpm install --no-frozen-lockfile --lockfile-only` runs in scratch (a control without `packages/sheet`, and the sheet with validated-form's full dependency list); design 11.2 allows one non-frozen install. | To find where the extra lockfile line comes from after the diff failed. Each restored `pnpm-lock.yaml` and `package.json` in scratch afterwards (`$S/install-control.log`, `$S/install-exp1.log`); neither touched `node_modules` or the checkout. |
| D14 | The design's `{{#if this.editing}}` `@value`/`@record` getters became `editorValue(editing)` / `editorRecord(editing)`, read live from `@records`. | Follows from D1. |

## 8. Lockfile

One non-frozen install in scratch:
`pnpm install --no-frozen-lockfile --store-dir $S/pnpm-store` (`$S/install.log`, exit 0).

`diff $S/pnpm-lock.before.yaml pnpm-lock.yaml` (`$S/lock.diff`) has 251 added lines and **1 removed**:

1. The `packages/sheet:` importer block (after `packages/pikaday`). Its versions are the siblings', except `@ember-eui/core: file:packages/core(b756b225…)`, an injected copy. The siblings have `link:../core`. That variant already existed in the lockfile.
2. **Outside the importer**, in the snapshot `'@rollup/plugin-node-resolve@16.0.0(rollup@4.63.5)'`: `resolve: 1.22.8` → `resolve: 1.22.12`. Both versions were already in the lockfile, so no new package is added.

The same install without `packages/sheet` changes nothing (`--lockfile-only`, `$S/install-control.log`). With validated-form's full dependency list, it produces the same importer shape and the same `resolve` line (`$S/install-exp1.log`, `$S/lock-exp1.diff`). So the change comes from pnpm 12.6 resolving a new importer, not from the sheet's dependency choices.

Per the design I did not copy the lockfile back. The resulting lockfile is `$S/pnpm-lock.after.yaml` if you choose to accept it.

## 9. Commands for the Mac

```bash
cd ~/prysmex/ember-eui
pnpm install                          # writes the packages/sheet importer; expect the diff of section 8
git diff --stat pnpm-lock.yaml        # review: the importer + resolve 1.22.8 -> 1.22.12 in @rollup/plugin-node-resolve@16.0.0
pnpm --filter @ember-eui/core build   # expected to sync core's injected copy into packages/sheet (syncInjectedDepsAfterScripts: build); not observed here
pnpm --filter @ember-eui/sheet lint
pnpm --filter @ember-eui/sheet test   # runs scripts/sync-injected.mjs first (V1)
pnpm --filter @ember-eui/sheet build
pnpm build:packages && pnpm test:dist # dist hygiene, now with 'sheet'
pnpm docs:api:check
```

If `pnpm --filter @ember-eui/sheet test` fails in `sync-injected.mjs` with ENOENT on validated-form's injected copy (as in scratch), that is the existing orphan snapshot of V1, not the sheet: the siblings' `test` scripts run the same script over every package.

## 10. Open issues

- **The lockfile decision** (section 8): accept `pnpm install`'s diff, or find why pnpm 12.6 injects core into the new importer and re-resolves `resolve`.
- The sheet's core is an injected copy, not a link. Edits to core should reach the sheet's tests after core's `build`, which runs the sync (not observed here), or after `sync-injected.mjs`.
- **Publish hazard**: the package is not private, and `@ember-eui/sheet` is a new name (npm not checked from here). `pnpm release` (`changeset publish`) would publish it as it is, even before `changeset version` runs. This is why the design had `private: true` (P12).
- **Release alignment**: a `minor` changeset takes the sheet to 16.2.0. The siblings need their usual "released with" entries to stay on the same version.
- **V8**: trusted events for the new editors (the orchestrator). Firefox, Safari and IME are untested.
- The **N21 panel check** covers the package's test page only; an app container with `overflow: hidden` around the sheet would clip a panel that extends below the grid.
- Rejections of pasted rows show only when the owner keeps the `tempId` as the id (Q4 default, documented).
- The README's flatpickr example was written from `eui-flatpickr.gjs`'s documented arguments and was not run.
- Not done (out of scope): bulk resolve on paste (`@onResolve`), a docs-site page, theming (Q5).

## 11. Trusted events in Chromium (V8, added by the orchestrator, 2026-11-19)

Real input (Playwright `keyboard.press`, real clicks) on the `demo (manual)`
page of the sheet package, served with `vite preview --outDir dist-tests`
from the scratch copy. All checks passed; no fix was needed.
Screenshot: `sheet-demo.png` (the test container renders at 50%).

| Check | Result |
| --- | --- |
| Select: click a status cell, press `h` | Editor opens with the search `h`; only "On hold" is listed |
| Then Enter | Saved as `hold`, panel closed, focus on the cell below |
| Select: Enter on "Open", ArrowDown, Enter | Saved as `closed`, focus on the cell below |
| Checkbox: click the cell | Selects the cell only (no toggle), as designed |
| Checkbox: Space | Toggles `false` → `true`, one change set |
| Date: press `1`, type `9/11/2026`, Enter | Text editor; stored `2026-11-19`, shown `19/11/2026`, focus below |
| Ctrl+C on a text cell, Ctrl+V on a number cell | Rejected: record unchanged, cell shows the text, `aria-invalid="true"`, title `"name1" is not a number` |
| Ctrl+V of the same text on a select cell | Rejected: `"name1" is not an option`; the change set has `rejected` and no patch |

Not checked: the native `<input type="date">` path (Enter/F2 on a date
cell; its calendar is browser UI), `createOnPaste`, Firefox, Safari, IME.

## 12. Docs (docs-site page, 2026-11-19)

Logs are in `$S` (the scratchpad above). Nothing committed. The
packages' `dist` folders in scratch were rebuilt for the last site build
and are kept (about 26 MB), so the site can be rebuilt there.

### Pages

Following the flatpickr and validated-form convention, the demos are
files in `packages/sheet/docs/sheet-demo/`, which docfy renders **on the
landing page**, not as separate pages. There is one new URL:
**`/docs/sheet/docs/sheet`** (side nav label "Sheet", read in the
real-input pass). Its "Examples"
heading is placed with `[[demos-all]]` after the prose, as on the icons
page.

| File | What |
| --- | --- |
| `packages/sheet/docs/sheet.md` | Landing: what it is, install, records in / change sets out, `localRecords`, `applyChangeSet` / `applyNewOptions`, an arguments table, the field types table, the keyboard table, the error model, "Not yet". |
| `sheet-demo/d01-basics.md` | 20 records in `localRecords`, a panel with the last 3 change sets (`patches`, `inserts`, `rejected`). |
| `sheet-demo/d02-field-types.md` | Text (`maxLength`), number (`min`/`max`), checkbox, singleSelect with coloured options, date (`min`), `required`; two rows start with errors. |
| `sheet-demo/d03-validation.md` | `@validate`: record rule (End before Start), cross-row rule (unique email), a fake 800 ms server check (blocked domains) that rejects on abort; a list of runs shows "discarded" / "applied"; **Save** sets `@cellErrors`. |
| `sheet-demo/d04-custom-cells.md` | App type `zone` with an async `EuiSelectable` editor (fake API, 400 ms, `@isPreFiltered`, `@isLoading`, `@errorMessage`, type `fail` for the error), zones by the row's Site; Position with `options(record)` by Area; Company `readOnly`/`required` as functions of Contractor. |
| `sheet-demo/d05-paste-rules.md` | Strict select (unknown value rejected) vs `createOnPaste` (shows `newOptions` and the grown option list); a block to copy and a copy button. |
| `sheet-demo/d06-date-picker.md` | `{ ...dateType, editor: FlatpickrDateEditor }` with `@ember-eui/flatpickr`; a digit still opens `SheetInputEditor`. |
| `sheet-demo/d07-translations.md` | English / Español through `euiI18n.addTranslations` (English put back from `sheetMessageTokens` on switch-back and on destroy; the sheet is re-created on a switch), and an `@messages` switch. |
| `sheet-demo/d08-large-data.md` | 10,000 generated rows; shows how long each change set took to apply. |

The editor in d04 copies the built-in select editor's V5 handling: Enter
with a typed search and no current option picks the first result.

### Site wiring (repo-relative)

- `site/docfy.config.mjs`: `'sheet'` added to the package sources. No
  `labels` entry needed (humanized to "Sheet").
- `site/package.json`: `"@ember-eui/sheet": "workspace:*"`.
- `scripts/generate-llms-txt.mjs`: `'sheet'` in `PACKAGES`.
- `site/lib/demo-playgrounds.mjs` (+ its test): `@ember-eui/sheet` is
  added to a playground when a demo uses `EuiSheet`. Whether
  `@ember-eui/sheet` is on npm was not checked; if it is not, "Open in
  StackBlitz" on these demos will not install.
- `site/tests/acceptance/docs-test.ts`: side nav count 125 → 126 (the new
  item; `$S/docs-site-test-1.log` failed only on that count).
- No style import: the sheet adds its own `<style>`. No
  `scripts/api-docs-pages.json` entry (below). `docs/` needed nothing.

### Lockfile: not copied back

One non-frozen install in scratch (`$S/docs-install.log`); diff in
`$S/docs-lock.diff`. Two hunks:

1. The wanted one: `@ember-eui/sheet: link:../packages/sheet` under the
   `site` importer (the siblings are `link:` too).
2. **Outside it**: in the `packages/sheet` importer,
   `@ember-eui/core: file:packages/core(b756b225…)` →
   `link:../core` (what the sibling packages have).

A control run without the `site/package.json` change
(`--lockfile-only`, `$S/docs-install-control.log`) changes nothing
(`$S/docs-lock-control.diff` is empty), so adding the site dependency
makes pnpm 12.6 re-resolve the sheet's core. Per the brief the repo's
`pnpm-lock.yaml` is unchanged; the full resulting lockfile is
`$S/docs-lock.after.yaml`. **Until `pnpm install` runs on the Mac, a
`--frozen-lockfile` install fails** (the site's specifiers changed).

### Tests and lint

| Check | Result | Log |
| --- | --- | --- |
| Site tests (testem, development build, long config): `Acceptance \| docs` (incl. the four "every docs page renders" groups, which visit `/docs/sheet/docs/sheet`) and `Acceptance \| code splitting`, final files | **14/14** | `$S/docs-site-test-final.log` |
| Earlier run with all eight demos, before the flatpickr fix | 14/14 | `$S/docs-site-test-2.log` |
| `node --test site/lib/*.test.mjs` | 8/8 | `$S/docs-site-lib-tests.log` |
| Prettier + ESLint on the touched site files | clean | `$S/docs-site-lint-files-1.log` |
| `pnpm lint` in `packages/sheet` | exit 0 (eslint, stylelint, ember-tsc) | `$S/docs-sheet-lint.log` |
| `pnpm docs:api:check` (`node scripts/generate-api-docs.mjs --check`) | exit 0 | `$S/docs-api-check-docs.log` |
| Leak crawler, `routes` mode, 20 reps, production build | 0 listeners, nodes, timers, observers left; heap +1.06 MB (data-grid basics: +4.57 MB) | `$S/docs-leak-3.log` |
| Real input over CDP (trusted keys, clicks, Ctrl+C/V with the real clipboard) on the final production build served by `vite preview`, `$S/docs-real-input.mjs` | **41/41** | `$S/docs-real-input-final-4.log` (first runs: `-1` crashed on a virtualized row, `-2` 31/37 from smooth-scroll misclicks in the script and the flatpickr bug below) |

The real-input pass covers every demo: typing, a rejected `abc`, range
+ Delete, a 2-row paste that inserts, select type-to-filter + Enter,
Space on a checkbox, the three `@validate` rules and a discarded run,
`@cellErrors`, the zone editor (load, pick, error state, typed search +
Enter, paste rejected as unresolved), record-dependent options,
conditional read-only, `createOnPaste`, the flatpickr calendar (open,
pick a day) and the digit path, Spanish, `@messages`, and a 21-cell
clear on 10,000 rows, a 303-row Shift+click range cleared, Ctrl+End to
the last cell, and the side nav label ("Sheet"). Tab on a cell moves
focus out of the grid, to the next element on the page (recorded in the
log; the keyboard table says so). Not checked: Firefox,
Safari, touch, the dark theme, screen readers.

Not run by the scratch build: `scripts/sync-injected.mjs` fails with
ENOENT on the orphan injected-core snapshot (as in section 10); the
site consumes the packages as links, so the build steps were run one by
one (`$S/docs-site-build.sh`). docfy prints an `ERR_INVALID_ARG_TYPE`
from its repo-info step because the scratch copy has no `.git`; the
pages are generated anyway.

### Package bugs and API gaps found by the demos

1. **Bug: a focused editor surface element removed from the DOM closes
   the editor.** `src/-private/editor-frame.gts` (`watchSurfaces` /
   `onFocusOut`) treats a `focusout` with `relatedTarget === null` from
   an `euiSheetEditorSurface` element as leaving the editor. flatpickr
   focuses the clicked day and then redraws the days, so the focused
   day is removed: the sheet commits (nothing) and closes the editor,
   and flatpickr's `onChange` then finds no edit. Repro: the README's
   flatpickr example (or d06 without its `mousedown` handler), Enter on
   a date cell, click a day: the date is not saved
   (`$S/docs-flatpickr-repro.log`: without the handler the cell keeps
   its value; the focusout log shows `flatpickr-day -> null`). The demo
   works around it like the built-in select editor: `mousedown`
   `preventDefault` on the calendar keeps focus in the input. **The
   README's flatpickr example has this bug** and should get the same
   line (and `@date` coalesced to `null`: EuiFlatpickr asserts on
   `undefined`, which `@value` is for a record without the field). A package fix: on a `focusout` without a
   `relatedTarget`, check `document.activeElement` after a frame
   instead of closing at once.
2. **`eui-i18n` translations are not tracked** (from the source, not
   run: core's `translations` is a plain field), so `addTranslations` after a sheet rendered does
   not update its cells; the demo re-creates its sheet. The service is
   also global: while Español is on, any other sheet on the page uses
   it (said in the demo).
3. **No API reference section**: `scripts/generate-api-docs.mjs` throws
   "No signature found for EuiSheet" because `EuiSheetSignature` lives
   in `src/types.ts`, not in the component file. The arguments table in
   `sheet.md` is hand-written, without `api:` markers.
4. **Range keys** (from the source, not run, except Shift+arrows and
   Shift+click, which the real-input pass uses): only Shift+arrows and
   Shift+click extend a range (`onKeyDown` sets `extending` for arrows
   only). Shift+Home/End, Ctrl+Shift+End and Page Up/Down do not (the
   grid's Page Up/Down do nothing without pagination). On 10,000 rows a large
   range needs Shift+click.
5. **Error messages are only in the cell's `title`** (hover). There is
   no visible or keyboard-reachable message (the cell has
   `aria-invalid`).
6. From the source, not run: no Shift+Enter (Enter always moves down)
   and no cut. The keyboard table in `sheet.md` lists what the code
   does.

### Serving the built site

`site/dist` in the scratch copy is a production build of the final
files (`$S/docs-site-build-prod-final-3.log`); the real-input pass ran
against it with this command (`$S/docs-vite-preview.log`): `cd $S/ember-eui/site && pnpm exec vite preview --outDir dist
--host 0.0.0.0 --port 4173`, then `/docs/sheet/docs/sheet`.

## 13. Fix: an editor that removes its own focused element (2026-11-19)

The bug found by the docs (section 12): `src/-private/editor-frame.gts`
closed the editor on any `focusout` whose `relatedTarget` was not in the
editor, including `null`. A `null` target also means the focused element was
removed from the DOM: flatpickr redraws its days when one is picked, so the
editor committed the old draft and closed before the pick was saved.

Fix: a `focusout` with no `relatedTarget` (on the frame or on an editor
surface) is decided one run-loop tick later (`next`). If focus is still in
the editor, or the element that lost focus was removed (`!isConnected`), the
editor stays open and focus goes back to its first focusable element;
otherwise it commits as before (a click on the page). A `focusout` to a known
element outside the editor still commits at once. Side effect: switching to
another window while editing (focus stays on the input) no longer commits.

- New tests in `eui-sheet-custom-type-test.gts`: **C5** (a pick that redraws
  and removes the focused day is saved) and **C6** (a redraw of the focused
  day keeps the editor open and gives focus back; a plain blur still closes
  it). With the old `editor-frame.gts` restored in scratch, C5 fails (the
  close happens during the render: an Ember "updated `editing` after it was
  consumed" assertion), so the tests catch the bug.
- The full sheet suite passes **83/83**; `pnpm lint` (stylelint, ESLint,
  ember-tsc) exits 0; Prettier is clean on the changed source and test.
- The docs demo's workaround (`mousedown` `preventDefault` on the calendar)
  is removed. Real input on the production docs build: Enter on an empty
  date, a click on day 20 in the flatpickr calendar saves `20/11/2026`,
  closes the calendar and the editor, and focus returns to the cell. The
  README's flatpickr example (which never had the workaround) now works as
  written.
- Not re-run: the site's acceptance tests (the demo only lost the
  workaround; the page was visited and works).

## 14. The focused cell's errors are visible (2026-11-19)

Reported by the user: the translations demo's language switch "does not
work". It did work (checked on a production build: the five messages
switch between English and Spanish, and `@messages` wins), but the only
translated texts were the cells' `title`s, shown on hover, so nothing
visible changed.

- Package: while a data cell with errors has focus and no editor is open,
  its messages show in a box under the cell (`.euiSheet__cellError`,
  `data-test-subj="euiSheetCellError"`), inside an always-rendered
  `role="status"` region so screen readers announce them. The box flips
  above the cell only near the window's bottom (it may hang below the
  sheet), follows the cell on scroll, and hides while editing and when
  focus leaves the grid's data cells. The `title` stays.
- Tests: new `eui-sheet-cell-error-test.gts`, E1 to E3 (position, valid
  cells, editing and Escape, blur, `@cellErrors`, `@messages`, a rejected
  paste). Full sheet suite **86/86**; `pnpm lint` exit 0; Prettier clean
  on `src`, `tests/integration` and the README.
- Docs: the translations demo translates its own field and option labels
  per language; the landing page, the validation demo and the README say
  the messages show under the focused cell.
- Real input on the production docs build: Español switches the headers
  (Artículo, Cantidad, Unidad, Vence) and options (Piezas, Cajas); focusing
  the empty Artículo cell shows "Obligatorio" under it, and the Unidad cell
  shows `"kg" no es una opción`. Screenshot: `sheet-cell-error-es.png`.

## 15. Airtable-style clicks and hover feedback (2026-11-19)

Reported by the user: every cell needed two presses to do anything, and a
single click gave almost no feedback. Before: a click only focused the cell
(the grid's thin outline); editing needed a double-click, Enter, F2 or
typing; a checkbox toggled only on its small box; select and date cells had
no button.

Chosen by the user: Airtable-style clicks, with hover feedback.

- A click selects the cell, drawn with a 2px blue ring; a click on the
  selected cell edits it; a double-click still edits at once (one editor);
  Shift+click extends the range and never edits; read-only cells never edit.
- Field-type contract (Ember layer, optional): `opener` (an EUI icon type,
  shown at the end of the hovered or selected editable cell; a click opens
  the editor) and `onCellClick(value, field, record)` (a click anywhere in
  the cell saves its result). Built-ins: singleSelect `opener: 'arrowDown'`,
  date `opener: 'calendar'`, checkbox `onCellClick` toggles (the box no
  longer has its own click handler, so a click toggles once). The custom
  cells demo's zone picker uses `opener: 'arrowDown'`.
- Rows get a light highlight on hover. Openers are not focusable (P9).
- Tests: new `eui-sheet-click-test.gts`, K1 to K4. N7 now expects a
  double-click on a checkbox cell to toggle twice (it is two clicks). Full
  sheet suite **90/90**; `pnpm lint` exit 0; Prettier clean.
- Real input on the production docs build (field types demo): one click on
  a text cell selects it with the blue ring and no editor, a second click
  edits ("Fire extinguishers"); hovering a select cell shows ▾, and one click
  on it opens the options; one click on the empty part of a checkbox cell
  toggles it. Screenshot: `sheet-clicks.png`.
