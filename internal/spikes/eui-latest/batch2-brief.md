# Batch 2 brief (parallel agents)

Base commit: "build(core): pre-register batch 2 upstream style factories" on `feat/eui-latest`. Read README.md, progress.md, components.md and [text-handoff.md](text-handoff.md) first; the text-family port is the most recent reference implementation.

## Already extracted for you (do not edit the generator)

`styles.generated.ts` exports these upstream EUI 123.1.0 factories, each with parity tests in `scripts/eui-upstream-parity.test.mjs`:

| Family | Factories |
| --- | --- |
| Link | `euiLinkStyles` (plus `euiLinkCSS`, already used by EuiText) |
| Badges | `euiBadgeStyles`, `euiBadgeGroupStyles`, `euiBetaBadgeStyles`, `euiNotificationBadgeStyles`, color helpers `euiBadgeColors`, `getBadgeColors`, `getTextColor`, `getCustomInteractiveColors`, `getIsValidColor` |
| Flex | `euiFlexGroupStyles`, `euiFlexItemStyles` (static object), `euiFlexGridStyles` |
| Button empty/icon | `euiButtonEmptyStyles`, `euiButtonIconStyles` (plus existing `euiButtonDisplay*`, `euiButtonDisplaysColors`, `euiFocusRing`) |

If you genuinely need another factory, stop and report it to the coordinator instead of editing `scripts/generate-eui-styles.mjs`, `styles.generated.ts` or `upstream-sources.json`. Parallel edits to those files cannot be merged safely.

## Rules

- Work only in your assigned worktree and branch. Do not touch other families' components, providers/shared utilities (`utils/emotion/*`, `utils/eui/theme.ts`, `utils/eui/styles.ts`), the showcase, the first five ports or the text family. Never stage `.vscode/settings.json`. Do not push.
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

From the worktree root: `node scripts/generate-eui-styles.mjs --check && node --test scripts/eui-upstream-parity.test.mjs`. Do not run rollup/site builds; the coordinator runs those after merging.

## Deliverables

Commit on your branch: component changes, tests, your `components.md` rows (Migrated only when the full core suite passes in your worktree), and `<family>-handoff.md` with files, API/default changes, exact check counts, unresolved issues and next step.
