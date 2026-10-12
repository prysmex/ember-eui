# Page layout family migration handoff

Status: **Migrated** (EuiPage, EuiPageBody, EuiPageContentBody, EuiPageContentHeader, EuiPageContentHeaderSection, EuiPageHeader, EuiPageHeaderContent, EuiPageHeaderSection, EuiPageSideBar, EuiPageTemplate, EuiBottomBar). The full core suite passes in Chromium 130 (668/668), with parity 41/41, types, lint and API docs.

## Upstream mapping

Upstream 123.1.0 dropped the v41 "content" family. Upstream now uses `EuiPageTemplate` (with `_EuiPageOuter`/`_EuiPageInner`), `EuiPageSection`, `EuiPageHeader` and `EuiPageSidebar`. The Ember components and the v41 `EuiPageTemplate` API stay in place, and each one maps onto the closest current factory:

| Ember | Upstream styles |
| --- | --- |
| EuiPage | `page/page.styles.js` `euiPageStyles` (`euiPage`, `row`/`column`, `grow`, `restrictWidth`) + `euiPaddingSize` + `euiBackgroundColor` |
| EuiPageBody | `page_body.styles.js` `euiPageBodyStyles`. When panelled: EuiPanel with the body styles composed over it, as upstream's `css` prop does |
| EuiPageContentBody | `page_section.styles.js` `euiPageSectionContentStyles` (`euiPageSection__content`, `restrictWidth`) + padding on every side |
| EuiPageContentHeader | `page_header_content.styles.js` `childrenOnly.flex` + `center`, with `childrenOnly.responsive` below `m` |
| EuiPageContentHeaderSection, EuiPageHeaderSection | unstyled, like upstream `EuiPageHeaderSection` |
| EuiPageHeader | `page_header.styles.js` `euiPageHeaderStyles` (root, `border` for `'extended'`) + inline padding + background |
| EuiPageHeaderContent | `euiPageHeaderContentStyles` (root, `__top` container, `__leftSideItems`, `__rightSideItems`/`__rightSideItem`, `__titleIcon`, `childrenOnly`) + `euiPageHeaderStyles.border` + upstream's block-padding rules |
| EuiPageSideBar | `page_sidebar.styles.js` `euiPageSidebarStyles` (`euiPageSidebar`, `sticky`, `embellish`) |
| EuiPageTemplate | composes the primitives above. `eui-fullHeight`/`eui-yScroll` get `euiFullHeight()`/`euiYScroll()`. The bottom bar gets `_EuiPageBottomBar`'s `overflow:hidden; flex-shrink:0` |
| EuiBottomBar | `bottom_bar.styles.js` `euiBottomBarStyles`, inside a nested dark `EuiEmotionProvider` (upstream wraps the bar in `EuiThemeProvider colorMode="dark"`) |

`euiPageOuterStyles` and `euiPageInnerStyles` are extracted with parity tests but are not used yet. They are there for a future port of the upstream template API.

## Files

- Components: `eui-page.gts`, `eui-page-body.gts`, `eui-page-content-body.gts`, `eui-page-content-header.gts`, `eui-page-content-header-section.gts` (doc only), `eui-page-header.gts`, `eui-page-header-content.gts`, `eui-page-side-bar.gts`, `eui-page-template.gts`, `eui-bottom-bar.gts`. `eui-page-header-section.gts` is unchanged.
- New `packages/core/src/utils/eui/page-layout.ts`, with the upstream license header. It holds what upstream does inside hooks/components:
  - `useEuiPaddingCSS(side)` as `euiPagePadding`;
  - `setStyleForRestrictedPageWidth` with px numbers;
  - the `euiScreenReaderOnly` mixin;
  - a `euiBreakpoint`-based media query for breakpoint lists (`useIsWithinBreakpoints` evaluated by CSS);
  - `composedOver` (`&&`), which reproduces upstream's "parent `css` after child styles" order when the parent's styles must sit as a second class on a child component's root.
- Generator (`// page layout` block): `euiPageStyles`, `PAGE_MAX_WIDTH`, `setStyleForRestrictedPageWidth`, `euiPageBodyStyles`, `euiPageSectionStyles`, `euiPageSectionContentStyles`, `euiPageSidebarStyles`, `euiPageHeaderStyles`, `euiPageHeaderContentStyles`, `euiPageOuterStyles`, `euiPageInnerStyles`, `euiBottomBarStyles`, `euiBreakpoint`, `euiMinBreakpoint`, `euiMaxBreakpoint`.
  - `euiYScroll` and `euiFullHeight` were added to the **existing** `global_styling/mixins/_helpers.js` entry, with a comment. The object key must stay unique, so union this one by hand at merge.
  - The generator now extracts 52 factories. `styles.generated.ts` and `upstream-sources.json` were regenerated. Existing code only changed through esbuild `_refN` renames.
