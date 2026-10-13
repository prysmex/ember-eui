# Composable EuiPageTemplate handoff

Branch `eui-wave/page-template` (from `feat/eui-latest` at `7d42c225`).
Target EUI 123.1.0 / Borealis 8.1.0. Status: **Migrated** (the full core
suite passes).

## What upstream 123.1.0 has

Checked against `page_template.tsx`, `outer/`, `inner/`, `bottom_bar/`,
`empty_prompt/` and `page/` (section, sidebar, header, `_bottom_border`,
`_restrict_width`). Top-level props that exist: `panelled`,
`bottomBorder`, `contentBorder`, `offset`, `grow`, `restrictWidth`,
`paddingSize`, `minHeight`, `responsive`, `direction`, `mainProps`,
`component`, `css`/`className`/`style`. All are ported. Upstream removed
the old `template` prop API (`EuiPageTemplate_Deprecated`).

## API

```hbs
<EuiPageTemplate @panelled={{true}} @offset={{0}}>
  <:sidebar as |T|>{{#if this.nav}}<T.Sidebar @sticky={{true}}>…</T.Sidebar>{{/if}}</:sidebar>
  <:default as |T|>
    <T.Header @pageTitle="…" />  <T.Section>…</T.Section>
    <T.EmptyPrompt @title="…">body</T.EmptyPrompt>  <T.BottomBar>…</T.BottomBar>
  </:default>
</EuiPageTemplate>
```

Without a sidebar: `<EuiPageTemplate as |T|>…</EuiPageTemplate>`.

- Parts are curried components, so args passed to a part override the
  inherited ones (upstream `{...context} {...props}`):
  - `Header` = `EuiPageHeader` with restrictWidth, paddingSize,
    bottomBorder (`bottomBorder ?? (sidebar ? true : 'extended')`) and
    color (`panelled === false ? transparent : plain`);
  - `Section` = `EuiPageSection` with restrictWidth, paddingSize, color,
    `grow=true`;
  - `EmptyPrompt` gets `panelled = innerPanelled ? true : panelled` and
    `grow=true`;
  - `BottomBar` gets restrictWidth and paddingSize;
  - `Sidebar` gets paddingSize and responsive.
- Outer: `div.euiPageTemplate` with `euiPageOuterStyles` (row, column
  within `@responsive`, grow) and inline `min-block-size: max(minHeight,
  100vh)` (or `minHeight` without grow) and `padding-block-start: offset
  ?? var(--euiFixedHeadersOffset, 0)`. `...attributes` and `@css` go here.
- Inner: `<main>` (`@component`) with `id = mainProps.id ??
  EuiPageTemplateInner_<guid>`, `euiPageInnerStyles` (panelled when
  `panelled ?? hasSidebar`; border when `contentBorder ?? hasSidebar`,
  left (inline start) outside / top inside the `@responsive`
  breakpoints). `@mainProps` takes `id`, `className`, `css`, `style`,
  `role`, `aria-label`, `aria-labelledby`, `data-test-subj`.
