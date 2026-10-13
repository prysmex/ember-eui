---
title: Page template
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Page template"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiPageTemplate` is a composable component for creating the different
types of page layout patterns described in these docs. It is somewhat
opinionated, but still has the ability to customize most of the inner
components directly on their instance. See the
[page template guidelines](/docs/core/docs/templates/page-template-guidelines)
for when to use which layout.

```hbs
<EuiPageTemplate @panelled={{true}} @restrictWidth={{true}}>
  <:sidebar as |T|>
    <T.Sidebar @sticky={{true}}><EuiSideNav @items={{this.nav}} /></T.Sidebar>
  </:sidebar>
  <:default as |T|>
    <T.Header @pageTitle="Users" @iconType="users">
      <:rightSideItems as |Item|>
        <Item><EuiButton @fill={{true}}>Invite user</EuiButton></Item>
      </:rightSideItems>
    </T.Header>
    <T.Section>…the page's content…</T.Section>
    <T.BottomBar>…save and cancel…</T.BottomBar>
  </:default>
</EuiPageTemplate>
```

Without a sidebar, yield the parts straight from the template:
`<EuiPageTemplate as |T|> <T.Header …/> <T.Section>…</T.Section> </EuiPageTemplate>`.

### What the parts inherit

| Part | Extends | Inherits from the template |
| --- | --- | --- |
| `T.Sidebar` | `EuiPageSidebar` | `@paddingSize`, `@responsive` |
| `T.Header` | `EuiPageHeader` | `@restrictWidth`, `@paddingSize`, `@bottomBorder` (default `true` with a sidebar, `'extended'` without), color (`'plain'`, or `'transparent'` when `@panelled={{false}}`) |
| `T.Section` | `EuiPageSection` | `@restrictWidth`, `@paddingSize`, color (as the header), `@grow={{true}}` |
| `T.EmptyPrompt` | `EuiEmptyPrompt` in a centered `EuiPageSection` | `@panelled` (`true` when the content is panelled), `@grow={{true}}` |
| `T.BottomBar` | `EuiBottomBar` (sticky) around an `EuiPageSection` | `@restrictWidth`, `@paddingSize` |

Args you pass to a part override what it inherits. Use the plain
components (e.g. `EuiPageSection`) in the template when you deliberately
don't want the settings to apply.

### How the template differs in Ember

- Upstream finds its `EuiPageTemplate.Sidebar` children and renders them
  outside the main element. Ember components can't inspect their
  children, so sidebars go in the `<:sidebar as |T|>` block, which is
  rendered before the main element. Each rendered `T.Sidebar` registers
  with the template, so a conditional sidebar (`{{#if}}` inside the
  block) panels and borders the content like upstream.
- The main element is upstream's `<main>` (`@component` changes its tag,
  `@mainProps` its `id`, `className`, `css`, `style`, `role`, labels and
  `data-test-subj`). Responsive stacking and border placement use CSS
  media queries over the `@responsive` breakpoints instead of measuring
  the window.
- `T.BottomBar` renders where you put it (upstream moves it to the end of
  the main element): render it last.
- `T.EmptyPrompt`'s default block is the prompt's body; its title,
  actions, icon and footer are named blocks (`<:title>`, `<:actions as
  |Item|>`, `<:icon>`, `<:footer>`).

### Legacy API

The older `@template` API (with `@pageHeader`, `@pageSideBarProps`,
`@pageBodyProps`, `@pageContentProps`, `@pageContentBodyProps`,
`@bottomBarProps`, `@fullHeight` and the `<:pageSideBar>`,
`<:pageHeader…>` and `<:bottomBar>` blocks) was removed upstream. It still
works and is deprecated until 16.0.0; see the last example.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiPageTemplate

