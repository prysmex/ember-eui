# `@ember-eui/sheet` v0.3 batch 3c: results

The split of `packages/sheet/src/components/eui-sheet.gts` into modules,
as `V03C-DESIGN.md` describes it. One section per stage.

How the checks run (every stage):

- The repo's `node_modules` are macOS-only. The suite, the type checks,
  ESLint and Prettier run in a Linux copy of the repo. `3c-checks/sync.sh`
  copies the changes there and checks that `src/` and `tests/` are the
  same in both.
- `3c-checks/check.sh` runs the static checks: the verbatim check, the
  gates, `pnpm lint:types`, the tests' `ember-tsc` against the baseline's
  19 errors (the same lines), ESLint and Prettier on the changed files,
  `node scripts/generate-api-docs.mjs --check`, and a `git diff --stat` of
  the protected paths.
- `CHECKS_NODE_MODULES` is the Linux copy's root `node_modules` (it has
  `typescript` and, under `.pnpm`, `content-tag`).
- The base of every comparison is `43d3279c`, the commit before stage 0.
- The suite: `vite build --mode=development`, then `testem ci` with a
  testem config that sets `browser_disconnect_timeout: 86400`.

## 3c stage 0

Baseline, at `43d3279c`:

- The suite: 527 tests, 527 pass. This is the runner's number; the design
  expected 527 or 532.
- `pnpm lint:types`: no error.
- The tests' `ember-tsc` (`tsconfig.eslint.json`): 19 errors, in
  `tests/deprecations.ts` (1), `eui-sheet-history-test.gts` (5),
  `eui-sheet-record-test.gts` (1), `eui-sheet-rows-test.gts` (10),
  `tests/test-helper.ts` (1), `tests/unit/change-set-test.ts` (1).
- `declarations/` of a `pnpm build` is kept in the Linux copy's scratch
  folder as `3c0-declarations`, for the stage 7 comparison.

What moved, to `src/-private/sheet/`:

- `types.ts`: the 15 types of design 3.2, each now exported.
- `util.ts`: the 15 functions and constants of design 3.2, each now
  exported, and `tempIdCounter` (not exported) with `nextTempId`.
- `header-display.gts`: `headerDisplay`, as a named export.

The component imports them and re-exports `CellView`, so `src/index.ts`
and the two `-private` files that import `CellView` from the component do
not change. The component goes from 7,895 to 7,699 lines; the three new
files have 269.

The checks, in `internal/spikes/sheet/3c-checks/`:

- `verbatim.mjs`: the verbatim check (design 5, check 6). It parses the
  old component and the new files with TypeScript. Each member and
  top-level declaration is compared by its tokens: whitespace and
  parentheses are ignored, and `this.`, `this.sheet.` and
  `this.sheet.<module>.` count as the same. Decorators, the kind of member
  and the comments must match too. A member must be where
  `module-map.mjs` puts it, and declared only once. The template is
  compared with module paths removed. `--pair` compares a `-private` file
  with its old version. A body whose only change is `this` to
  `this.sheet` as a value is listed as OWNER, to look at.
- `owner-gate.mjs` and `gates.sh`: the grep gate and the import gate
  (checks 7, 8), the untouched paths (check 9). The AST gate also finds a
  bare `this` that Prettier wrapped onto its own line, and a field
  initialiser that reads `this` at construction.
- `module-map.mjs`: design 3.2 as data. All 443 members of the class are
  assigned once, to a module or to the component.
- `move.mjs`: moves one stage's members and rewrites only their paths
  (`this.x`, `this.sheet.x`, `this.sheet.<module>.x`), in the moved code,
  the code that stays, the template and the `-private` files. It prints
  each bare `this` for a look. Imports are added by hand.
- `check.sh`, `sync.sh`: see above. `index.mjs` lists a file's members.

The design said the verbatim script is "a scratch script, not committed".
It is committed with this stage, so the later stages use the same checks.

The checks were tested against changed copies of the component: an
operator, a dropped `@cached`, `let` to `const`, and an added comment
each fail; a line wrapped in parentheses and a `this.` changed to
`this.sheet.` pass; `isDestroying(this.sheet)` is listed as OWNER.

The `@action` probe: a plain class with an `@action` method, a `@cached`
getter and a `@tracked` field, in `src/-private/sheet/` of the Linux copy,
used from a template with `{{on "click" probe.bump}}` in a scratch test.
It passes: the handler gets the module as `this` through `{{on}}` and when
called detached, `probe.bump === probe.bump`, and the `@cached` getter
recomputes after a `@tracked` write and not before. So the 20 `@action`
handlers keep `@action`; the fallback (arrow fields) is not needed. The
probe was run alone and deleted before the stage's full run.

Results:

- Verbatim: 510 members, top-level declarations and templates compared,
  all equal.
- Gates: OK. `tests/`, `src/core/`, `src/types.ts`, `src/index.ts`,
  `src/search-ui/` and `packages/core/` are untouched.
- `pnpm lint:types`: no error. The tests' `ember-tsc`: the baseline's 19
  errors, the same lines.
