# Text family migration handoff (EuiText, EuiTitle, EuiTextColor, EuiTextAlign)

Status: **Migrated**. The full core suite passes in Chromium (609/609), along with upstream parity, types, lint, API docs and the core build.

## Files

- `packages/core/src/components/eui-text.gts`, `eui-title.gts`, `eui-text-color.gts`, `eui-text-align.gts`: now Glimmer classes on extracted factories. Each one resolves its context with `getEuiThemeContext`.
- `scripts/generate-eui-styles.mjs` (shared, additive only): new entries for `euiTextStyles`, `euiTextColorStyles`, `euiTextAlignStyles` and `euiTitleStyles`. The generator now extracts 17 factories. Newly bundled upstream sources: `text/*.styles.js`, `title/title.styles.js`, `link/link.styles.js`, `code/code_syntax.styles.js`. `styles.generated.ts` and `upstream-sources.json` were regenerated, never edited by hand. The only diff to existing factories is esbuild renaming `_ref4` to `_ref5`.
- `scripts/eui-upstream-parity.test.mjs`: the three new factories go through the existing 12-configuration matrix (light/dark × no/preferred/forced contrast × default/overridden theme). Two tests were added: static `euiTextAlignStyles` parity, and typography parity with title-font, scale, size and text-token overrides.
- `packages/core/tests/integration/components/eui-text-family-test.gts`: new, 9 computed-style tests.
- `eui-text-test.gts` and `eui-title-test.gts`: legacy modifier-class assertions replaced with structural/semantic ones.
- `eui-combo-box-test.gts` ("prose list styles leave the input alone"): the harness now also injects the combo box's real input-wrap padding and font from the theme CSS. EuiText's reset uses `:where()`, so in a real page the theme's `.euiComboBox .euiComboBox__inputWrap` rule (specificity 0,2,0) wins. Without that rule the harness fell back to browser-default `ul` padding and fonts, and the pills moved by 20px. The assertion itself is unchanged.
- `packages/core/docs/display/text/index.md` and `title/index.md`: only the generated API sections were regenerated.
- Not touched: `text-block.gts` (CallOut and NotificationEvent use it), `utils/css-mappings/*` (MarkdownFormat imports the text size mapping), providers/shared utils, the first five ports, the showcase, and `.vscode/settings.json`.

## API and default changes (latest-only)

- **EuiText default `@size` is now `'s'`** (upstream). It was `'m'`.
- **EuiText renders a single element.** `@color` and `@textAlign` styles are composed onto the `.euiText` div in upstream's clone order: text, constrained width, size, color, align. The nested EuiTextAlign/EuiTextColor wrappers are gone.
- Without `@color`, EuiText inherits its color as upstream does (`color: inherit`); headings inside it inherit too.
- **EuiTextColor colors:** adds `accentSecondary`, `inherit` and any CSS color value. `ghost` keeps upstream `!important`. `primary` is no longer upstream and is kept as an Ember extension mapped to `colors.textPrimary`.
- Custom colors use an Emotion class, not upstream's inline `style`, so a caller's `style` attribute is never overwritten.
- `@tagName` additions:
  - EuiTextColor: adds `'p'`.
  - EuiTextAlign: new, `'div' | 'span' | 'p'`, defaulting to div.
  - `<p>` variants reset their margin.
  - EuiText does not get `@tagName`: widening its `Element` type broke `EuiSelectableMessage`'s attribute forwarding, so that is deferred.
- **EuiTextAlign is logical.** `left`, `center` and `right` serialize to `start`, `center` and `end`, so left/right flip in RTL.
- **Root classes kept:** `euiText`, `euiTitle`, `euiTextColor` and `euiTextAlign` (same as upstream; unmigrated callers and tests select on them). Every legacy `--modifier` class is removed.
- **Scoped resets** stand in for React's global reset, because Ember has none:
  - EuiText root gets box-sizing and the Borealis font family.
  - EuiText descendants: margin/padding resets, h1–h6/p font inheritance, `code/pre/kbd/samp` code font, `strong` weight and `em` italic. These are all wrapped in `:where()` so every upstream rule still wins.
  - EuiTitle: margin, padding, box-sizing and the Borealis font family.