- Parity (`scripts/eui-upstream-parity.test.mjs`, `// page layout`):
  - 9 factories in the 12-configuration matrix;
  - static `euiPageOuterStyles`;
  - a helper test covering `PAGE_MAX_WIDTH`, `setStyleForRestrictedPageWidth` (5 widths × 2 styles), min/max/range breakpoints with a breakpoint override, `euiYScroll` and `euiFullHeight`.
- Tests:
  - new `tests/integration/components/eui-page-layout-test.gts` (11 tests);
  - updated `eui-page-template-test.gts` and `eui-page-test.gts`, explained below.
- API docs regenerated: `docs/layout/bottom-bar`, `docs/layout/page-header`, `docs/templates/page-template`.
- Not touched:
  - `eui-page-content.gts` (see Unresolved);
  - `helpers/eui-page-restrict-width.ts`, which is still a public app export but no longer used internally;
  - `utils/css-mappings/eui-page*.ts` and `eui-bottom-bar.ts`, now dead but still registered in the mappings index;
  - providers, shared utils, the showcase and the site.

## API and default changes (latest-only)

- **Root classes kept:** `euiPage`, `euiPageBody`, `euiPageContentBody`, `euiPageContentHeader(Section)`, `euiPageHeader`, `euiPageHeaderContent`, `euiPageHeaderContent__top/__rightSideItems/__bottom/__titleIcon`, `euiPageHeaderSection`, `euiPageSideBar`, `euiPageTemplate`, `eui-fullHeight`/`eui-yScroll` (template hooks), and `euiBottomBar` plus `euiBottomBar--{fixed,static,sticky}` (upstream keeps both). All other `--modifier` classes are removed: padding, grow, restrictWidth, direction, sticky, bottomBorder, responsive, alignItems, tabs and position type.
- **restrictWidth** everywhere: `true` = upstream `PAGE_MAX_WIDTH` 1200px inline `max-width` plus `margin-inline: auto` (no class). Numbers are px; strings pass through.
- **EuiPage:**
  - `@paddingSize` defaults to `'none'` (was `'m'`) and also accepts `xs`/`xl`.
  - The hard-coded inline `min-height: 460px` is removed (upstream has none). EuiPageTemplate still sets its own `@minHeight`.
  - New `@color` (default transparent).
  - `direction="row"` stacks below `m` (768px), as upstream.
- **EuiPageBody:**
  - `@paddingSize` defaults to `'none'` even when `@panelled` (was `'l'`). The template passes explicit sizes, so it is unaffected.
  - The unrestricted computed `max-width` is now `100%`, not `none`.
  - `@color` accepts any EuiPanel color.
- **EuiPageContentBody:** `width: 100%`, border-box, padding on every side. Accepts `xs`/`xl`.
- **EuiPageContentHeader:** sections are spaced by a `size.base` gap instead of legacy margins.
  - Keeps an Ember-only `margin-block-end: size.l`. Upstream has no standalone content header.
  - `@responsive` stacks the sections (left-aligned) below `m`.
- **EuiPageHeader:**
  - `@bottomBorder` accepts `'extended'` (border on the header, across padding).
  - `@paddingSize` is split upstream-style: inline padding on the header, block padding on the content.
  - Upstream padding rules apply. Border without padding gets `l` bottom padding. A title plus tabs gets top padding and a default border. Tabs as the title get bottom padding. A header with only tabs gets no padding.
  - `@restrictWidth` now limits and centers `.euiPageHeaderContent`, not the `<header>`.
  - `@style` goes on the header.
  - New `@color`.
  - `@alignItems` default: upstream (`stretch`; `center` for a header with only a default block). It was `top`/`center`.
  - Only a default block: the header now renders upstream's content wrapper plus a children-only flex row (gap base), not raw children.
- **EuiPageHeaderContent (private):**
  - The default block now renders in the left column after a spacer (upstream), not in the `__bottom` area. `__bottom` only holds the tabs under a title.
  - Tabs use upstream `size="m"` without `display="condensed"`.
  - A tabs-only title gets an SR-only `<h1>` with the selected tab's label.
  - `@description` is wrapped in `<p>`.
  - `responsive="reverse"` reorders with CSS `order` below `m` instead of JS. DOM order is kept, which keeps reading order. The JS `useIsWithinBreakpoints` modifier is gone.
  - Right-side items keep block order. Upstream reverses its `rightSideItems` array; Ember has no array to reverse.