- ESLint and Prettier on the changed files: clean. The check scripts are
  Prettier-formatted.
- `node scripts/generate-api-docs.mjs --check`: passes.
- The suite: 527 tests, 527 pass (2 min 24 s).

Deviations from the design:

- `field-editor.gts` imports only `FieldEditorState` from the component,
  not `WrapperBox`, so it needs no edit in this stage. `FieldEditorState`
  moves in stage 5.
- `util.ts` holds the design's list as it is, though four of its entries
  have one user module (`sameRange`: filling, `sameLayout`: follow,
  `isPromise`: validate, `EMPTY_CHANGE_SET`: history). The design puts
  them there; moving them later is harmless either way.

## 3c stage 1

What moved, to `src/-private/sheet/`, as the module map assigns it:

| File | Class, property | Members | Lines |
| --- | --- | --- | --- |
| `fields.ts` | `SheetFields`, `fields` | 21 | 267 |
| `grid-columns.ts` | `SheetGridColumns`, `gridColumns` | 19 | 274 |
| `header-menu.ts` | `SheetHeaderMenu`, `headerMenu` | 2 | 106 |
| `frozen.ts` | `SheetFrozen`, `frozen` | 11 | 158 |
| `grid-options.ts` | `SheetGridOptions`, `gridOptions` | 11 | 179 |
| `dom.ts` | `SheetDom`, `dom` | 22 | 254 |

Five constants with one user moved above that module's class:
`ROW_COLUMN_WIDTH` and `FROZEN_DEFAULT_WIDTH` (grid-columns),
`GRID_DEFAULT_COLUMN_WIDTH` and `ROW_HEIGHTS` (grid-options),
`FROZEN_MAX_COLUMNS` (frozen). A module cannot import a value from the
component (that would be a run-time cycle), so these could not wait.

The component goes from 7,699 to 6,649 lines. It creates the six modules
as `readonly` fields. Its template changes 25 paths only
(`this.columns` is now `this.gridColumns.columns`, and so on). Six
`-private` files change their paths only: `editor-frame.gts`
(`dom.toViewport`), `field-editor.gts` (`dom.toViewport`,
`fields.fieldById`), `footer-cell.gts` (`frozen.frozenCellProps`),
`sheet-cell.gts` and `row-number-cell.gts` (`frozen.frozenCellProps`,
`gridOptions.pinsAddRow`), `record-form.gts` (`fields.allFields`,
`fields.typeOf`).

How: `3c-checks/move.mjs --stage 1` cut each member with its comment and
rewrote the paths; the imports were added by hand; then Prettier. The
four owners were changed by hand to `this.sheet`: `checkOrderShown` and
`expectUpdate` (`isDestroying`, `isDestroyed`), `measureGroupWidth`
(the same, inside the `ResizeObserver` callback), `onFrozenFocus`
(`afterRender`). The verbatim check lists exactly these four as OWNER,
which is what design 6.1 lists for these modules.

Results:

- Verbatim: 648 members, top-level declarations, templates and `-private`
  declarations compared, all equal apart from the four owners above.
  Every member is in the file the module map names, and declared once.
- Gates: OK. No `this` as a value in a module, no field initialiser that
  reads `this`, every import of the component is `import type`.
  `tests/`, `src/core/`, `src/types.ts`, `src/index.ts`, `src/search-ui/`
  and `packages/core/` are untouched.
- `pnpm lint:types`: no error. The tests' `ember-tsc`: the baseline's 19
  errors, the same lines.
- ESLint and Prettier on the changed files: clean.
- `node scripts/generate-api-docs.mjs --check`: passes.
- The suite: 527 tests, 527 pass (2 min 11 s).

The checks were tested again on the module code: a `@cached` dropped in
a module, a field left on the component as well, a changed template path,
a changed argument in a `-private` file, a member in a class the map does
not name, and `afterRender(this, ...)` in a module each fail.

Two fixes to the checks in this stage: the verbatim check now also
counts the component's own `this.<module>.` as the same path as `this.`
(it failed on every member that stays and reads a moved one), and the
module-map check compares file and class names, not whole paths. It also
fails if a module property has the name of an old member, which would
make the paths ambiguous; none does.

