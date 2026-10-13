# Navigation family migration handoff (Tabs, TabbedContent, Breadcrumbs, Pagination, Steps)

Status: **Migrated**. Full core suite 698/698 in Chromium 130 (including 16 new navigation tests), parity 63/63, types, lint and API docs pass.

## Files

- Components (`packages/core/src/components/`), all Glimmer classes on extracted factories via `getEuiThemeContext` / `useEuiBorealisStyles` / `euiClass`, class getters `@cached`, static style objects hoisted to module scope:
  - `eui-tabs.gts`, `eui-tab.gts` (`eui-tabbed-content.gts` unchanged: it composes EuiTabs/EuiTab and inherits their styles/keyboard)
  - `eui-breadcrumbs.gts` (plus an internal `BreadcrumbItem` class in the same module)
  - `eui-pagination.gts`, `eui-pagination-button.gts`, `eui-pagination/button-wrapper.gts`, `eui-pagination/next-button.gts`, `eui-pagination/previous-button.gts`, **new** `eui-pagination/arrow-button.gts` (upstream `EuiPaginationButtonArrow`)
  - `eui-steps.gts` (unchanged: upstream has no styles for the container), `eui-step.gts`, `eui-step-number.gts`, `eui-steps-horizontal.gts`, `eui-step-horizontal.gts`, `eui-sub-steps.gts`
- New private modules (`packages/core/src/-private/`): `eui-tabs-context.ts` (upstream `EuiTabsContext`: size/expand), `eui-steps-horizontal-context.ts` (size), `window-resize.ts` (resize modifier shared by Breadcrumbs and Pagination).
- `scripts/generate-eui-styles.mjs` and `scripts/eui-upstream-parity.test.mjs`: `// navigation` block (below). `styles.generated.ts` / `upstream-sources.json` regenerated (70 factories); provenance comments normalized to the main checkout's `// node_modules/...` form. Regenerate+normalize is byte-identical to the committed files (`cmp`). The diff also renumbers some esbuild-internal identifiers (`_ref31` → …) in unrelated factories; that is esbuild output, not a behavior change.
- Tests: new `packages/core/tests/integration/components/eui-navigation-test.gts` (16 tests); legacy assertions updated in `eui-tabs-test`, `eui-steps-test`, `eui-breadcrumbs-test`, `eui-pagination-test`, `eui-internals-test`, `eui-header-test`, `eui-table-test` (explained below).
- Docs: regenerated API sections of `docs/navigation/{tabs,steps,breadcrumbs/index,pagination/index}.md`.
- Not touched: Link/ButtonEmpty/ButtonIcon/Title/Text, EuiIcon, EuiPopover, EuiHeaderBreadcrumbs, EuiPageHeaderContent, EuiTablePagination, providers/shared utils, `utils/css-mappings/eui-tabs.ts` / `eui-step-number.ts` (now unused by the components, still registered in the mappings index; remove in the coordinated cleanup).

## Generator entries added (`// navigation`)

`euiTabsStyles`; `euiTabStyles`, `euiTabContentStyles`; `euiBreadcrumbsListStyles`; `euiBreadcrumbStyles`; `euiBreadcrumbContentStyles`, `euiBreadcrumbPopoverStyles`; `euiPaginationStyles`; `euiPaginationButtonStyles`; `euiStepVariables`, `euiStepStyles`, `euiStepContentStyles`, `euiStepTitleStyles`; `euiStepNumberStyles`, `euiStepNumberContentStyles`; `euiStepsHorizontalStyles`; `euiStepHorizontalStyles`, `euiStepHorizontalNumberStyles`, `euiStepHorizontalTitleStyles`; `euiSubStepsStyles`; plus the helpers `euiScreenReaderOnly` (accessibility/screen_reader_only) and `euiTextTruncate` (global_styling/mixins/_typography). Every theme factory is in the parity `factories` map (12 configurations); `euiStepVariables`, `euiScreenReaderOnly` and `euiTextTruncate` have their own deepEqual test. Other families may add `euiScreenReaderOnly` too; union at merge.

## API and default changes (latest-only)