A whole page layout. The composable API (upstream's) yields the page's
parts, which inherit the template's settings:

```hbs
<EuiPageTemplate @panelled={{true}}>
  <:sidebar as |T|><T.Sidebar>…</T.Sidebar></:sidebar>
  <:default as |T|>
    <T.Header @pageTitle="Users" />
    <T.Section>…</T.Section>
    <T.BottomBar>…</T.BottomBar>
  </:default>
</EuiPageTemplate>
```

The legacy API (`@template`, `@pageHeader`, `<:pageSideBar>`, …) is
deprecated: upstream removed it.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@restrictWidth` | `boolean \| number \| string` | `true` | Shared by both APIs. Max width of the header and the sections' content: `true` for EUI's default (1200px), a number in px or any CSS width. |
| `@grow` | `boolean` | `true` | Shared by both APIs. Grows the page to fill its flex parent; with the composable API it also makes the page at least as tall as the window. |
| `@paddingSize` | `EuiPagePaddingSize` | `'l'` | Shared by both APIs. Padding of the header, sections, sidebar and bottom bar: `'none'`, `'xs'`, `'s'`, `'m'`, `'l'` or `'xl'` (`'xs'` and `'xl'` with the composable API only). |
| `@minHeight` | `number \| string` | `460` | Shared by both APIs. Minimum height of the page, in px or any CSS height. With the composable API and `@grow`, the page is at least `max(minHeight, 100vh)`. |
| `@panelled` | `boolean` | panelled when there is a sidebar | Composable API. Puts the main content on a plain panel and sections and the header on plain backgrounds; `false` makes them transparent. |
| `@bottomBorder` | `boolean \| 'extended'` | `true` with a sidebar, `'extended'` without | Composable API. Border under `T.Header`: `true` within the restricted width, `'extended'` across the whole header. |
| `@contentBorder` | `boolean` | `true` with a sidebar | Composable API. A border separating the main content from the sidebar (on its inline start, or on top when stacked). |
| `@offset` | `number` | the `--euiFixedHeadersOffset` CSS variable that fixed `EuiHeader`s maintain; pass `0` to ignore them | Composable API. Top padding of the page in px, to clear fixed headers. |
| `@responsive` | `EuiPageBreakpoint[]` | `['xs', 's']` | Composable API. Theme breakpoints (`'xs'`…`'xl'`) where the sidebar stacks above the content and takes the full width. |
| `@direction` | `'row' \| 'column'` | `'row'` | Composable API. `'row'` puts the sidebar beside the content (stacking on `@responsive` breakpoints); `'column'` always stacks it. |
| `@component` | `string` | `'main'` | Composable API. Tag of the main content wrapper. |
| `@mainProps` | `EuiPageTemplateMainProps` |  | Composable API. Attributes of the main content wrapper: `{ id, className, css, style, role, 'aria-label', 'aria-labelledby', 'data-test-subj' }`. |
| `@css` | `EuiCss` |  | Composable API. Styles composed last into the page's class (upstream's `css`). |
| `@template` |  | `'default'` | Legacy API. Layout: `'default'` (header and content), `'centeredBody'` (content panel centered in the page), `'centeredContent'` (content centered in the body, e.g. an empty prompt) or `'empty'` (no panels). |
| `@pageBodyProps` |  |  | Legacy API. Props for the `EuiPageBody`, overriding layout defaults. |
| `@pageContentProps` |  |  | Legacy API. Props for the `EuiPageContent`: `{ className, hasBorder, hasShadow, color, borderRadius, grow, role }`. |
| `@pageContentBodyProps` |  |  | Legacy API. Props for the `EuiPageContentBody`, overriding layout defaults. |
| `@pageHeader` |  |  | Legacy API. The page header, as EuiPageHeader args: `{ pageTitle, iconType, description, tabs, responsive, bottomBorder }`. Use the `<:pageHeader…>` blocks for its title, description and actions. |
| `@pageSideBarProps` |  |  | Legacy API. Props for the side bar, including `sticky` and `paddingSize`. |
| `@bottomBarProps` | `NormalProps & EuiButtomBarArgs` |  | Legacy API. Props for the bottom bar; override the layout defaults. |
| `@fullHeight` | `boolean \| 'noscroll'` | `false` | Legacy API. Stretches the page to the window's height and scrolls the content instead of the page (templates `'default'` and `'empty'`, on medium screens and up). Use `'noscroll'` to fill the height without adding a scrolling wrapper around the content. |

Deprecated: `@bottomBar` (Has no effect, use the `<:bottomBar>` block.); `@hasPageHeader` (Has no effect.); `@hasPageContent` (Has no effect.); `@hasPageContentBody` (Has no effect.).

| Block | Description |
| --- | --- |
| default block | The page's content. Composable API: yields the parts (`as \|T\|`), to stack `T.Header`, `T.Section`, `T.EmptyPrompt`, `T.BottomBar` or any content in the main element, in order. |
| `<:sidebar>` | Composable API. Sidebars (`T.Sidebar`, may be conditional), rendered beside the main element. Any rendered `T.Sidebar` panels and borders the content, like upstream. |
| `<:pageSideBar>` | Legacy API. A side bar, e.g. an `EuiSideNav`. |
| `<:pageHeaderPageTitle>` | Legacy API. The header's title, instead of `pageHeader.pageTitle`. |
| `<:pageHeaderDefault>` | Legacy API. Extra header content. |
| `<:pageHeaderDescription>` | Legacy API. The header's description. |
| `<:pageHeaderRightSideItems>` | Legacy API. Header actions; yields an item to wrap each in, see EuiPageHeader. |
| `<:bottomBar>` | Legacy API. Content of a bottom bar (EuiBottomBar), e.g. save/cancel buttons. |

### EuiPageTemplateSidebar

`T.Sidebar` of `EuiPageTemplate` (upstream `EuiPageTemplate.Sidebar`):
an `EuiPageSidebar` with the template's `@paddingSize` and
`@responsive`. Render it in the template's `<:sidebar as |T|>` block.

Also takes the args of `EuiPageSidebar`.

### EuiPageTemplateEmptyPrompt

`T.EmptyPrompt` of `EuiPageTemplate` (upstream
`EuiPageTemplate.EmptyPrompt`): an `EuiEmptyPrompt` centered in a growing
`EuiPageSection`. The default block is the prompt's body.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@panelled` | `boolean` |  | Shows the prompt as a panel on a plain section: the prompt is `'subdued'` unless `@color` says otherwise. The template sets it when its content is panelled (e.g. with a sidebar). |
| `@color` | `PromptColor` | `'subdued'` when panelled, `'plain'` otherwise | Color of the prompt (any `EuiEmptyPrompt` color). |
| `@paddingSize` | `EuiPagePaddingSize` | `'l'` | Padding of the section and the prompt: `'none'`, `'xs'`, `'s'`, `'m'`, `'l'` or `'xl'`. |
| `@grow` | `boolean` | `true` | Grows the section to fill the page's height. |
| `@restrictWidth` | `EuiPageRestrictWidth` | `false` | Max width of the section's content: `true` for EUI's default (1200px), a number in px or any CSS width. |
| `@alignment` | `EuiPageSectionAlignment` | `'center'` | Alignment of the prompt in the section: `'top'`, `'center'` or `'horizontalCenter'`. |
| `@layout` | `PromptArgs['layout']` |  | `'vertical'` or `'horizontal'`, see `EuiEmptyPrompt`. |
| `@iconType` | `PromptArgs['iconType']` |  | Large icon above the title. |
| `@iconColor` | `PromptArgs['iconColor']` |  | Color of the icon. |
| `@title` | `PromptArgs['title']` |  | Title text; use the `<:title>` block for a heading. |
| `@titleSize` | `PromptArgs['titleSize']` | `'m'` | Size of the title. |
| `@body` | `PromptArgs['body']` |  | Body text, when there is no default block. |
| `@actions` | `PromptArgs['actions']` |  | Action components, see `EuiEmptyPrompt`. |
| `@footer` | `PromptArgs['footer']` |  | Footer text; use the `<:footer>` block for markup. |
| `@hasBorder` | `PromptArgs['hasBorder']` | `true` for a `'plain'` prompt | Adds a border. |

| Block | Description |
| --- | --- |
| default block | The prompt's body (upstream's `children`). |
| `<:icon>` | Custom content instead of the `@iconType` icon. |
| `<:title>` | The title, inside an `EuiTitle`, e.g. `<h2>No spice</h2>`. |
| `<:actions>` | Actions; wrap each in the yielded item, see `EuiEmptyPrompt`. |
| `<:footer>` | The footer, e.g. a link or a button. |