Deviations from the design: none in the code. One in the comments: a
section banner travels with the member right below it (the verbatim
check compares each member's comments, banner included). Two banners
landed in a module whose section mostly stayed: "Edit lifecycle" is now
in `dom.ts` above `rectOf`, and "Field management (V03 6)" in `fields.ts`
above `fieldById`. Comment-only; left as is, so that the check stays
strict. Stage 5, which moves the edit and field-editor code, can put
them back with an allowance in the check. The module map's table
says "about 1,050 lines" for this stage; the six files have 1,238, of
which about 170 are imports, class headers and Prettier's re-wrapping of
the longer paths.

For stage 2:

- Run `move.mjs --src packages/sheet/src --stage 2` (no `--tops`: the
  stage 2 modules use only `util.ts` and `types.ts` constants). It also
  re-points the stage 1 modules' `this.sheet.rowModel`,
  `this.sheet.isGrouped`, `this.sheet.hasAddRow`, `this.sheet.recordAt`
  and the others to `this.sheet.rows.x`.
- Review the `-private` re-pointing by hand: `sheet.groups` becomes
  `sheet.rows.groups`, and the regex matches any `sheet.<name>`.
- Then the imports by hand, the bare `this` lines it prints (LOOK), the
  unused imports ESLint lists in the component, Prettier, `sync.sh`,
  `check.sh <repo> <linux copy> 43d3279c <baseline tests-tsc log>`, with
  `CHECKS_NODE_MODULES` set to the Linux copy's root `node_modules`.
- Design 6.1 lists no owner site in `rows`, `groupHeaders`, `checked` or
  `cells`: `move.mjs` should print no LOOK line and the OWNER list should
  stay the four of this stage. Anything else needs reading.
- OWNER is lenient: any `this` changed to `this.sheet` as a value is
  listed, not failed. In stages 4 and 6, a `later(this, ...)` or
  `debounce(this, ...)` changed by mistake shows only there.
- A banner moves with the member below it (see above): check where each
  banner of the stage lands.
- The design's one-off `cellView` call count (one scroll step of the
  large-data demo, before and after) is stage 2's.
- The `@action` probe ran on the test (vite) build only; the publish
  Babel config is first exercised by stage 7's `pnpm build`.
- The baseline files (`3c0-declarations`, `3c0-base-types-tests.log`) are
  in the Linux copy's scratch folder. If it is cleaned, rebuild them from
  `43d3279c`.

## 3c stage 2

What moved, to `src/-private/sheet/`, as the module map assigns it:

| File | Class, property | Members | Lines |
| --- | --- | --- | --- |
| `rows.ts` | `SheetRows`, `rows` | 29 | 319 |
| `group-headers.ts` | `SheetGroupHeaders`, `groupHeaders` | 17 | 249 |
| `checked.ts` | `SheetChecked`, `checked` | 10 | 123 |
| `cells.ts` | `SheetCells`, `cells` | 9 | 155 |

No constant or function moved with them: they use only `util.ts`, `types.ts`
and `core`.

The component goes from 6,649 to 5,960 lines. Its template changes 2
paths (`rows.rowCount`, `rows.isGrouped`). Two stage 1 modules are
re-pointed: `grid-columns.ts` (`rows.numberOf`) and `grid-options.ts`
(`rows.hasAddRow`, `rows.isGrouped`, `rows.rowModel`, `rows.groups`).
Five `-private` files change their paths only: `sheet-cell.gts`,
`row-number-cell.gts`, `group-label.gts`, `record-form.gts`,
`record-form-field.gts`. Each `-private` change was read by hand; every
`sheet.groups` is now `sheet.rows.groups`.

How: `3c-checks/move.mjs --stage 2`, the imports by hand, the unused
imports ESLint listed in the component removed, then Prettier. `move.mjs`
printed no LOOK line: these four modules have no owner site.

