# New components: page sections, banner and live regions

Branch `eui-wave/new-page-a11y` (merged with `feat/eui-latest` at
`b1004ad0`). Target EUI 123.1.0 / Borealis 8.1.0. Status: **Migrated**.

## Files

- New: `packages/core/src/components/eui-page-section.gts`,
  `eui-page-sidebar.gts`, `eui-banner.gts`, `eui-live-announcer.gts`,
  `eui-screen-reader-live.gts`, `packages/core/src/-private/live-text.ts`.
- Changed: `eui-page-side-bar.gts` (delegates to `euiPageSidebarClass`),
  `eui-call-out.gts` (`@announceOnMount`).
- Registries: `components.ts`, `template-registry.ts` (added lines only),
  `packages/core/package.json` app-js exports (rollup).
- Generator/parity: `euiBannerStyles` (`components/banner/banner.styles.js`)
  in a `// page-a11y` block of `scripts/generate-eui-styles.mjs` and
  `scripts/eui-upstream-parity.test.mjs`; regenerated `styles.generated.ts`
  and `upstream-sources.json` (the worktree's source-path comments are
  stale because `node_modules` is a symlink; regenerate in main).
- Tests: `tests/integration/components/eui-page-a11y-test.gts` (12 tests).
- Docs: `docs/layout/page-section/` (EuiPageSection, EuiPageSidebar, 3
  demos), `docs/display/banner/` (1 demo), `docs/utilities/live-regions/`
  (EuiScreenReaderLive, EuiLiveAnnouncer, 2 demos); `scripts/api-docs-pages.json`
  entries; the callout API section gained `@announceOnMount`.

## Components and API

- `EuiPageSection`: `@paddingSize` (default `l`; inline padding on the
  section, block padding on the content, as upstream), `@color` (default
  transparent), `@bottomBorder` (`true`/`'extended'`), `@restrictWidth`,
  `@grow`, `@alignment` top/center/horizontalCenter, `@contentProps`
  (`className`, `css`, `style`, `aria-label`, `data-test-subj`),
  `@component` (default `section`), `@css`.
- `EuiPageSidebar`: upstream name of the sidebar; `@sticky` (`true` or
  `{offset}`), `@paddingSize` (default none), `@minWidth` (248),
  `@responsive` (`['xs','s']`/false), `@hasEmbellish`, `@css`. The class is
  built by the exported `euiPageSidebarClass`, which the older
  `EuiPageSideBar` now reuses (same output, `euiPageSideBar` root class
  kept; its existing tests pass unchanged).
- `EuiBanner`: upstream `euiBannerStyles` with container-query layouts;
  `@title` (required), `@headingElement` (h2), `@text`, `@size` s/m (m),
  `@color` highlighted/plain (highlighted), `@actionProps` `{primary,
  secondary}` (EuiButton / EuiButtonEmpty, `{children, onClick, href,
  target, iconType, isDisabled, isLoading, data-test-subj}`), `@onDismiss`,
  `@dismissButtonProps` (aria-label, size, iconSize, isDisabled, css,
  data-test-subj), `@announceOnMount`, `@css`; i18n token
  `euiBanner.dismissAriaLabel`.
- `EuiLiveAnnouncer`: SR-only `role=status` region, content appears after
  upstream's 50ms mount delay and is cleared after `@clearAfterMs` (2000,
  `false` keeps it); `@isActive`, `@role`, `@ariaLive`; re-announces when
  its text changes.
- `EuiScreenReaderLive`: two alternating SR-only live regions (upstream's
  toggle), `@isActive`, `@role`, `@ariaLive`, `@focusRegionOnTextChange`
  (tabindex -1, both regions `aria-live=off`, focus on insert/change).
- `EuiCallOut @announceOnMount`: upstream prop; announces title, text and
  body joined by `,&nbsp;` through EuiLiveAnnouncer (upstream does the same).

All style getters are `@cached`; theme factories go through
`useEuiBorealisStyles`; the theme-independent page-section content styles
are hoisted to module scope.

## Ember differences

- Live regions: upstream reacts to new React `children`. Glimmer blocks
  cannot signal that, so both components render the block into a `hidden`
  element and the `observeLiveText` modifier (MutationObserver +
  test waiter) copies its whitespace-normalized text into the regions.
- EuiBanner `media` is required upstream; here it is an optional
  `<:media>` block (no media slot rendered without it).
- EuiPageSidebar breakpoints/sticky are media queries in the class
  instead of upstream's JS window measurement (as EuiPageSideBar already
  did), so callers' `style` is never replaced.
- React props objects map to `@actionProps`/`@dismissButtonProps`/
  `@contentProps` hashes; `rest` goes to `...attributes` on the root.

## Checks (2026-10-12, worktree)

- `ember-tsc --noEmit`: pass. ESLint on changed sources/tests: pass.
- Parity `node --test scripts/eui-upstream-parity.test.mjs`: 310/310.
- Generator: 353 factories, React-free output verified.
- `generate-api-docs.mjs --check`: pass (102 pages).
- Core rollup build: pass. Vite test build: pass.
- Focused (`filter=Borealis page sections`): 12/12.
- Full core suite (Chromium 130): 1146/1146.
- Demo templates rendered in a throwaway integration test (not committed):
  pass. Site build/tests not run (per brief).

## For the coordinator

- Site: three docs pages were added, so
  `site/tests/acceptance/docs-test.ts` nav count must go from 104 to 107.
- The `eui-call-out.gts` and `eui-page-side-bar.gts` rows in components.md
  belong to other families; consider noting `@announceOnMount` and the
  `euiPageSidebarClass` delegation there.
- `eui-skeleton-loading/screen-reader-live.gts` (new-skeleton family) is a
  private port of upstream EuiScreenReaderLive; it could later delegate to
  the public `EuiScreenReaderLive` (different arg shape: `@text`/`@options`).