- **EuiPageSideBar:**
  - `@paddingSize` defaults to `'none'` (was `'l'`).
  - New `@minWidth` (default 248), `@responsive` (breakpoints, default `['xs','s']`, `false` = never) and `@hasEmbellish`.
  - `@sticky` accepts `{ offset }`. `true` uses `var(--euiFixedHeadersOffset, 0)` for `top` and `max-height: calc(100vh - offset)`.
  - Responsive full width and non-sticky behavior come from media queries in the theme class. Upstream uses JS plus inline styles, so here a caller's `style` is never overwritten.
- **EuiBottomBar:**
  - Always dark (nested dark provider, `@wrapper={{false}} @globalStyles={{false}}`, inheriting overrides and contrast). Border-top, flat shadow, clip-path and the reduced-motion-guarded appear animation come from upstream.
  - `z-index` is `levels.header - 2`.
  - Offsets use the `style` modifier and accept CSS strings. **`@top` no longer defaults to 0**, so sticky bars stick to the bottom as upstream.
  - `@usePortal={{false}}` now works for fixed bars: rendered in place, no displacement. It was documented as "no effect".
  - Displacement also sets/removes `--euiBottomBarOffset` on `<html>`.
  - The SR heading and announcement are hidden with the local upstream SR-only mixin.
- `Element` types are unchanged. `EuiPageTemplate`'s `@paddingSize` type is now the explicit `'none'|'s'|'m'|'l'`, with the same members as before.

## Existing tests changed (why)

- `eui-page-test.gts`: removed legacy class assertions, replaced with computed style checks:
  - `euiPage--grow/--restrictWidth-default/--paddingLarge/--column` became flex-grow / 1200px / 24px / column;
  - `euiPageSideBar--sticky` became `position: sticky`;
  - `euiPageContentHeader--responsive` became flex with space-between;
  - `euiPage--restrictWidth-custom` became `max-width`, plus padding;
  - `euiPageHeader--bottomBorder/--responsive` became the content's computed border;
  - the "no stray class" test now checks computed max widths.
- `eui-page-template-test.gts`:
  - Legacy class assertions became computed checks (grow, padding, max widths, header border/padding/alignment, sidebar sticky/padding, bottom bar padding).
  - Header `maxWidth` assertions moved to `.euiPageHeaderContent`, the upstream location. Header root `@style` is still asserted on the header.
  - Unrestricted bodies assert `max-width: 100%` (upstream). Before, the non-class path gave `none`.
  - The `bundled v41.4.0 Amsterdam CSS` module (24 tests) was a legacy-coexistence suite, which the brief forbids. It is replaced by `latest Borealis layout without legacy CSS` (24 tests) with the same light/dark × template × sidebar matrix:
    - display, min height, where the max width lands, content padding/border/shadow, the panelled body background against tokens, and sidebar sticky/padding/min-width;
    - iframe viewports at 375/767/768/1200 for page stacking, sidebar sticky and full width;
    - the full-height scroll tests, now running without legacy CSS on the extracted utility mixins.
  - Dropped: `alignSelf: center` for centered content, which only legacy CSS provided (see Unresolved).
- No other existing test changed. `eui-bottom-bar-test.gts` and `eui-internals-test.gts` pass unchanged.

## Coverage (eui-page-layout-test.gts, 11 tests)

- **Padding:** all 6 page padding sizes per side, plus default none, display/shrink/grow/background/box-sizing.
- **Page:**
  - grow vs `grow=false` measured in a flex row;
  - restrictWidth `true`/number/rem/merged `@style`, measured and centered in 1500px;
  - subdued background against the token;
  - direction row/column/RTL;
  - responsive stacking and sidebar full width in iframes at `m-1`/`m`.
- **Body:**
  - padding, tag;
  - restricted width measured and centered;
  - the panelled body's flex column beats the panel's `display:block`;
  - panel border pseudo element, custom panel radius/color/border/max width.
- **Content body and content header:**
  - content body width 100% including padding, centered restricted width;
  - content header gap/space-between/margin;
  - LTR/RTL section placement;
  - responsive stacking with the gap in iframes, and the non-responsive control.
- **Side bar:**
  - padding sizes, default min width, number/rem `@minWidth`, embellish;
  - `responsive=false` always sticky, all breakpoints never sticky;
  - real sticky geometry in a scroll container with `--euiFixedHeadersOffset` (top + max-height) and `{offset: 48}`, then non-sticky, with the same element throughout;
  - iframe sticky/static and widths.
- **Header:**
  - title/icon/description/right side items: placement, block order, m gutter;
  - padding split;
  - `true` vs `'extended'` borders with token colors;
  - title+tabs, tabs only (SR h1, visually hidden), tabs as title;
  - restrictWidth content centered in a full-width header;
  - children-only flex;
  - every alignItems value, default stretch/wrap/gap/container type;
  - RTL placement;
  - responsive, reverse, `responsive=false` and children-only reverse in iframes at `m-1`/`m`.