A trap found while adding the imports: a name the module forgot to import
can resolve to a DOM global and still compile. `stop(event)` in
`onGroupKeyDown` resolved to `window.stop()`; only its argument count
made it a type error. `Range` is the same (the DOM's `Range`). So each new
module was also checked with a scratch script that lists every name it
uses which is a top-level name of the old component but is neither
declared nor imported in the module. It lists none. (It does list `stop`
when that import is removed.) Not committed; stage 3 on should do the
same.

The `cellView` count (design 5, stage 2's extra check): a temporary
counter in `cellView` and a scratch test, both only in the Linux copy and
removed afterwards. The test renders the large-data demo's case (10,000
records, the same 30 fields, `@height={{420}}`, 1,000 px wide), then
scrolls the grid. It is not the docs demo itself, which needs the docs
app. Calls:

| | Before (stage 1) | After (stage 2) |
| --- | --- | --- |
| First render | 130 | 130 |
| Scroll down to 100 px | 30 | 30 |
| Scroll down to 200 px | 20 | 20 |
| Scroll down to 300 px | 30 | 30 |
| Scroll right to 300 px | 39 | 39 |

The same numbers in two runs each.

Results:

- Verbatim: 674 members, top-level declarations, templates and `-private`
  declarations compared, all equal apart from stage 1's four owners. Every
  member is in the file the module map names, and declared once.
- Gates: OK. `tests/`, `src/core/`, `src/types.ts`, `src/index.ts`,
  `src/search-ui/` and `packages/core/` are untouched.
- `pnpm lint:types`: no error. The tests' `ember-tsc`: the baseline's 19
  errors, the same lines.
- ESLint and Prettier on the changed files: clean.
- `node scripts/generate-api-docs.mjs --check`: passes.
- The suite: 527 tests, 527 pass (run by the main session after the agent was stopped by a restart; the static checks were re-run then too, all OK).

Deviations from the design: none. No section banner moved in this stage.

## 3c stage 3

What moved, to `src/-private/sheet/`, as the module map assigns it:

| File | Class, property | Members | Lines |
| --- | --- | --- | --- |
| `selection.ts` | `SheetSelection`, `selection` | 19 | 260 |
| `outline.ts` | `SheetOutline`, `outline` | 8 | 224 |
| `scroll.ts` | `SheetScroll`, `scroll` | 9 | 226 |
| `ime.ts` | `SheetIme`, `ime` | 12 | 110 |
| `focus.ts` | `SheetFocus`, `focus` | 17 | 321 |

Three constants with one user moved above that module's class:
`CELL_ERROR_SPACE` and `CELL_ERROR_MAX_WIDTH` (focus), `FLASH_MS`
(outline).

The component goes from 5,960 to 4,977 lines. Its template changes 23
paths only (`onScroll`, `onFocusIn`, `onFocusOut`, the range outlines,
`layoutTick`, `scrolledX`, `headerMarkCss`, `cellError`). `setupWrapper`
adds and removes the same `this.focus.onPagePress`; `willDestroy` clears
`this.outline.flashTimer`, in the same place. Four stage 1 and 2 modules
are re-pointed: `cells.ts` (`selection.isSelected`,
`selection.touchedAt`), `frozen.ts` and `grid-options.ts`
(`scroll.scrollElement`, `scroll.scrolledX`), `grid-columns.ts`
(`scroll.layoutTick`). Four `-private` files change their paths only:
`ime-catcher.gts` (writes `sheet.ime.imeInput`; the five IME handlers),
`layer.gts` (`focus.onFocusIn`, `focus.onFocusOut`), `range-outline.gts`
(`outline.placeRangeOutline`), `row-number-cell.gts`
(`selection.isRowSelected`, `selection.isRowMarked`). Each was read by
hand.

How: `3c-checks/move.mjs --stage 3 --tops
CELL_ERROR_SPACE=focus,CELL_ERROR_MAX_WIDTH=focus,FLASH_MS=outline`, the
imports by hand, the unused imports ESLint listed (in the component, and
`run` in `outline.ts`, where `run` is a local name) removed, then
Prettier. The missing-import script of stage 2 (scratch) lists no name in
any module.

`move.mjs` printed LOOK for exactly the five owner sites design 6.1 lists
for these modules; each was changed by hand to `this.sheet`:
`onFocusIn` (`afterRender`), `revealCell` and `parkFocus` (`isDestroying`,
`isDestroyed`), `onScroll` (`afterRender(this.sheet,
this.sheet.focus.parkFocus)`), `flashCells` (`isDestroying`,
`isDestroyed`, inside the timer). Before that, the owner gate failed on
all five, as it should. The verbatim check now lists them as OWNER, next
to stage 1's four.

The other risks of design stage 3:

- No moved field is still declared in the component (a grep of the 21
  field names, besides the verbatim check's "declared once").
- `parkFocus` stays an arrow field (the verbatim check compares kinds).
- A plain method passed as a value would lose its `this`: every
  reference to a moved method that is not a call was listed. There are
  three, all in templates (`scroll.onScroll`, `focus.onFocusIn`,
  `focus.onFocusOut`), and all three are `@action`.

Results:

- Verbatim: 699 members, top-level declarations, templates and `-private`
  declarations compared, all equal apart from the nine owners above.
  Every member is in the file the module map names, and declared once.
- Gates: OK. `tests/`, `src/core/`, `src/types.ts`, `src/index.ts`,
  `src/search-ui/` and `packages/core/` are untouched.
- `pnpm lint:types`: no error. The tests' `ember-tsc`: the baseline's 19
  errors, the same lines.
- ESLint and Prettier on the changed files: clean.
- `node scripts/generate-api-docs.mjs --check`: passes.
- The suite: 527 tests, 527 pass.

Deviations from the design: none in the code. In the comments, as in
stage 1: the "Called by the cell renderer" banner was above `isSelected`,
so it is now in `selection.ts`; the rest of its section moved to
`cells.ts` in stage 2.

From this stage on, the checks run in this one Linux checkout (repo root
and Linux copy are the same path, so `sync.sh` is not needed), and
`check.sh` takes the baseline log as an absolute path (it changes
directory before reading it).

## 3c stage 4

What moved, to `src/-private/sheet/`, as the module map assigns it:

| File | Class, property | Members | Lines |
| --- | --- | --- | --- |
| `changes.ts` | `SheetChanges`, `changes` | 3 | 158 |
| `validate.ts` | `SheetValidate`, `validate` | 9 | 97 |
| `resolve.ts` | `SheetResolve`, `resolve` | 7 | 184 |
| `uploads.ts` | `SheetUploads`, `uploads` | 7 | 195 |
| `history.ts` | `SheetHistory`, `history` | 13 | 448 |
| `records.ts` | `SheetRecords`, `records` | 11 | 282 |

Five top-level declarations with one user moved above that module's
class: `FLASH_SOURCES` (changes), `HISTORY_LIMIT` (history),
`VALIDATE_DEBOUNCE` and `validateWaiter` (validate), `hasFiles`
(uploads). `validateWaiter` is built once, at module scope, in
`validate.ts` only; `resolveWaiter` stays in `util.ts` only (a grep of
`buildWaiter(` in `src/`).

The component goes from 4,977 to 3,776 lines. Its template changes 3
paths (`uploads.onDragOver`, `uploads.onDragLeave`, `uploads.onDrop`).
`willDestroy` has the same statements in the same order, pointed at
`validate.validateTimer`, `validate.validateController`,
`validate.endValidateWaiter()` and `resolve.pendingCalls` /
`resolve.endCall`. Two earlier modules are re-pointed: `cells.ts`
(`validate.validation`, `uploads.dropPos`, `resolve.pendingCells`) and
`selection.ts` (`changes.emit`). Two `-private` files change their paths
only: `record-form.gts` (`history.undo`, `history.redo`) and
`record-form-field.gts` (`uploads.uploadFiles`). Each was read by hand.

How: `3c-checks/move.mjs --stage 4 --tops
FLASH_SOURCES=changes,HISTORY_LIMIT=history,VALIDATE_DEBOUNCE=validate,validateWaiter=validate,hasFiles=uploads`,
the imports by hand, the 35 imports ESLint listed as unused in the
component removed (with a scratch script that drops named imports), then
Prettier. The missing-import script lists no name in any module.

Owner sites: `move.mjs` printed LOOK for `insertOne`, `duplicate`
(`records`) and `selectChanged` (`history`), each
`afterRender(this, ...)`, changed by hand to `this.sheet`; and for
`scheduleValidate`'s `debounce(this, this.runValidate, ...)`, which stays
as it is (design 6.1: the module is a stable target, and `cancel` in
`willDestroy` gets the same timer). `finishResolve`, `uploadFiles` and
`runValidate` read `this.isDestroying` / `this.isDestroyed`; `move.mjs`
rewrote them to `this.sheet.isDestroying` / `this.sheet.isDestroyed`, as
for any name that stays on the component (the verbatim check counts that
as a path, not as an owner). The OWNER list is stage 3's nine plus these
three.

The other checks of this stage:

- No moved field is still declared in the component (a grep of the 14
  field names).
- References to a moved plain method that are not calls: only
  `debounce(this, this.runValidate, ...)` (the target is given). The three
  drag handlers bound in the template are `@action`.
- `emit` is verbatim (the order of its steps is in its body).

Results:

- Verbatim: 699 members, top-level declarations, templates and `-private`
  declarations compared, all equal apart from the twelve owners above.
  Every member is in the file the module map names, and declared once.
- Gates: OK. `tests/`, `src/core/`, `src/types.ts`, `src/index.ts`,
  `src/search-ui/` and `packages/core/` are untouched.
- `pnpm lint:types`: no error. The tests' `ember-tsc`: the baseline's 19
  errors, the same lines.
- ESLint and Prettier on the changed files: clean.
- `node scripts/generate-api-docs.mjs --check`: passes.
- The suite: 527 tests, 527 pass.

Deviations from the design: none in the code. In the comments, two that
travel with the declaration right below them (the verbatim check compares
each declaration's leading comments):

- `/** Shift+F10 or the ContextMenu key: the row menu. */` sat above
  `FLASH_SOURCES` in the original (a stray: the function it describes,
  `isMenuKey`, is further down), so it is now in `changes.ts`.
- The small heading `/* Following \`@records\` (V02-DESIGN.md 3.2, 3.3) */`
  sat above `pendingFocus`, so it is now in `records.ts`, not with the
  `follow` fields it introduced.

## 3c stage 5

What moved, to `src/-private/sheet/`, as the module map assigns it:

| File | Class, property | Members | Lines |
| --- | --- | --- | --- |
| `edit.ts` | `SheetEdit`, `edit` | 22 | 359 |
| `expanded.ts` | `SheetExpanded`, `expanded` | 18 | 202 |
| `field-editor.ts` | `SheetFieldEditor`, `fieldEditor` | 21 | 472 |
| `row-menu.ts` | `SheetRowMenu`, `rowMenu` | 13 | 318 |
| `follow.ts` | `SheetFollow`, `follow` | 12 | 377 |

Top-level declarations with one user moved above that module's class:
the `Editing` class, `NARROW_SHEET` and `coarsePointer` (edit); the
`FieldEditorState` class (still exported), `CREATABLE_FIELD_TYPES`,
`errorMessage` and `typeName` (fieldEditor); `MENU_ITEMS_THAT_MOVE_FOCUS`
(rowMenu); `isOwnChange` (follow). `move.mjs --tops` skips class
declarations, so the two classes were moved by a scratch script that cuts
the same range (the statement with its leading comment) and puts it above
the module's class. `-private/field-editor.gts` now imports
`FieldEditorState` (type only) from `./sheet/field-editor.ts` instead of
from the component, as design 3.1 says. `sheet/field-editor.ts` imports
`draftOf` and `FIELD_EDITOR_WIDTH` from `-private/field-editor.gts`; the
way back is a type import, so there is no run-time cycle.

The component goes from 3,776 to 2,210 lines. Its template changes 24
paths only (`follow.watchRecords`, `fieldEditor.watchFields`, the menu,
the field editor, the record shells, the editor block and its callbacks,
`fieldEditor.addingField`, `edit.onDragStart`, `rowMenu.onContextMenu`);
the two modifiers stay on the same element, in the same place.
`willDestroy` removes `this.rowMenu.onDocumentMouseDown`, the same arrow
field `openMenu` adds and `closeMenu` removes. Seven earlier modules are
re-pointed (`focus`, `headerMenu`, `history`, `ime`, `outline`,
`records`, `scroll`). Five `-private` files change their paths only:
`field-editor.gts`, `layer.gts` (`rowMenu.onContextMenu`),
`record-form.gts` (writes `sheet.expanded.formEditorOpen`),
`record-form-field.gts`, `record-shells.gts`. Each was read by hand.

How: `3c-checks/move.mjs --stage 5 --tops ...` (the seven above), the two
classes by the scratch script, the imports by hand, the 24 imports ESLint
listed as unused in the component removed, then Prettier. The
missing-import script lists no name in any module.

Owner sites: `move.mjs` printed LOOK for exactly design 6.1's sites in
these modules, each changed by hand to `this.sheet`: `watchRecords`,
`closeExpanded`, `afterFormRender`, `editInRecord`, `closeFieldEditor`,
`watchFields` (`afterRender`), `runFieldHandler` (`isDestroying`,
`isDestroyed`, twice). `onContextMenu`'s `this.isDestroying` /
`this.isDestroyed` became `this.sheet.isDestroying` /
`this.sheet.isDestroyed` (a path, as in stage 4). The OWNER list is
stage 4's twelve plus these seven.

A fix to the checks in this stage: `RecordFlyout` and `RecordModal` in
`record-shells.gts` extend `RecordShell`, not `Component<...>`, so the
verbatim check compares them as top-level classes, and their inline
`<template>` was compared as raw text: the path
`this.sheet.formEditorOpen` → `this.sheet.expanded.formEditorOpen`
failed. `parse.mjs` now writes a template inside a declaration the way
`verbatim.mjs` already compares templates on their own (module paths
dropped, whitespace ignored). Tested both ways: with the fix the stage
passes; with `false true` swapped in `RecordFlyout`'s template, or a
renamed member in `RecordModal`'s, it still fails.

The other checks of this stage:

- No moved field is still declared in the component (a grep of the 18
  field names).
- References to a moved plain method that are not calls: none. Template
  handlers are `@action` or arrow fields; `growOf`, `editorValue` and
  `editorRecord` stay arrow fields (the verbatim check compares kinds).
- `commit`, `editingList` (`@cached`) and the listener pairs are
  verbatim; `onContextMenu`'s `window` `mouseup` listener is a local
  function, added and removed in the same body.

Results:

- Verbatim: 718 members, top-level declarations, templates and `-private`
  declarations compared, all equal apart from the nineteen owners above.
  Every member is in the file the module map names, and declared once.
- Gates: OK. `tests/`, `src/core/`, `src/types.ts`, `src/index.ts`,
  `src/search-ui/` and `packages/core/` are untouched.
- `pnpm lint:types`: no error. The tests' `ember-tsc`: the baseline's 19
  errors, the same lines.
- ESLint and Prettier on the changed files: clean.
- `node scripts/generate-api-docs.mjs --check`: passes.
- The suite: 527 tests, 527 pass.

Deviations from the design: none in the code. The banners stage 1 left
in `dom.ts` ("Edit lifecycle") and `fields.ts` ("Field management (V03
6)") stay there: putting them back would need an allowance in the
verbatim check, and they are comments only. This stage's banners landed
in their modules ("@editIn", "Editor callbacks, bound once", "The
expanded record", "The row menu").

## 3c stage 6

What moved, to `src/-private/sheet/`, as the module map assigns it:

| File | Class, property | Members | Lines |
| --- | --- | --- | --- |
| `drag.ts` | `SheetDrag`, `drag` | 17 | 301 |
| `touch.ts` | `SheetTouch`, `touch` | 9 | 102 |
| `clicks.ts` | `SheetClicks`, `clicks` | 3 | 156 |
| `filling.ts` | `SheetFilling`, `filling` | 14 | 279 |

Three constants with one user moved above that module's class:
`LONG_PRESS_MS` and `LONG_PRESS_SLOP` (touch), `FILL_HANDLE_SIZE`
(filling).

The component goes from 2,210 to 1,463 lines. Its template changes 16
paths only (the mouse, pointer and click listeners, `drag.dragging`,
`filling.fillTarget`, `filling.fillHandleRange`,
`filling.onFillHandlePress`). `willDestroy` has the same statements in
the same order: `drag.stopWatchingRelease()`, `filling.stopFillDrag()`,
`drag.autoScroll.stop()`, `touch.cancelLongPress()`. Two earlier modules
are re-pointed (`follow`, `rowMenu`). Three `-private` files change their
paths only: `fill-handle.gts` (`filling.placeFillHandle`), `layer.gts`
(seven handlers: `drag.onMouseDown`, `touch.onPointerDown`,
`touch.onPointerMove`, `touch.onPointerEnd` twice, `touch.onClickCapture`,
`clicks.onClick`), `sheet-cell.gts` (`filling.isFillPreview`). Each was
read by hand.

How: `3c-checks/move.mjs --stage 6 --tops
LONG_PRESS_MS=touch,LONG_PRESS_SLOP=touch,FILL_HANDLE_SIZE=filling`, the
imports by hand, the 7 imports ESLint listed as unused in the component
removed, then Prettier. The missing-import script lists no name in any
module.

Owner sites: `move.mjs` printed LOOK for the two design 6.1 names for
these modules. `stopFillDrag`'s `isDestroying(this)` is now
`isDestroying(this.sheet)` (otherwise the fill target would be written
during destroy). `onPointerDown`'s `later(this, this.onLongPress,
LONG_PRESS_MS)` stays as it is: `onLongPress` runs with the module as
`this`, and `cancelLongPress` cancels the same timer. The OWNER list is
stage 5's nineteen plus `stopFillDrag`.

The other checks of this stage:

- No moved field is still declared in the component (a grep of the 12
  field names).
- The document listeners: `onRelease` and `onDragMove` are added in
  `drag.watchRelease` and removed in `drag.stopWatchingRelease`;
  `onFillMove`, `onFillRelease` and `onFillKeyDown` are added in
  `filling.onFillHandlePress` and removed in `filling.stopFillDrag`. Each
  pair names the same arrow field of the same module.
- `autoScroll`'s initialiser only builds closures (the owner gate checks
  that no initialiser reads `this` at construction).
- References to a moved plain method that are not calls: only
  `later(this, this.onLongPress, ...)` (the target is given).

Results:

- Verbatim: 721 members, top-level declarations, templates and `-private`
  declarations compared, all equal apart from the twenty owners above.
  Every member is in the file the module map names, and declared once.
- Gates: OK. `tests/`, `src/core/`, `src/types.ts`, `src/index.ts`,
  `src/search-ui/` and `packages/core/` are untouched.
- `pnpm lint:types`: no error. The tests' `ember-tsc`: the baseline's 19
  errors, the same lines.
- ESLint and Prettier on the changed files: clean.
- `node scripts/generate-api-docs.mjs --check`: passes.
- The suite: 527 tests, 527 pass.

Deviations from the design: none. The banners landed in their modules
("Touch", "The fill handle"; the batch 6 heading above `fillSource` in
`filling.ts`).

## 3c stage 7

What moved, to `src/-private/sheet/`, as the module map assigns it:

| File | Class, property | Members | Lines |
| --- | --- | --- | --- |
| `keys.ts` | `SheetKeys`, `keys` | 15 | 627 |
| `clipboard.ts` | `SheetClipboard`, `clipboard` | 9 | 313 |
| `api.ts` | `SheetApiModule`, `api` | 2 | 55 |

Top-level declarations with one user moved above that module's class:
`ARROWS` (read only by `RANGE_KEYS`'s initialiser), `RANGE_KEYS`,
`ARROW_DIRECTIONS`, `ARROW_STEPS`, `startsComposition`,
`isShortcutListKey`, `isMenuKey` (keys); `writeClipboard` (clipboard).

The component goes from 1,463 to 532 lines. Its template changes 8
paths only (`keys.onKeyDown`, `clipboard.onCopy`, `clipboard.onCut`,
`clipboard.onPaste`, `api.blockApi` three times, `keys.shortcutsOpen`).
`registerSheetApi` stays on the component (its `afterRender(this, ...)`
owner is the component) and hands over `this.api.sheetApi`. One earlier
module is re-pointed (`rowMenu`: `clipboard.copyRows`). Two `-private`
files change their paths only: `layer.gts` (`keys.onKeyDown`) and
`shortcut-list.gts` (`keys.shortcutContext`, `keys.closeShortcuts`).

How: `3c-checks/move.mjs --stage 7 --tops ...` (the eight above), the
imports by hand, the 23 imports ESLint listed as unused in the component
removed, then Prettier. The missing-import script lists no name in any
module. `move.mjs` printed no LOOK line: design 6.1 has no owner site in
these three modules.

The risks of design stage 7:

- `sheetApi` is one object, built once in a field initialiser of the
  `api` module (itself built once per component); its closures read the
  sheet when called (the owner gate checks no initialiser reads `this`
  at construction).
- `blockApi` stays `@cached`, verbatim: its tracked reads are still
  `visibleFields`, `hiddenFields`, `args.sort`, `rowHeight`,
  `checkedRecords`, `args.groupBy`, `args.groups` (module fields are
  plain, so `this.sheet.<module>` adds none).
- `blockApi` hands out members of six modules as values (`hideField`,
  `showField`, `setRowHeight`, `setSort`, `showShortcuts`, `setGroupBy`,
  `toggleGroupByKey`). The unbound-method listing was run over all 33
  modules: every member referenced without a call is an arrow field or
  `@action`, except the two run-loop targets of stages 4 and 6
  (`debounce(this, this.runValidate, ...)`, `later(this,
  this.onLongPress, ...)`).

Results:

- Verbatim: 730 members, top-level declarations, templates and `-private`
  declarations compared, all equal apart from the twenty owners of
  stages 1 to 6. Every member is in the file the module map names, and
  declared once.
- Gates: OK (33 module classes). `tests/`, `src/core/`, `src/types.ts`,
  `src/index.ts`, `src/search-ui/` and `packages/core/` are untouched.
- `pnpm lint:types`: no error. The tests' `ember-tsc`: the baseline's 19
  errors, the same lines.
- ESLint and Prettier on the changed files: clean.
- `node scripts/generate-api-docs.mjs --check`: passes.
- The suite: 527 tests, 527 pass.

The end checks:

- The component holds only what design 3.1 lists: its class has exactly
  the 22 members of `module-map.mjs`'s `component` list and the 33 module
  fields; the file's only other top-level declaration is `isModal`. It
  has 532 lines (design: about 560). The 33 modules and the three shared
  files are 8,438 lines; the largest is `keys.ts` at 627 (design: about
  560; `onKeyDown` alone is 193 and is not split).
- `pnpm build` on this branch, and the declarations compared with a
  `pnpm build` of `43d3279c` (a worktree, removed afterwards):
  `declarations/index.d.ts`, `declarations/types.d.ts` and
  `declarations/core/**` are the same. What differs, as the design
  expects: `components/eui-sheet.d.ts` (the class's members are on the
  modules, decision 1 of section 10; it no longer exports `WrapperBox`
  and `FieldEditorState`, which moved to `sheet/types.ts` and
  `sheet/field-editor.ts`), `-private/field-editor.d.ts` (its type import
  of `FieldEditorState` follows the class), the new
  `-private/sheet/**`, and the `.d.ts.map` files of the `-private`
  components whose paths changed (line offsets only).
- The `@action` probe of stage 0 ran on the test build only; this
  `pnpm build` (the publish Babel config) compiles the 20 `@action`
  handlers on plain classes without an error. Whether they bind in the
  published build was not run in a browser.
- The pass by hand through the docs demos (large data, groups, frozen
  fields, the expanded record) was not done: it needs the docs app and a
  person at the browser. It is the one end check still open.

Deviations from the design: none in the code. The "Keys and clipboard"
banner was above `onKeyDown`, so it is in `keys.ts`; the clipboard half
of its section is in `clipboard.ts` without it.

## 3c: summary

| Stage | Commit | Moved to | Component lines | Suite |
| --- | --- | --- | --- | --- |
| 0 | (earlier) | `types.ts`, `util.ts`, `header-display.gts` | 7,895 → 7,699 | 527 / 527 |
| 1 | `4f5f731` | fields, gridColumns, headerMenu, frozen, gridOptions, dom | → 6,649 | 527 / 527 |
| 2 | `56f2e91` | rows, groupHeaders, checked, cells | → 5,960 | 527 / 527 |
| 3 | `f5ab257` | selection, outline, scroll, ime, focus | → 4,977 | 527 / 527 |
| 4 | `0a0e99d` | changes, validate, resolve, uploads, history, records | → 3,776 | 527 / 527 |
| 5 | `7d52fd0` | edit, expanded, fieldEditor, rowMenu, follow | → 2,210 | 527 / 527 |
| 6 | `ab8c633` | drag, touch, clicks, filling | → 1,463 | 527 / 527 |
| 7 | this commit | keys, clipboard, api | → 532 | 527 / 527 |

Owner sites (design 6.1): all 31 handled. 21 sites in 20 members
(`runFieldHandler` has two) take `this.sheet` (`isDestroying`,
`isDestroyed`, `afterRender`); the 4 `this.isDestroying` reads became
`this.sheet.isDestroying` (paths); `later` and `debounce` keep the module
as their target; `registerSheetApi`'s `afterRender(this, ...)`,
`guidFor`, `getEuiThemeContext` and `cellContext` stay on the component.

Stages 3 to 7 could not be pushed from the session that made them
(GitHub refused its writes with 403); they were handed over as git
bundles, to push from the user's clone with the same commits. Stages 3
and 4 were pushed that way during the run.

## 3c: verified by the main session (2026-11-20)

Stages 3-4 and 5-7 were done in a claude.ai cloud session, which could
not push; the user handed them over as git bundles, fast-forwarded onto
`feat/sheet` (`0a0e99dd`, then `431558fe`). Checked again in the sandbox
on `431558fe`:

- `check.sh` against `43d3279c`: verbatim, gates, `lint:types`, the
  tests' 19 baseline errors, ESLint, Prettier, the API docs check: all
  OK. The suite: 527 tests, 527 pass.
- A production docs build, Playwright real input on the system Chromium
  (the scripts used for batch 3b): two checked rows copy as TSV and paste
  onto the next rows; the d19 groups demo collapses (22 → 17 grid rows)
  and expands, a paste on a group's add row inserts into that group;
  scrolled sideways at 420 px each header shows one label at the left
  edge, clickable; a header under the column header stays below it. The
  same results as before the split; no page errors.

Batch 3c is complete: the component is 532 lines, the 33 modules and
three shared files in `src/-private/sheet/` are 8,438 lines.
