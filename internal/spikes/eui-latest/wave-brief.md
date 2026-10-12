# Migration wave brief (parallel agents)

Applies to every migration wave. Your worktree branch starts from the current `feat/eui-latest`. Read README.md, progress.md, components.md and [text-handoff.md](text-handoff.md) first; the text-family port is the most recent reference implementation.

## Upstream style factories

`styles.generated.ts` already exports many upstream factories (see `scripts/generate-eui-styles.mjs` `entries`). If you need more:

- Add entries to `entries` in `scripts/generate-eui-styles.mjs` inside a block commented `// <your family>`, and matching parity coverage in `scripts/eui-upstream-parity.test.mjs` (function factories go in the `factories` map; static objects get their own `deepEqual` test).
- Regenerate with `node scripts/generate-eui-styles.mjs`. Never hand-edit `styles.generated.ts` or `upstream-sources.json`.
- In a worktree, `--check` reports stale source-path comments because `node_modules` is a symlink; that is expected. The coordinator unions all families' entries at merge time and regenerates in the main checkout, so commit your generator/parity edits *and* your regenerated files.
- If the generator rejects a factory (React/hook dependency), do not patch around it in the generator's adapters; port that piece by hand in a `utils/eui/<family>.ts` file with the upstream license header (see `utils/eui/global-styles.ts`) and add a parity test against upstream, or report it.

## Wave context

- Legacy Amsterdam CSS is being removed from the docs site; nothing should rely on it. The core test harness never loaded it.
- The outermost `EuiEmotionProvider` injects upstream global styles (root font size 14px) and every provider renders a color `<span class="euiThemeProvider">` (see README "Shared foundation"). Tests without a provider resolve the owner default theme and keep the browser's 16px root; assert sizes relative to the root font size or render inside a provider.
- Other families are migrating concurrently, including **EuiIcon**. Outside the icon family, render `EuiIcon` as-is: do not add new local icon sizing/styling and do not assert icon pixel sizes; assert presence/semantics. Existing local icon scoping in already-migrated components stays until the icon family lands.
- Behavior-only components (no upstream styles, e.g. portals, i18n, delays): audit upstream, keep behavior, add/confirm tests, and mark the row `Migrated` with "No styles upstream" in the notes.

## Performance rules (required)

Style work must not repeat on every render:

- **Always get factory output through `useEuiBorealisStyles(context, factory)`.** It memoizes each factory's result per resolved theme object (a WeakMap keyed by `context.upstream`, which is itself `@cached`), like upstream's `useEuiMemoizedStyles`. Never call a theme-taking factory directly in a getter (`euiFooStyles(context.upstream)` re-runs the whole upstream factory each time). Static style objects (e.g. `euiFlexItemStyles`) can be used directly.
- **Mark class/style getters `@cached`** (from `@glimmer/tracking`) so `euiClass` serialization and hashing only re-run when a tracked input (args, provider context) changes. Glimmer class components are fine; template-only components can't memoize, so prefer a class with cached getters when a component computes styles.
- Helpers that take extra arguments (e.g. `getBadgeColors(context, color)`) are cheap per call but should still live in a `@cached` getter.
- Do not build per-instance objects for static styles; hoist constants to module scope.

## Styling migrated children

To style a migrated child component (EuiIcon, EuiPanel, EuiButtonIcon, …) pass its `@css` argument (type `EuiCss` from `utils/eui/styles.ts`): it is composed **last into the child's own class**, like upstream's `css` prop. Never add a second Emotion class to a migrated child — which class wins then depends on rule insertion order (this broke checkbox marks when EuiIcon migrated). If a migrated child you need lacks `@css`, add it in your component only if it is in your family; otherwise report it and the coordinator adds it.


## New components (not in Ember EUI before)

When porting a component that exists in upstream EUI 123.1.0 but not yet in Ember EUI:

- Create it under `packages/core/src/components/` following the naming of existing files (`eui-foo-bar.gts`, sub-parts in `eui-foo-bar/`), as a Glimmer class with `@cached` style getters, factories via `useEuiBorealisStyles`, and an `@css` argument composed last (see the Styling migrated children section). Mirror upstream's public props as Ember args (camelCase `@args`), blocks for React children/render props, and `...attributes` on the element upstream spreads `rest` onto. Port behavior (keyboard, focus, aria, timers, resize) with Ember modifiers/services, not React hooks.
- Register it in `packages/core/src/components.ts` and `packages/core/src/template-registry.ts` (both: import + entry, in the existing alphabetical position — the coordinator merges these files by union, so only ADD lines). The package's `package.json` app-js exports are regenerated by the core build — run `./node_modules/.bin/rollup --config` in packages/core once and commit the resulting `package.json` change.
- Add a `components.md` row (status Migrated only when the full core suite passes) and a docs page under `packages/core/docs/<section>/<name>/index.md` (+ `demo/` files) matching existing pages' frontmatter/demo format (look at e.g. `packages/core/docs/display/text/`); run `node scripts/generate-api-docs.mjs` to fill the API section. Demos must render with the new component in the docs site.
- Tests: a focused `eui-<family>-test.gts` with computed-style + behavior + a11y coverage like the migration waves.

## Rules

- Work only in your assigned worktree and branch. Do not touch other families' components, providers/shared utilities (`utils/emotion/*`, `utils/eui/theme.ts`, `utils/eui/styles.ts`, `eui-emotion-provider.gts`), the site/showcase, or already-migrated components (report needed changes instead). Never stage `.vscode/settings.json` or the `node_modules` symlinks. Do not push.
- Claim your rows in `components.md` (edit only your rows) before porting.
- Latest-only styling: no legacy modifier classes, no specificity shields, no Amsterdam coexistence tests. Keep stable upstream root class names where callers or upstream use them.
- Add scoped resets only where React's global reset is load-bearing; use `:where()` for descendant resets so upstream rules win.
- Tests: a new `<family>`-focused computed-style test file covering variants, reactive args without element replacement, light/dark nearest-provider + sibling isolation, native token overrides (use JS objects, not `(hash)`; see text-handoff), attributes/events/blocks, a11y semantics, RTL/logical CSS and contrast where relevant. Compare colors through a computed `rgb()` probe against `resolveBorealisTheme(...)` tokens. Update existing tests that asserted legacy classes; never weaken unrelated tests without explaining why in the handoff.
- Keep public `Element` types stable unless every caller still type-checks.
- Regenerate API docs with `node scripts/generate-api-docs.mjs` if your signatures change.

## Running checks in a worktree

```sh
export PATH=<scratchpad>/bin:$PATH CI=true   # google-chrome -> Playwright Chromium 130
cd packages/core
./node_modules/.bin/ember-tsc --noEmit
./node_modules/.bin/eslint <changed files>
./node_modules/.bin/vite build --mode=development --out-dir dist-tests
./node_modules/.bin/testem --file testem.cjs ci --port 0
```

From the worktree root: `node scripts/generate-eui-styles.mjs --check && node --test scripts/eui-upstream-parity.test.mjs`. Do not run rollup/site builds; the coordinator runs those after merging. Keep runs lean: run your family's filtered tests while iterating (`--test_page 'tests/index.html?hidepassed&filter=<name>'`) and the full suite once before committing.

## Deliverables

Commit on your branch: component changes, tests, your `components.md` rows (Migrated only when the full core suite passes in your worktree), and `<family>-handoff.md` with files, API/default changes, exact check counts, unresolved issues and next step.
