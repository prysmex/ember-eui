# Latest EUI migration spike — feat/eui-latest

## Goal and boundaries

Upgrade Ember components from the bundled EUI 41.4 Amsterdam styles to the latest stable upstream EUI, preserving Ember semantics and testing each migration. This branch builds on `feat/emotion`; the Ember 7.3/native element helper work remains in separate commits on master. Preserve unrelated `.vscode/settings.json` changes.

Baseline checked on 2026-10-11: **EUI 123.1.0** (released 2026-10-05), **Borealis 8.1.0**, **theme-common 10.1.0**. Pin these versions; do not silently follow snapshots. Latest EUI has no drop-in prebuilt all-component CSS. The upgrade is real upstream theme resolution plus pure component style factories, ported incrementally onto existing Ember components.

The previous `/docs/emotion` page remains the original hand-authored token experiment. The `/docs/eui-latest` migration showcase uses real upstream Borealis components and disables the Amsterdam stylesheet while active. Do not describe unmigrated components as upgraded. The legacy vendor CSS remains available only for the unmigrated docs/catalog. Migrated components target latest styles exclusively: no legacy selector specificity shields or dual-style compatibility requirements.

## Shared foundation

- `@elastic/eui-theme-borealis` and `@elastic/eui-theme-common` are runtime dependencies. They supply the actual theme model and `buildTheme`/`getComputed` resolution, including computed semantic tokens.
- Full `@elastic/eui@123.1.0` is a development dependency used as the source/reference for extracted factories. Its React components are not consumed by Ember.
- `scripts/generate-eui-styles.mjs` extracts pure factories into `packages/core/src/utils/eui/styles.generated.ts`; `--check` detects drift. Never edit the generated file.
- The extractor replaces Emotion's React entry with serialization only, removes React/global reset/hook barrels, and rejects surviving hooks or React imports. CSS/keyframes serialization remains equivalent to upstream and will be checked against the installed upstream factories. Provenance, hashes, and source versions are recorded in `upstream-sources.json`.
- `utils/eui/theme.ts` resolves the native Borealis context. `EuiThemeContext.upstream` is cached through Ember autotracking. Theme instances/cache defaults remain owner scoped.
- `EuiEmotionProvider @borealisOverrides={{...}} @highContrastMode="preferred"` supplies native upstream token overrides and contrast mode. Nested providers inherit overrides/mode/cache; the explicit parent API remains optional. Contrast modes are `false`, `"preferred"`, and `"forced"`.
- Migrated components call `getEuiThemeContext(this)`, `useEuiBorealisStyles(context, factory)`, and `euiClass(context, ...serializedStyles)`. Do not use React hooks or global CSS injection. Use ordinary Emotion composition without legacy selector shields. Existing `@overrides` and `context.theme` belong to the prototype; native migration components consume `@borealisOverrides` and `context.upstream`.
- Include local box sizing/typography resets where a component needs them. Root typography/normalization, fonts, portals, and layout direction require explicit scoped validation rather than assuming React's global reset is present.
- Preserve upstream copyright headers and license files under `packages/core/vendor/eui-latest`. Generated upstream-derived code follows Elastic License 2.0 / SSPL v1 as stated in those files; the repository's MIT license does not replace upstream terms.

## Migration procedure per component

1. Claim the component in `components.md`; record files and dependencies before editing. Coordinate shared foundation changes with the root agent.
2. Read upstream 123.1.0 implementation, style factories, defaults, semantic tokens, and relevant tests. Record intentional Ember API differences and changed defaults.
3. Replace class-dependent styling with the extracted factory while preserving documented arguments, attributes, events, accessibility, and block contracts. Update API documentation for deliberate behavior changes.
4. Add substantive browser rendering coverage for supported variants, dynamic argument changes, light/dark inheritance, sibling isolation, native interactions, disabled/loading behavior, modifiers/attributes, RTL/logical CSS, contrast/reduced motion where applicable, and cleanup.
5. Check computed styles without legacy CSS. Assert the component works in the standalone migration showcase. Do not add tests or styling work to support Amsterdam CSS on migrated components.
6. Verify extracted CSS against upstream, run relevant rendering tests and type/lint checks. Root agent runs the full core suite, package build, site checks, and browser smoke/visual checks sequentially where builds share output directories.
7. Update the row and handoff notes with exact evidence. `Migrated` means tests pass; `In progress` is not a completion claim. Do not use a passing class-name assertion as visual parity evidence.

## Planned batches

- Foundation: pinned versions, theme/context/cache integration, deterministic extraction/provenance, license notices, upstream parity tests, migration showcase, inventory.
- Batch 1: Spacer, HorizontalRule, LoadingSpinner, Panel, Button. These establish layout, animation, surfaces, and interactive styling patterns.
- Batch 2: Badge, Text, Title, Link, ButtonEmpty, ButtonIcon, FlexGroup/FlexItem, form labels and basic controls.
- Later: overlays/portals, selectable/combo box, forms/date pickers, tables, navigation, drag/drop, markdown/code rendering, and specialized components. Dependencies must be migrated before callers lose legacy CSS.
- Release gate: full catalog status audited, legacy CSS retirement strategy documented, visual/a11y/browser matrix, FastBoot extraction/hydration, bundle/style insertion comparison, current EUI icon audit, downstream customization/migration notes.

## Reproduction and checks

Use Node 24 and pnpm 12.6.0. `pnpm install`, then `node scripts/generate-eui-styles.mjs --check`. Build core before the site so injected workspace copies are current. `pnpm --filter site start` synchronizes copies before Vite starts; restart after dependency graph changes.

Sandbox toolchain: `PATH=/tmp/ember-eui-toolchain/node_modules/.bin:$PATH`; Chromium tests need `LD_LIBRARY_PATH=/tmp/ember-eui-arm-chromium/lib`. Run tests with the normal package Testem scripts. Do not run site builds and site acceptance tests simultaneously because they share `site/dist`.

## Progress and next handoff

Foundation is in progress. See [components.md](components.md) for the complete source-file inventory; rows include nested/private component files so no component is silently omitted. Validation counts and screenshot links will be added when checks complete. No broad catalog migration is complete yet.

## User direction update — 2026-10-11

Proceed entirely with the latest styling for migrated components. Removed compatibility specificity wrappers and legacy variant classes; use native style/state assertions. The showcase runs separately from the older docs shell and disables its old stylesheet. This spike intentionally changes Panel defaults and HorizontalRule default margin to latest values. Keep this decision when resuming; do not reintroduce dual-style support. Unmigrated catalog pages are not upgraded yet.