- New files: `eui-page-template/sidebar.gts` (`T.Sidebar`),
  `eui-page-template/empty-prompt.gts` (`_EuiPageEmptyPrompt`, with the
  upstream panelled color rules), `eui-page-template/bottom-bar.gts`
  (`_EuiPageBottomBar`). Not registered in components.ts/template-registry
  (upstream doesn't export them either); app-js exports regenerated.
- `EuiEmptyPrompt`: new `<:title>` (inside the EuiTitle), `<:body>`
  (inside the subdued EuiText) and `<:actions as |Item|>` (inside the
  actions flex group; `Item` = EuiFlexItem grow=false) blocks, plus
  private `@has…Block` args so wrappers can forward blocks. Spacing
  follows upstream (title+body: s, actions after title/body: l).
- `EuiBottomBar`: new `@css` composed last (the template part uses it for
  upstream's `overflow:hidden; flex-shrink:0`).
- No generator/parity changes: `euiPageOuterStyles`/`euiPageInnerStyles`
  were already extracted with parity tests. Getters are `@cached`; inner
  styles via `useEuiBorealisStyles`, outer styles are static.

## Ember mechanism for sidebars (why)

Upstream inspects its children (`React.Children`) to pull
`EuiPageTemplate.Sidebar` out of the main column and to derive
`panelled`, `contentBorder` and the header border. Ember can't inspect
children, so:

1. **Placement: a `<:sidebar as |T|>` named block**, rendered before the
   main element. No DOM moving, no `in-element`, FastBoot-safe, and the
   sidebar is in the right place on the first render.
2. **Presence: each rendered `T.Sidebar` registers with the template**
   (constructor → count, destructor → uncount). Only derived state (a
   tracked count). The sidebar block renders before `<main>`, and nothing
   before it reads the count, so on first render the main class, header
   border and empty prompt panelling are right without a second pass or
   backtracking errors. A conditional sidebar (`{{#if}}` inside the block)
   updates the layout in place (tested). This matches upstream exactly:
   only the namespaced sidebar counts, not a raw `EuiPageSidebar`.

`T.Sidebar` yielded to the default block asserts (it would render inside
`<main>`). Rejected alternatives: `has-block "sidebar"` only (can't make a
sidebar conditional — named blocks can't be), and rendering the default
block twice (duplicates non-part content).

## Mode selection and legacy API

The composable layout renders when the default block takes block params
(`has-block-params`), a `<:sidebar>` block is given, or any
composable-only arg is set (`@panelled`, `@bottomBorder`,
`@contentBorder`, `@offset`, `@responsive`, `@direction`, `@component`,
`@mainProps`, `@css`). Otherwise the legacy `@template` API renders
unchanged; it fires `deprecateRemovedUpstream('eui-page-template-legacy',
…)` once per instance (id `ember-eui.eui-page-template-legacy.removed-upstream`,
since 15.0.0, until 16.0.0). Shared args (`@grow`, `@restrictWidth`,
`@paddingSize`, `@minHeight`) keep their defaults; `@paddingSize` now
also types `xs`/`xl` (legacy layouts cast). An empty
`<EuiPageTemplate />` with no args stays legacy.

## Ember differences

- `T.BottomBar` renders where it is placed; upstream portals it to the end
  of `<main>` (after a rAF). Docs say to render it last.
- `T.EmptyPrompt`: default block = body (upstream `children`); title,
  actions, icon and footer are blocks; `@body` still works without a block.
- `T.BottomBar @css` is composed with the overflow css (upstream's `css`
  prop would replace it).
- `@component` takes tag names only (no React component).
- Responsive behaviour via media queries, like the existing sidebar port.

## Tests

`tests/integration/components/eui-page-template-composable-test.gts`, 20
tests: upstream cases (is rendered + custom styles, outer props, inner
props/mainProps/component/panelled, restrictWidth true/number/string,
bottomBorder true/extended/defaults, minHeight, offset incl. 0 and the
fixed-headers variable, every paddingSize on header/section/sidebar/bar,
children placement: 2 sidebars outside main, 3 children inside in order),
plus inheritance and overrides (reactive, no element replacement),
sidebar-derived panelling/border/empty prompt colors, conditional sidebar
toggling, responsive stacking in narrow/wide iframes (default, `[]`, all
breakpoints), RTL border side, `T.EmptyPrompt` centering and the four
upstream color cases, EuiEmptyPrompt blocks, `T.BottomBar`
(sticky/last/overflow/dark/not over the sidebar), light/dark providers,
args-only composable mode, the misplaced-sidebar assert, and the legacy
deprecation. Existing `eui-page-template-test.gts` and the page layout
tests are unmodified and pass.

## Docs

- `docs/templates/page-template`: index rewritten (composable API, what
  parts inherit, Ember differences, brief legacy section); demos d01–d04
  mirror upstream's four examples (skeletons instead of the SVGs); d05 is
  one legacy example. Removed the twelve legacy demos d05–d16.
- **New top-level page** `docs/templates/page-template-guidelines`
  (upstream's guidelines as text do/don't lists, plus the "converting from
  legacy layouts" demo). The site nav count in
  `site/tests/acceptance/docs-test.ts` must go from 114 to **115**.
- Empty prompt demos d08/d09 use `T.EmptyPrompt` (as upstream); page
  header and bottom bar pages mention the parts.
- API tables regenerated (page template, empty prompt, bottom bar); the
  three parts were added to `scripts/api-docs-pages.json` and to the
  generator's `ALIASES`.
- Removed the EuiPageTemplate rows and the EuiEmptyPrompt row from
  `docs-audit-gaps.md`.

## Checks (2026-10-13, worktree, Chromium 130)

- Full core suite: **1353/1353** (main was 1333; +20 new).
- Focused: filter `EuiPageTemplate` 22/22, filter `page` 162/162 (includes the unmodified legacy template tests).
- `ember-tsc --noEmit`: pass. ESLint on changed source/test files: pass.
- Parity: 349/349. `generate-api-docs.mjs --check`: pass.
- Not run (per brief): `sync-injected.mjs`, companion suites, site checks.

## For the coordinator

- Update the site nav count to 115 (new guidelines page).
- `site/app/templates/application.hbs` uses the legacy API
  (`<:pageSideBar>`, `@pageBodyProps`), so the docs site now logs the
  deprecation once. Suggested migration: `<EuiPageTemplate
  @paddingSize="none" @restrictWidth={{false}} class="pageBodyShadow">`
  with `<:sidebar as |T|><T.Sidebar><SideNav …/></T.Sidebar></:sidebar>`
  and `<:default>{{outlet}}</:default>`; check the shadow class target and
  the sidebar's sticky/padding visually.
- Add the deprecation to the 16.0.0 changeset list.