- Upstream React-only props are not ported: `cloneElement`, and EuiTitle's child-element cloning. Ember keeps `@tagName` on EuiTitle.

## Checks run (2026-10-12)

Environment: Node 22.22.1; pnpm unavailable, so package scripts were invoked directly. Chromium 130 (Playwright build 1140, arm64) was installed under `~/.cache/ms-playwright`, with its system libraries installed through apt. Testem found it through a `google-chrome` symlink on `PATH`, with `CI=true` for `--no-sandbox`.

- `node scripts/generate-eui-styles.mjs --check`: pass (17 factories, React-free).
- `node --test scripts/eui-upstream-parity.test.mjs`: **17/17 pass** (12 before plus 5 new).
- Core test (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci`): **609 tests, 609 pass, 0 fail**. That includes the 9 new `Borealis text family` tests.
- `ember-tsc --noEmit`: pass. ESLint on the changed components and tests: pass.
- `node scripts/generate-api-docs.mjs --check`: pass.
- Core build (`rollup --config` plus `ember-tsc` declarations): pass. The unused-import warning for theme-common in `styles.generated.ts` predates this work.
- Not run (root): site build, site acceptance tests, showcase/browser visual checks.

Failures fixed during the runs:
- Test bug: locals named `kbd`/`pre` shadowed those tags in strict templates.
- Test expectation: Borealis prose links use `textParagraph` with a dotted underline and medium weight, not the link color. Upstream applies this only to unclassed links.
- The combo-box harness issue described above.

## Unresolved

1. ~~Wrapperless provider and inherited color.~~ **Resolved 2026-10-12:** EuiEmotionProvider now wraps its content in `<span class="euiThemeProvider">` with the resolved `textParagraph` color, as upstream's nested provider does. This is on by default (user decision); `@wrapper={{false}}` opts out where an extra element would break flex/grid layout. Attributes are forwarded to the span. Covered by the text-family test "provider wrapper gives inherited text its own mode color".
2. Unmigrated callers that render EuiText/EuiTitle (Card, CallOut, EmptyPrompt, PageHeader, Stat, Toast, etc.) now get Borealis typography. On legacy docs pages that still load Amsterdam CSS, `.euiText`/`.euiTitle` vendor rules also apply. Audit visually when those callers migrate.
3. The `ghost` demo (`text/demo/d02-coloring-text.md`) is white `!important` and readable only on dark surfaces. Check it visually.
4. Upstream `kbd` and `euiCodeBlock` selectors inside EuiText assume the future CodeBlock port uses the upstream class names.
5. ~~Provider finding~~ **Resolved in cebf6dbc:** passing a template `(hash …)` to `@borealisOverrides` crashes upstream `buildTheme` with `key.hasOwnProperty is not a function`. Ember's `hash` creates a prototype-less object, and upstream calls `.hasOwnProperty` on override values. JS objects work, which is what the tests use. The fix belongs in the shared provider/theme utility (normalize overrides before `buildTheme`). Owner: root agent.
6. Root still has to run the full core suite, the core build, and the site build/acceptance tests sequentially (they share output). Also needed: browser checks of forced-colors and the RTL emulation in the showcase.

## Next step

Root: run the site build, acceptance tests and showcase checks sequentially, then decide on the provider items (inherited text color in dark islands, `(hash)` overrides). Nice-to-have later: add text-family samples to the `/docs/eui-latest` showcase after the coordinator finishes it. Callers of EuiText/EuiTitle (Card, CallOut, EmptyPrompt, PageHeader, Stat…) are the natural next migrations.
