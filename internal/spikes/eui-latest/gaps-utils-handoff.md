# Utility gaps handoff (branch eui-wave/gaps-utils)

Target EUI 123.1.0. Status: see Checks.

## Closed

- `EuiFocusTrap` (`components/eui-focus-trap.gts`): ember-focus-trap's `focusTrap` modifier on a
  `<div data-focus-lock-disabled>` wrapper, created through the registry
  (`_createFocusTrap`), so portalled popovers/combo box lists count as inside.
  Args: `disabled`, `returnFocus` (bool, `FocusOptions`, function), `initialFocus`
  (selector/element/function), `autoFocus`, `data-autofocus`, `onClickOutside`,
  `closeOnMouseup`, `clickOutsideDisables`, `onEscapeKey`, `onActivation`, `onDeactivation`,
  `shards`, `crossFrame`, `scrollLock`, `gapMode`, `noIsolation`, `css`.
  - `shards` are extra containers of the same trap (elements, selectors or functions; re-synced
    when the arg changes) and also count as inside for outside clicks.
  - `crossFrame` false (default): the trap pauses while an iframe outside it has focus. True: stays trapped.
  - `scrollLock`/`gapMode`: counted body lock with scrollbar-width compensation
    (`-private/focus-trap-effects.ts`); `noIsolation={{false}}`: `aria-hidden` plus
    `pointer-events: none` on the outside siblings present at activation (portals added later are untouched).
  - Registry additions (add-only): `focusTrapContains`, `setFocusTrapContainers`.
- `EuiWindowEvent` (`components/eui-window-event.gts`): `@event`, `@handler`; a class helper
  subscribes, re-subscribes on change and removes the listener on teardown. Renders nothing.
- `htmlIdGenerator` (`utils/html-id-generator.ts`, random id instead of uuid v1).
- `@ember-eui/core/theming` now also exports `euiContainerCSS`, `euiContainerQuery`,
  `euiScrollBarStyles`, `euiYScroll`, `euiYScrollWithShadows`, `euiFullHeight` (typed wrappers over the
  extracted upstream mixins; take the theme given to an `@css` function).
- Docs (11 new utilities pages): focus-trap, window-event, error-boundary, html-id-generator,
  inner-text, pretty-duration, provider, container-queries, css-utility-classes, color-palettes,
  scroll. error-boundary, pretty-duration and css-utility-classes say what to use instead and why.
- Illustrations: `EuiIllustration` already takes the `{ id, title, light, dark }` contract, so core never
  imports `@elastic/eui-illustrations`. The Illustration page now documents the optional
  `pnpm add @elastic/eui-illustrations`, an example, the catalog listing, and the Elastic
  License 2.0 / SSPL v1 terms (pointing at `packages/core/NOTICE.md`).

## Skipped

- react-focus-on `as`, `lockProps`, `inert`, `whiteList`, `focusLock`, `allowPinchZoom`,
  `preventScrollOnFocus`, focus guard sentinels, `EuiProvider componentDefaults` (Ember has no
  counterpart or focus-trap handles it).
- `useEuiContainerQuery`, horizontal overflow helper, standalone `PrettyDuration`, EuiErrorBoundary,
  global `eui-*` utility classes: not ported (reasons in the pages and docs-audit-gaps.md).
- Live illustrations gallery: see below.
- Palette functions: not changed (see Unresolved).

## For the coordinator

- Site nav count: `site/tests/acceptance/docs-test.ts` expects 116; this branch adds 11 pages (127 on
  its own, plus other agents' pages). Not edited here.
- Illustrations gallery: to add upstream's searchable gallery to the site, add
  `"@elastic/eui-illustrations": "<version used by @elastic/eui 123.1.0>"` to `site/package.json`
  devDependencies, run `pnpm install` (lockfile updates `pnpm-lock.yaml`), then add a docs demo
  that imports `illustrations` from the package (see the Illustration page for the listing code).
  Not added now because a demo importing a missing package breaks the site build. The gaps row stays until then.
- Unresolved: `euiPaletteColorBlind`/`ForStatus`/`ForTemperature`/`Cool`/`Warm`/`Gray`/`Negative`/
  `Positive`/`BehindText` use the classic EUI colors, not Borealis vis colors; `euiPaletteComplimentary`
  vs upstream `euiPaletteComplementary`. Changing them changes tokens/avatars; left for a decision.

## Behaviour changes to existing tests

None. Existing modal/flyout focus trapping is untouched; the registry only gained exports.

## Checks

- Full core suite: 1785/1785 (Chromium 130). New tests: 15 focus trap, 1 window event, 4 htmlIdGenerator/theming helpers. ember-tsc and eslint on changed files pass; API docs regenerated (4 pages updated).
