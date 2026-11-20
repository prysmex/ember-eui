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
