# EuiLink migration handoff

Status: **Migrated**. The full core suite passes in Chromium 130 (617/617). Upstream parity, types, lint and API docs pass too.

## Files

- `packages/core/src/components/eui-link.gts`: now a Glimmer class on the extracted `euiLinkStyles`, via `getEuiThemeContext`, `useEuiBorealisStyles` and `euiClass`. It exports `LINK_COLORS`, the `EuiLinkColor` type, `getSecureRelForTarget` and `isValidHref`. The last two are ports of upstream's `services/security` helpers.
- `packages/core/tests/integration/components/eui-link-borealis-test.gts`: new, 8 computed-style tests.
- `packages/core/tests/integration/components/eui-link-test.gts`: updated legacy assertions, explained below.
- `packages/core/docs/navigation/link.md`: regenerated API section, plus one prose sentence about the default color and `rel`.
- Not touched:
  - generator, generated files and providers/shared utils
  - EuiIcon and the screen-reader-only modifier
  - callers: Breadcrumbs, NotificationEvent, SuperDatePicker quick select, HeaderAlert
  - `utils/css-mappings/eui-link.ts` and the markdown processor, which still emits `euiLink euiLink--primary` on raw anchors

## API and default changes (latest-only)

- **Default `@color` is now `'text'`**, as upstream. It was `'primary'`. `text` is `textParagraph` at rest and `textPrimary` on hover/focus. Callers that relied on the default now render paragraph-colored links with a dotted underline:
  - SuperDatePicker "commonly used" and "recently used" lists
  - NotificationEvent title
  - docs demos without `@color`

  Breadcrumbs pass explicit colors.
- **Colors:** the same 8 as upstream 123.1.0 (`primary`, `subdued`, `success`, `accent`, `danger`, `warning`, `text`, `ghost`). None were added or removed. `@color` is typed as `EuiLinkColor | (string & {})`. An unknown color keeps the base link style (`textParagraph`), with no interaction color, as upstream.
- **`rel`:** the anchor always gets upstream's secure `rel`: `noreferrer`, plus `noopener` for `_blank`, sorted.
  - New optional `@rel` arg merges with it.
  - A plain `rel="…"` attribute still wins over everything because `...attributes` comes last. That is the native escape hatch.
  - Behavior change: same-origin links now send no `Referer`, exactly as upstream.
- **`javascript:` hrefs** render a disabled `<button>` (upstream `validateHref`). The check uses native `URL` instead of `url-parse`.
- **Disabled:** a disabled button uses upstream `styles.disabled`, which inherits color and weight and drops the underline.
  - The existing Ember behavior is kept: a disabled link with `@href` is a disabled `<button>` with no href/target/rel. Upstream React instead renders an enabled `<a>`.
  - An empty `@href` still renders a button (existing Ember behavior). Upstream would render an `<a>`.
- **External indicator follows upstream:**
  - The icon is decorative: `role="presentation"`, `aria-hidden="true"` and no `aria-label`. It was labelled "External link".
  - Screen-reader text is `(external, opens in a new tab or window)` for `_blank`, or `(external)` for `@external={{true}}`. It was `(opens in a new tab or window)`.
  - With `@target="_blank" @external={{false}}` there is no icon and no screen-reader text. That matches upstream, but before this change the new-tab note was still read.
- **Icon glyph:** still `popout`. Upstream uses `external`, which the current Ember icon set lacks; the glyphs are equivalent. Revisit this in the icon migration.
- **Root class:** `euiLink` is kept. Legacy `euiLink--<color>` and `euiLink-disabled` modifier classes are removed.
- **Scoped resets** stand in for React's global reset (Ember has none):
  - Both elements: box-sizing, margin, padding, border, `vertical-align: baseline` and `cursor: pointer`.
  - Button only: `background: none`, `color: inherit`, radius 0, `font-size: inherit` and the Borealis font family.
  - All of these are composed before the upstream styles so upstream wins.
- **Unmigrated dependencies are scoped locally** under the link root, without editing the shared components:
  - EuiIcon: `.euiLink__externalIcon` gets upstream size `s` (`size.m` = 12px), `currentColor` fill, `vertical-align: middle` and logical `margin-inline-start: size.xs`.
  - EuiScreenReaderOnly: `.euiLink__screenReaderOnly` gets upstream's `euiScreenReaderOnly` mixin, hand-transcribed. That mixin is not among the extracted factories.

## Existing test changes (`eui-link-test.gts`)

- The `hasClass('euiLink--subdued' | 'euiLink--primary' | 'euiLink-disabled')` assertions were replaced with `euiLink` and `rel` assertions. The legacy classes no longer exist; color is covered by computed styles in the new file.
- The external-icon test now asserts upstream semantics: icon `aria-hidden`, new screen-reader text, and `rel="noopener noreferrer"`. The old `aria-label="External link"` was removed deliberately (see above).

