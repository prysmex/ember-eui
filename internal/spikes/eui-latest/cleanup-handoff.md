# Cleanup handoff (dead pre-Borealis code, companion packages)

Branch `eui-wave/cleanup`, from `feat/eui-latest` at 9bb97be3.

## What counts as public

Every `src` module is technically importable, because of `exports["./*"]` and rollup `publicEntrypoints('**/*.js')`. For this cleanup, a module or name counts as **public** if it meets any of these:

- it is in the `app-js` re-exports (components, helpers, modifiers, services);
- it is in the `components.ts`, `helpers.ts` or `modifiers.ts` barrels or in `template-registry.ts`;
- it is imported in the docs, the site or another package.

Everything else, including undocumented deep imports of `utils/*` and `-private/*`, is treated as internal. The usage check for each file covered `packages/*/src`, `packages/*/tests`, `packages/core/docs`, `site/` and `packages/core/scripts`.

## Deleted (internal, no remaining importer)

- `packages/core/src/utils/css-mappings/*.ts`: the registry `index.ts` and 70 per-component legacy Amsterdam class mappings. Every file except `eui-icon.ts` was deleted, including:
  - `eui-panel.ts`: its only importer was `eui-panel.gts`, which used it for types. Those types are now inlined as literal unions with the same values. The API docs were regenerated and now show the types.
- `eui-icon.ts` stays, because `typeToPathMap` and the alias and deprecated lists are documented and the icon scripts use them. Only its undocumented tail was removed: `baseClass`, `sizeToClassNameMap`, `colorToClassMap` and the default `ComponentMapping` export. These were legacy class maps that nothing imported.
- `utils/index.ts`: the `export { default } from './css-mappings/index.ts'` line (registry re-export, undocumented).
- `utils/token-map.ts`: `TOKEN_MAP` has no importer and is not documented.
- `-private/vis-colors.ts` and `tests/unit/-private/vis-colors-test.ts`: only the deleted avatar and badge mappings used them.
- `unpublished-development-types/global.d.ts` (core only): the global `Mapping`, `ComponentMapping`, `PropertyMapping`, `ComponentProperty` and `Styling` interfaces. The other packages' copies were left alone; they are harmless.

## Deprecated (public; keeps working until the next major, 16.0.0)

The shared helper `-private/unused-after-borealis.ts` (`deprecateUnusedAfterBorealis`) uses:

- id `ember-eui.<name>.unused-after-borealis`;
- `for: '@ember-eui/core'`;
- `since: { available: '15.0.0', enabled: '15.0.0' }`;
- `until: '16.0.0'`.

The message says the API "will be removed from @ember-eui/core in the next major (16.0.0)". The versions follow the coordinator's correction: the pending major changeset makes the next release 15.0.0.

| Export | Fires when | Notes |
|---|---|---|
| `class-names` helper, `componentName` option (`…class-names-component-name…`) | `componentName` passed | **Behavior change:** the option is now ignored, because the registry it read is gone, so no legacy `euiX--*` classes are added. Undocumented, and no internal or companion caller used it. Plain class joining is unchanged and used widely internally, so the helper stays. |
| `inline-styles` helper, `componentName`/`componentArgs` (`…inline-styles-component-name…`) | `componentName` passed | Same: these options are ignored. Plain properties work as before (the list-group docs demo uses them). |
| `get-range-tick` helper (app-js) | helper/function call | Unused since EuiRangeTicks was migrated. `calculateThumbPosition`/`calculateOffset` named exports stay (can't fire; remove in 16.0.0). |
| `eui-page-restrict-width` helper (app-js) | `restrictWidth()` / helper call | Its `restrictWidth-*` classes have no styles; pages use `utils/eui/page-layout.ts`. |
| `eui-markdown-editor-toolbar/icons/markdown-checkmark` component (app-js) | constructor | Converted from template-only to a class so it can fire. The toolbar uses the upstream `listCheck` icon. |

`tests/deprecations.ts` silences `*.unused-after-borealis` the same way it silences `*.removed-upstream`. A new test, `tests/integration/unused-after-borealis-test.gts` (4 tests), checks for each deprecated API that it still works and that the deprecation fires with the right options. For `class-names` and `inline-styles` it also checks that they do not fire without `componentName`.

Not deprecated, still used: `arg-or-default` (used across core and changeset-form), `class-names` and `inline-styles` without `componentName`, `hex-to-rgb` and `is-valid-hex`.

Listed for removal in 16.0.0 (cannot fire at use):
- `get-range-tick.ts` named exports;
- the `_EuiPageRestrictWidth` type;
- the `componentName`/`addBase`/`componentArgs` option types.

## Companion packages

None of the failures came from a core bug, and no companion `src` changes were needed. They had three causes:

1. **The test harness was missing the `eui-emotion` service.** Without it, every migrated component threw "Emotion theme consumers require an Ember component owner". A real app gets the service from core's app-js. Each package's `tests/test-helper.ts` now registers `./services/eui-emotion`, as core's own harness does. The ember-provide-consume-context initializer is not registered: the companions can't resolve that package, and their tests don't use providers.
2. **Tests asserted legacy modifier classes.** These were replaced with checks on the behavior upstream produces:
   - full width: `maxWidth: 100%` and the control filling a 640px parent (`euiFieldText--fullWidth`, `euiFormRow--fullWidth`);
   - compressed: a 32px control (`euiFieldText--compressed`);
   - in group: the input sits inside `.euiFormControlLayout--group` (upstream's stable class) with no inset border box-shadow (`euiFieldText--inGroup`).
3. **Combo box option selector:** `button.euiFilterSelectItem` became `.euiComboBoxOptionsList .euiComboBoxOption[role="option"]`, the same selector core's combo-box test uses.

Upstream EuiForm focusing its error callout did not break any companion test.

Environment note: in a worktree, each companion's `node_modules` symlink resolves `@ember-eui/core` to the **main checkout's** core. To test against the worktree's core, the four symlinks were replaced locally with directories of per-entry symlinks plus `@ember-eui/core` pointing to the worktree's core. The same pattern is used for `packages/core/node_modules` in `mkwt.sh`, and the change is untracked and gitignored. Update `mkwt.sh` the same way if companion suites should run in worktrees.

## Suite results (Chromium 130, this worktree)

| Package | Result |
|---|---|
| core | 1120/1120 (`ember-tsc --noEmit`, eslint on changed files, `docs:api:check` and `rollup --config` pass) |
| validated-form | 23/23 (was 2/23 before the fixes) |
| changeset-form | 22/22 |
| flatpickr | 8/8 |
| pikaday | 7/7 |

## Unresolved / next

- **Needs user sign-off:** the `class-names` and `inline-styles` `componentName` options now do nothing. Before, they added legacy Amsterdam classes and inline styles. No known caller uses them.
- Remove the deprecated exports listed above in 16.0.0.
- `-private/vis-colors.ts` was deleted. If a future port needs `VIS_COLORS_BEHIND_TEXT`, use `euiPaletteColorBlindBehindText()` (the deleted test asserted they were equal).