### EuiPageTemplateBottomBar

`T.BottomBar` of `EuiPageTemplate` (upstream
`EuiPageTemplate.BottomBar`): a sticky `EuiBottomBar` at the end of the
page's main content, never over the sidebar, with its content aligned to
the template's `@restrictWidth` and `@paddingSize`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@paddingSize` | `EuiPagePaddingSize` | the template's `@paddingSize` | Padding of the bar's content (an `EuiPageSection`): `'none'`, `'xs'`, `'s'`, `'m'`, `'l'` or `'xl'`. |
| `@restrictWidth` | `EuiPageRestrictWidth` | the template's `@restrictWidth` | Max width of the bar's content, centered. |
| `@position` |  | `'sticky'` | Where the bar sits, see `EuiBottomBar`; `'sticky'` keeps it at the bottom of the main content. |
| `@css` | `EuiCss` |  | Styles composed last into the bar's class (upstream's `css`). |

Also takes the args of `EuiBottomBar`.

| Block | Description |
| --- | --- |
| default block | The bar's content, e.g. buttons in an `EuiFlexGroup`. |

### EuiPage

The outermost layout of a page: holds an optional `EuiPageSideBar` and an `EuiPageBody`. See also EuiPageTemplate.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@restrictWidth` | `boolean \| number \| string` | `false` (no limit) | Max width of the page, centered: `true` for EUI's default (1200px), a number in px, or any CSS width. |
| `@paddingSize` | `EuiPagePaddingSize` | `'none'` | Padding around the page: `'none'`, `'xs'`, `'s'`, `'m'`, `'l'` or `'xl'`. |
| `@grow` | `boolean` | `true` | Grows to fill its flex parent (`flex-grow: 1`). |
| `@direction` | `'row' \| 'column'` | `'row'` | `'row'` puts an `EuiPageSideBar` beside the body from the theme's `m` breakpoint up and stacks them below it; `'column'` always stacks them. |
| `@color` | `string` | `'transparent'` | Background: `'transparent'`, `'plain'`, `'subdued'`, `'highlighted'`, `'accent'`, `'accentSecondary'`, `'primary'`, `'success'`, `'warning'` or `'danger'`. |
| `@style` | `Record<string, string>` |  | Inline styles, merged with the max width. |

| Block | Description |
| --- | --- |
| default block | `EuiPageSideBar` and `EuiPageBody`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiPageSideBar

The side column of an EuiPage, e.g. with an `EuiSideNav`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@sticky` | `boolean \| { offset?: number }` |  | Keeps the side bar in view (and scrollable) while the page scrolls, except on `@responsive` breakpoints. `true` offsets it by the `--euiFixedHeadersOffset` CSS variable (fixed headers); pass `{ offset: 48 }` for a pixel offset. |
| `@paddingSize` | `EuiPagePaddingSize` | `'none'`, as upstream (formerly `'l'`) | Padding: `'none'`, `'xs'`, `'s'`, `'m'`, `'l'` or `'xl'`. |
| `@minWidth` | `number \| string` | `248` | Minimum width, in px or any CSS width. |
| `@responsive` | `EuiPageBreakpoint[] \| false` | `['xs', 's']` | Theme breakpoints where the side bar takes the full width and is never sticky (an `EuiPage` stacks it above the body there). `false` keeps the desktop layout everywhere. |
| `@hasEmbellish` | `boolean` |  | Adds upstream's subtle diagonal background embellishment. |