## New coverage (`Borealis link`, 8 tests)

1. All 8 colors on both `<a>` and `<button>`, compared against tokens through an `rgb()` probe. Also: default `text`, unknown-color fallback, medium weight, dotted underline, logical start alignment, `user-select`, cursor, button reset and Borealis font, and absence of legacy classes.
2. Focus for every color:
   - interaction color (`text` turns to `textPrimary`)
   - solid, thick underline
   - upstream focus ring: `auto` outline, `focus.width` offset, `focus.color`, gated on `:focus-visible`
   - button links focus too
3. Disabled button, disabled anchor and `javascript:` URL:
   - each renders a disabled button with no href/target/rel/icon
   - each inherits color and weight, with no underline
   - none fires clicks or takes focus
4. External links:
   - `rel` for `_blank`, same-origin, merged `@rel` and the attribute override
   - `position: relative` on `_blank` links
   - icon semantics, size, fill and margin, including the RTL flip
   - screen-reader text and its visual hiding
   - `@external` true/false
   - the exported helper functions
5. Reactive color, target, href, type, disabled and external, without replacing elements.
6. Light/dark follows the nearest provider: nested providers inherit, a fixed-light child and outer siblings stay isolated, and the dark interaction color applies.
7. JS-object overrides (colors and `font.weight.medium`): nested overrides win and the outside stays unaffected. Under `preferred` and `forced` contrast, colors and the interaction color match `resolveBorealisTheme(…, mode)`. Teardown is checked.
8. Attributes, classes, `data-test-subj`, ARIA, block content, click events (anchor and button), `type="submit"` in a form, default `type="button"`, keyboard events and focusability/tab order.

Hover and `:target` cannot be triggered from JS. They come from the same `_colorCSS` declarations as focus (`:where(:hover, :focus)`) and are covered by factory parity.

## Checks run (2026-10-12, worktree `eui-batch2/link`)

Environment: Node 22.22.1, with binaries invoked directly (no pnpm). Chromium 130 through the scratchpad `google-chrome` shim, `CI=true`.

- `ember-tsc --noEmit`: pass.
- ESLint on `eui-link.gts`, `eui-link-borealis-test.gts` and `eui-link-test.gts`: pass.
- `vite build --mode=development --out-dir dist-tests` plus `testem --file testem.cjs ci`: **617 tests, 617 pass, 0 fail**. That is 609 before, plus 8 new.
- Filtered `link` run: 26/26.
- `node --test scripts/eui-upstream-parity.test.mjs`: **29/29 pass**.
- `node scripts/generate-api-docs.mjs --check`: pass, after regenerating `navigation/link.md`.
- `node scripts/generate-eui-styles.mjs --check`: **fails in this worktree, and it would fail on the untouched base too.** In the worktree, `node_modules` is a symlink to the main checkout. So esbuild's `// <source path>` comments become `../../../../../../../Users/…/node_modules/...` instead of `node_modules/...`. Regenerating changed only those 48 comment lines, and the files were restored with `git checkout`. Nothing generated is modified on this branch. The check should pass in the main checkout.
- Not run (root): rollup core build, site build/acceptance, showcase/browser visual checks.

## Unresolved

1. The default-color change makes the SuperDatePicker quick-select lists and the NotificationEvent title paragraph-colored. Upstream React looks the same, but this needs a visual check when those callers migrate.
2. Always-on `noreferrer` changes `Referer` for internal links. That matches upstream, but apps using analytics on internal EuiLinks should be told in release notes.
3. `screenReaderOnly` and the EuiIcon sizing are local stand-ins. When EuiScreenReaderOnly/EuiIcon migrate, remove `.euiLink__screenReaderOnly`/`.euiLink__externalIcon` local rules. Ideally the coordinator extracts `euiScreenReaderOnly` as a shared factory.
4. The markdown processor (`markdown-add-components/processor.ts`) still sets legacy `euiLink euiLink--primary` classes on raw anchors, so they are not styled by Borealis. That belongs to the MarkdownFormat migration.
5. `@external={{false}}` with `_blank` no longer announces the new tab, matching upstream. Re-evaluate if a11y review prefers keeping the announcement.
6. As the text handoff notes, a wrapperless provider means a disabled link inherits the page color inside dark islands.

## Next step

Root: merge, then run the core build, site build/acceptance and the showcase (consider adding link samples) sequentially. Breadcrumbs, NotificationEvent and SuperDatePicker quick select are natural follow-ups because they consume EuiLink.