- **Bottom bar:**
  - portal, fixed geometry against a fixed probe (after finishing the appear animation, whose presence is asserted), z-index, offsets incl. rem;
  - dark background/text/border tokens inside a light provider;
  - SR heading hidden;
  - static in place, reactive padding sizes;
  - static → sticky keeps the element and sticks to the scroll container bottom;
  - `usePortal=false` fixed in place.
- **Displacement:** body padding equals the bar height, the CSS variable, the body class, the aria label and live announcement, displacement following padding changes, the opt-out removing padding and the variable, teardown cleanup, and static bars never displacing.
- **Reactive args:** across page/sidebar/body/header/content-body with no element replacement, including header content.
- **Themes:** light/dark nearest provider, sibling isolation, nested JS-object overrides (`size.base`, `border.color`) reaching the page, header border and the dark bar, mode/override changes and their removal.
- **Template full height:** the page stays within its height, content scrolls, and the bottom bar is static with `overflow:hidden; flex-shrink:0`.

## Checks run (2026-10-12, worktree `eui-wave/page-layout`)

Node 22, binaries run directly, Chromium 130 via the scratchpad `google-chrome` shim with `CI=true`.

- Core suite (`vite build --mode=development --out-dir dist-tests && testem --file testem.cjs ci --port 0`): **668 tests, 668 pass, 0 fail**.
- `node --test scripts/eui-upstream-parity.test.mjs`: **41/41 pass**.
- `node scripts/generate-eui-styles.mjs --check`: passes in this worktree (52 factories). The regenerated provenance comments use this worktree's symlinked paths, so re-run in the main checkout after merging.
- `ember-tsc --noEmit`: pass. ESLint on all changed components, `page-layout.ts` and the three test files: pass.
- `node scripts/generate-api-docs.mjs --check`: pass, after regenerating 3 pages.
- Not run (root): rollup build, site build/acceptance, showcase/visual checks.

## Unresolved

1. **EuiPageContent (already migrated, not edited) still relies on legacy classes for `@verticalPosition`/`@horizontalPosition="center"`.** These are `euiPageContent--verticalCenter/--horizontalCenter`, which give `align-self:center`, auto margins and `width:auto`. Without Amsterdam CSS, centered content in `centeredBody`/`centeredContent` templates is no longer centered. Only `grow=false` applies.
   - Suggested fix in `eui-page-content.gts`: compose upstream `euiPageSectionStyles.center`/`horizontalCenter`-style rules, or explicit `alignSelf: center; marginBlock: auto` and `marginInline: auto; width: auto; maxWidth: 100%`, through `euiClass`.
   - It also still emits `euiPageContent--borderRadiusNone` (legacy).
2. **Docs-site visual risks.** The docs shell (`site/app/templates/application.hbs`) and every page-template demo use these components:
   - legacy `euiPage--padding* .euiPageSideBar` margins and `.euiPageBody > .euiPageHeader` margins are gone;
   - header bottom padding/border now follow upstream rules;
   - tabs use size m without condensed display;
   - the side bar default padding is none;
   - the header's default block moved into the left column;
   - centered templates are not centered (item 1).

   On pages that still load Amsterdam CSS, vendor `.euiPageBody`, `.euiPageHeader`, `.euiPageSideBar` and similar base rules still apply alongside the new classes. Audit visually after the merge (docs shell, page-template demos d02/d03/d04/d11, page-header and bottom-bar pages).
3. EuiTabs, EuiIcon, EuiBreadcrumbs and EuiScreenReaderOnly are unmigrated. The header renders them as before. The SR-only and title-icon positioning come from local upstream mixins.
4. Merge note: `euiYScroll`/`euiFullHeight` were appended to the shared `_helpers.js` generator entry, not to a separate key.
5. Dead code to remove in a coordinated cleanup:
   - `utils/css-mappings/eui-page*.ts` and `eui-bottom-bar.ts`;
   - `helpers/eui-page-restrict-width.ts`, a public export that is still legacy class-based.
6. Not ported:
   - upstream's newer `EuiPageTemplate` API (Outer/Inner/Section/Sidebar context, `panelled`, `offset`, `bottomBorder` on the template);
   - `EuiPageSection` as a public component;
   - `tabsProps`/`iconProps` beyond `className`;
   - the bottom bar announcement for non-portal bars (upstream always renders it; Ember kept portal-only).

## Next step

Root:
1. Merge, re-run `generate-eui-styles --check` in the main checkout, then run the core build and the site build/acceptance.
2. Fix EuiPageContent centering (item 1).
3. Do a visual pass of the docs shell and the page-template/page-header/bottom-bar docs pages.