| Block | Description |
| --- | --- |
| default block | The side bar content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiPageBody

The main column of an EuiPage: header, content and so on.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@restrictWidth` | `boolean \| number \| string` | `false` (no limit) | Max width of the body, centered: `true` for EUI's default (1200px), a number in px, or any CSS width. |
| `@tagName` | `string` | `'div'` | Tag of the body (without `@panelled`). |
| `@borderRadius` |  | `'none'` | Border radius of the panel: `'none'` or `'m'`. |
| `@paddingSize` |  | `'none'`, as upstream, also when `@panelled` (formerly `'l'` when panelled) | Padding: `'none'`, `'s'`, `'m'` or `'l'`. |
| `@panelled` | `boolean` |  | Renders the body as an `EuiPanel` (plain background, border). |
| `@color` |  |  | Panel background (with `@panelled`), any `EuiPanel` color. |
| `@hasBorder` | `boolean` | EuiPanel's (`true`) | Panel border (with `@panelled`). |
| `@hasShadow` | `boolean` | EuiPanel's (`false`) | Panel shadow (with `@panelled`). |
| `@style` | `Record<string, string>` |  | Inline styles, merged with the max width. |

| Block | Description |
| --- | --- |
| default block | Usually an `EuiPageHeader` and `EuiPageContent`. |

### EuiPageContent

A panel holding the page's main content, inside EuiPageBody.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@role` | `string \| null` | `'main'`; pass `null` for none | `role` of the content. |
| `@verticalPosition` | `'center' \| 'bottom'` |  | Vertically centers (`'center'`) or bottom-aligns the content panel. |
| `@horizontalPosition` | `'center'` |  | Horizontally centers the content panel (e.g. an empty prompt). |
| `@hasShadow` | `boolean` | `false` | Adds a shadow. |
| `@hasBorder` | `boolean` | `true` | Adds a border. |
| `@paddingSize` |  | `'l'` | Padding, any `EuiPanel` padding size. |
| `@borderRadius` |  |  | Border radius: `'none'` or `'m'`. |
| `@color` |  |  | Background, any `EuiPanel` color. |
| `@grow` | `boolean` |  | Fills the remaining height. |

| Block | Description |
| --- | --- |
| default block | `EuiPageContentHeader` and `EuiPageContentBody`, or any content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiPageContentBody

The content of an EuiPageContent. Styled as upstream's
`EuiPageSection` content (`euiPageSection__content`).

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@restrictWidth` | `boolean \| number \| string` | `false` (no limit) | Max width of the content, centered: `true` for EUI's default (1200px), a number in px, or any CSS width. |
| `@paddingSize` | `EuiPagePaddingSize` | `'none'` | Padding on every side: `'none'`, `'xs'`, `'s'`, `'m'`, `'l'` or `'xl'`. |
| `@style` | `{ [key: string]: string; }` |  | Inline styles, merged with the max width. |

| Block | Description |
| --- | --- |
| default block | The content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