### EuiTabs / EuiTab / EuiTabbedContent
- Sizes are upstream `s`/`m`/`l` (gap m/base/l; content xs/s/m font, 32/40/40px line height). **`xl` is kept as an alias of `l`** (EuiPageHeaderContent passes it). `@display="condensed"` is kept as an Ember alias that only removes the bottom border (upstream removed condensed).
- Bottom border is upstream's inset box-shadow (real border in forced contrast). Selected tab: `textHeading` + `::after` primary underline (`border.width.thick`, doubled in high contrast); unselected `textSubdued`; disabled `textDisabled` + `not-allowed`, disabled+selected underline `textDisabled`. Content truncates (upstream `eui-textTruncate` via the `euiTextTruncate` mixin).
- **Keyboard (new, upstream):** ArrowLeft/ArrowRight on the tablist move focus across enabled tabs and wrap. Focus only; selection still needs click/Enter (manual activation). Arrow direction is DOM order, also in RTL (as upstream).
- **Roving tabindex (new, upstream):** selected tab `tabindex="0"`, others `-1`. Behavior change: a tab list with no selected tab has no keyboard tab stop (same as upstream).
- New `@target`/`@rel` on EuiTab (secure rel from EuiLink's `getSecureRelForTarget`); `javascript:` hrefs disable the tab (upstream `validateHref`).
- Classes: `euiTabs`, `euiTab`, `euiTab-isSelected`, `euiTab__prepend/__content/__append` kept. Removed legacy `euiTabs--small/--large/--xlarge/--condensed/--expand/--bottomBorder`, `euiTab-isDisabled`.
- EuiTabbedContent: unchanged API; inherits the keyboard handling. Kept Ember behavior of rendering no panel when the selected tab disappears (upstream falls back to the first tab).

### EuiBreadcrumbs
- Upstream page type: slanted `::after` separators, 160px (10 × size.base) truncation per breadcrumb with the last one filling the rest, `nowrap` list when `@truncate`. Per-breadcrumb `truncate: false/true` now overrides `@truncate` (upstream).
- **New `@type`** (`page` default, `application` arrow chips with clip-path, `breadcrumbsApplication*` tokens, primary light background for clickable ones) and **`@lastBreadcrumbIsCurrentPage`** (default `true`).
- **Default `@responsive` is now `true`** (upstream `{ xs: 1, s: 2, m: 4 }`); it was off. No effect at l/xl widths. Pass `@responsive={{false}}` for the old behavior.
- **Link color default is `subdued` for every breadcrumb** (upstream); the last clickable breadcrumb used to be `text`. Interactive breadcrumbs get the dotted underline and upstream's hover/focus `textPrimary` (via the `euiLink-subdued` label selector).
- `<nav aria-label="Breadcrumbs">` (i18n `euiBreadcrumbs.nav.ariaLabel`); `li[data-test-subj="euiBreadcrumb"]`.
- Collapsed "…" item: EuiLink button with `aria-label`/`title` "See collapsed breadcrumbs" (Ember kept the label on the button; upstream puts it on an inner span and wraps the button in a tooltip — EuiToolTip not used), chevron EuiIcon (`arrowDown`, rendered as-is), popover wrapper `max-inline-size` upstream. Popover crumbs have no `aria-current` (upstream `lastBreadcrumbIsCurrentPage=false`), replacing the old mutation of the caller's objects (`'aria-current' = 'false'` was written into the input array; fixed).
- `EuiBreadcrumb.ellipsis` / `'aria-current'` stay in the type, documented as deprecated/ignored (type stability). New optional `rel`.
- Removed legacy classes: `euiBreadcrumbs--truncate`, `euiBreadcrumb--last/--collapsed/--truncate`, `euiBreadcrumbs__inPopover`.

### EuiPagination (+ button, wrapper, arrows)
- **New `@responsive`** (default `['xs','s']`, `false` disables): compressed below the `m` breakpoint, as upstream.
- **Compressed now shows first/last arrows** and "`{page} of {total}`" as plain spans (first span `textPrimary` semibold), not page buttons; `EuiHideFor` removed.
- **Arrow labels follow upstream:** "First page", "Previous page", "Next page", "Last page" (tokens `euiPaginationButtonArrow.*`). Before: "Previous page, {n}" / "Next page, {n}". Icons `arrowStart/arrowLeft/arrowRight/arrowEnd` (Ember names for upstream's `chevronLimit*/chevronSingle*`). Arrows carry `data-test-subj="pagination-button-<type>"` and class `euiPaginationArrowButton`. No tooltip (EuiToolTip is another family).
- **Active page `aria-current="page"`** (was `"true"`), bold primary underlined, disabled. Page buttons get `data-test-subj="pagination-button-<index>"`.
- With `aria-controls`, page and enabled arrow buttons link to `#id` (upstream) and clicks `preventDefault()` then focus the controlled element.
- Screen-reader status `<span role="status">Page n of N</span>` (upstream; "collection" when `pageCount` is 0).
- Ellipsis is `li.euiPagination__item[aria-label]` styled `textDisabled`. Removed legacy `euiPaginationButton-isActive/-isPlaceholder/--hideOnMobile`.
- Kept Ember semantics: `@activePage` must be 0..pageCount-1 (no upstream negative "from end" pages), and out-of-range clicks are ignored; next/last are disabled when `pageCount` is 0. EuiPaginationButton `@paddingSize`/`@hideOnMobile` are accepted but deprecated no-ops; new `@ariaControls` arg. Previous/Next private components keep their signatures (`props.href` is now derived, ignored if passed).

### Steps
- EuiStep: upstream connecting line, content margin/padding, title wrapper gap, per-size title styles; **`@titleSize` adds `xxs`** (16px dot, no number); `@step` optional (default 1). Disabled title uses upstream high-contrast-adjusted disabled color.
- EuiStepNumber: upstream sizes (m/s 32px, xs 24px, none/xxs 16px), all statuses including **new `current`** (scale 1.1 + inset ring), `complete/warning/danger` filled button colors with icons labelled by upstream strings ("Step 2 is complete"), `loading` spinner, `incomplete` hollow, `disabled` filled-disabled. Screen-reader text is upstream's status text unless `@stepAriaLabel` is given. `@isHollow` is a deprecated alias for `@status="incomplete"`.
- EuiStepsHorizontal: **new `@size`** (`xs`/`s`/`m`, via context; steps may also take `@size`). EuiStepHorizontal: upstream layout, connecting lines (logical, flip in RTL), title (bold xs title, hidden below `m`), `aria-label` from upstream strings, `aria-disabled`, `data-step-status`, `current` status. `@isComplete`/`@isSelected` kept (map to `complete`/`current`); `@title` still sets `title`. Disabled steps ignore clicks.
- `li` gets upstream `euiStepsHorizontal__item` and keeps `euiStepHorizontal__item`. Removed legacy `euiStep--small`, `euiStep-isDisabled`, `euiStepNumber--<status>`, `euiStepNumber-isHollow`, `euiStepNumber--small`, `euiStep__circle`, `euiStepHorizontal-is*`.
- EuiSubSteps: `lightestShade` box, base padding/margin, border in preferred contrast, lower-alpha ordered lists.

### Scoped resets
Box sizing everywhere; button resets (no border/background/margin, Borealis font) on tabs and horizontal steps; list resets on breadcrumbs, pagination and horizontal steps. Screen-reader-only text uses the extracted `euiScreenReaderOnly` mixin (the `screenReaderOnly` modifier has no styles without legacy CSS).

### Performance rules (coordinator update)
All theme factories are read only through `useEuiBorealisStyles(context, factory)`; every getter that calls `euiClass` is `@cached`; static style objects (box-sizing/list resets) and the theme-independent `euiScreenReaderOnly()`/`euiTextTruncate()` results are module constants. Resets that need the theme font family are built inside the cached getters. Step/Pagination/Tabs/Breadcrumb pieces that compute styles are Glimmer classes; only `EuiSteps` (no styles), the pagination wrapper/next/previous wrappers and EuiTabbedContent compute no styles.

### Composition order note
Upstream passes `css` into EuiLink/EuiButtonEmpty/EuiText so its rules come last. Here classes are passed as attributes; they win only because they are serialized when the child splats `...attributes` (after the child's own class). Classes passed to migrated children are therefore computed in the component that renders the child (`BreadcrumbItem`, `EuiPaginationButton`, cached getters read in the attribute position), never precomputed in a parent loop. Residual edge: if a child's own class composition changes later while ours is already cached (e.g. a breadcrumb's `color` changes reactively), the child's new class is inserted after ours and its reset could win for overlapping properties (padding).

## Existing test changes
- `eui-tabs-test`: `euiTabs--small/--expand/--bottomBorder`, `euiTab-isDisabled`, `euiTabs--condensed` class checks replaced by computed gap/box-shadow/flex-grow and `isDisabled`.
- `eui-steps-test`: status/size classes replaced by icon `aria-label`s, screen-reader text, computed hollow background and 24px xs width; horizontal state classes replaced by upstream `data-step-status`.
- `eui-breadcrumbs-test`: `--last`/`--collapsed`/`__inPopover`/`--truncate` classes replaced by nav `aria-label`, the collapsed button's label, the popover panel, and computed `flex-wrap: nowrap`.
- `eui-pagination-test`: placeholder class → `li.euiPagination__item[aria-label]`; "Next page, n"/"Previous page, n" → upstream "Next page"/"Previous page"; `aria-current="true"` → `"page"`.
- `eui-internals-test`: step-number classes → icon label/hollow background; pagination button `-isActive`/`aria-current="true"` → `aria-current="page"`.
- `eui-header-test`: `euiBreadcrumbs--truncate` → computed `nowrap` (EuiHeaderBreadcrumbs itself untouched).
- `eui-table-test`: table pagination `aria-current="true"` → `"page"`.

No unrelated assertion was weakened.

## New coverage (`Borealis navigation`, 16 tests)
Tab sizes (gap, font size relative to root, line height, measured gap/height); selected indicator/disabled/disabled-selected/link/javascript:/expand/bottom border/condensed; arrow-key navigation with wrap and disabled skip + manual activation + aria-controls/labelledby; reactive tab args without replacement; breadcrumbs separators, truncation (max-width and measured), per-crumb override, aria-current, subdued links, title, click; max/responsive-object/default collapse, popover contents and no aria-current, reactive `@max`; application type colors/contrast/clip-paths/radius/overlap and reactive type switch; pagination pages/ellipsis/active styles/disabled ends/status text/clicks; compressed text/arrows/aria-controls links/focus/no hash navigation/reactive compressed toggle; every step status color + icon/number/screen-reader content; step title sizes, connecting line geometry, content padding, xxs dot, sub steps; standalone step number reactivity and aliases; horizontal steps layout, equal widths, lines, labels, disabled clicks, sizes reactive, RTL lines/order; light/dark nearest provider + sibling isolation + contrast; JS-object overrides (primary, lightestShade, size) scoped and removable, preferred/forced high contrast; attributes/classes/events.

## Checks run (2026-10-12, worktree `eui-wave/navigation`)
Environment: Node 22.22.1, binaries run directly (no pnpm), Chromium 130 via the scratchpad `google-chrome` shim, `CI=true`.

- Core suite (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **698 tests, 698 pass, 0 fail**.
- Filtered `/navigation|tabs|steps|breadcrumbs|pagination|building blocks|header|page|table/i`: 165 tests, 164 pass before the `eui-table-test` fix (its `aria-current="true"` assertion), fixed afterwards.
- `node --test scripts/eui-upstream-parity.test.mjs`: **63/63 pass**.
- `ember-tsc --noEmit`: pass. ESLint on all changed/new components, private modules and tests: pass.
- `node scripts/generate-api-docs.mjs --check`: pass after regenerating 4 pages.
- `node scripts/generate-eui-styles.mjs --check`: throws "Stale generated artifact" **in this worktree only** (symlinked `node_modules` provenance paths). Regenerating and normalizing the comment paths is byte-identical to the committed files.
- Not run (root): rollup core build, site build/acceptance, showcase visual checks.

## Unresolved
1. Responsive breadcrumbs/pagination default on: callers on narrow screens now collapse/compress (upstream behavior). Visual check of header/page-header breadcrumbs and table pagination on mobile widths.
2. EuiToolTip is not used for the collapsed breadcrumb and arrow buttons (other family); add when tooltips migrate.
3. Icons: pagination/breadcrumb use Ember glyph names (`arrowStart`, `arrowLeft`, `arrowRight`, `arrowEnd`, `arrowDown`); switch to upstream `chevron*` names if the icon family adds them. Icon sizing is not styled locally (icon family).
4. Roving tabindex makes tab lists without a selected tab unreachable by Tab key (upstream parity); consider a fallback (first enabled tab) if a11y review prefers.
5. Composition order edge case described above; a shared way to pass extra `css` into migrated children (e.g. an `@css` arg composed last) would remove it.
6. Dead css-mappings `eui-tabs.ts`, `eui-step-number.ts`.

## Next step
Root: merge (union the `// navigation` generator/parity blocks), regenerate in the main checkout, run the core build and site checks, and visually pass the tabs/breadcrumbs/pagination/steps docs pages (including mobile widths).
