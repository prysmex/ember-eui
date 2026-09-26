---
title: Page template
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Page template"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiPageTemplate` builds a whole page layout in one component: an
optional side bar, a page header, the content, and an optional bottom
bar. Pick the arrangement with `@template`:

| `@template` | Layout |
| --- | --- |
| `default` | Header and content in a panel next to the side bar. |
| `centeredBody` | The content panel centered in the page, for a single focused task. |
| `centeredContent` | Content centered inside the body, e.g. an empty prompt. |
| `empty` | No panels, for fully custom content. |

```hbs
<EuiPageTemplate
  @pageHeader={{hash pageTitle="Users" iconType="users"}}
  @restrictWidth={{true}}
>
  <:pageSideBar><EuiSideNav @items={{this.nav}} /></:pageSideBar>
  <:pageHeaderRightSideItems as |Item|>
    <Item><EuiButton @fill={{true}}>Invite user</EuiButton></Item>
  </:pageHeaderRightSideItems>
  <:default>…the page's content…</:default>
</EuiPageTemplate>
```

`@pageHeader` takes `EuiPageHeader`'s options; the `<:pageHeader…>`
blocks fill its parts. The same layouts can be built by hand from
`EuiPage`, `EuiPageSideBar`, `EuiPageBody`, `EuiPageContent` and
`EuiPageContentBody`, which the examples also show.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiPageTemplate

A whole page layout in one component: side bar, header, content and
bottom bar, arranged by `@template`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@template` |  | `'default'` | Layout: `'default'` (header and content), `'centeredBody'` (content panel centered in the page), `'centeredContent'` (content centered in the body, e.g. an empty prompt) or `'empty'` (no panels). |
| `@pageBodyProps` (required) |  |  | Props for the `EuiPageBody`: `{ className }`. |
| `@pageContentProps` (required) |  |  | Props for the `EuiPageContent`: `{ className, hasBorder, hasShadow, color, borderRadius, grow, role }`. |
| `@pageContentBodyProps` (required) |  |  | Props for the `EuiPageContentBody`: `{ className }`. |
| `@pageHeader` (required) |  |  | The page header, as EuiPageHeader args: `{ pageTitle, iconType, description, tabs, responsive, bottomBorder }`. Use the `<:pageHeader…>` blocks for its title, description and actions. |
| `@pageSideBarProps` (required) |  |  | Props for the `EuiPageSideBar`: `{ className }`. |
| `@fullHeight` | `boolean` | `false` | Stretches the page to the window's height and scrolls the content instead of the page (templates `'default'` and `'empty'`, on medium screens and up). |
| `@minHeight` | `number` | `460` | Minimum height of the page, in px or any CSS height. |
| `@restrictWidth` | `boolean \| number \| string` | `true` | Max width of the header and content: `true` for EUI's default, a number in px or any CSS width. |
| `@grow` | `boolean` | `true` | Fills the window's height. |
| `@paddingSize` |  | `'l'` | Padding of the page's sections: `'none'`, `'s'`, `'m'` or `'l'`. |

Deprecated: `@bottomBar` (Has no effect, use the `<:bottomBar>` block.); `@bottomBarProps` (Has no effect.); `@hasPageHeader` (Has no effect.); `@hasPageContent` (Has no effect.); `@hasPageContentBody` (Has no effect.).

| Block | Description |
| --- | --- |
| default block | The page's content. |
| `<:pageSideBar>` | A side bar, e.g. an `EuiSideNav`. |
| `<:pageHeaderPageTitle>` | The header's title, instead of `pageHeader.pageTitle`. |
| `<:pageHeaderDefault>` | Extra header content. |
| `<:pageHeaderDescription>` | The header's description. |
| `<:pageHeaderRightSideItems>` | Header actions; yields an item to wrap each in, see EuiPageHeader. |
| `<:bottomBar>` | Content of a bottom bar (EuiBottomBar), e.g. save/cancel buttons. |

### EuiPage

The outermost layout of a page: holds an optional `EuiPageSideBar` and an `EuiPageBody`. See also EuiPageTemplate.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@restrictWidth` | `boolean \| number \| string` | `false` (no limit) | Max width of the content: `true` for EUI's default (1000px), a number in px, or any CSS width. |
| `@paddingSize` | `'none' \| 's' \| 'm' \| 'l'` | `'m'` | Padding around the page: `'none'`, `'s'`, `'m'` or `'l'`. |
| `@grow` | `boolean` | `true` | Fills the window's height. |
| `@direction` | `'row' \| 'column'` | `'row'` | `'row'` puts an `EuiPageSideBar` beside the body, `'column'` stacks them. |
| `@style` | `Record<string, string>` |  | Inline styles, merged with the max width. |

| Block | Description |
| --- | --- |
| default block | `EuiPageSideBar` and `EuiPageBody`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiPageSideBar

The side column of an EuiPage, e.g. with an `EuiSideNav`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@sticky` | `boolean` |  | Keeps the side bar in view while the page scrolls. |
| `@paddingSize` |  | `'l'` | Padding: `'none'`, `'s'`, `'m'` or `'l'`. |

| Block | Description |
| --- | --- |
| default block | The side bar content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiPageBody

The main column of an EuiPage: header, content and so on.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@restrictWidth` | `boolean \| number \| string` | `false` (no limit) | Max width of the content: `true` for EUI's default (1000px), a number in px, or any CSS width. |
| `@tagName` | `string` | `'div'` | Tag of the body (without `@panelled`). |
| `@borderRadius` |  | `'none'` | Border radius of the panel: `'none'` or `'m'`. |
| `@paddingSize` | `'none' \| 's' \| 'm' \| 'l'` | `'l'` when `@panelled`, `'none'` otherwise | Padding: `'none'`, `'s'`, `'m'` or `'l'`. |
| `@panelled` | `boolean` |  | Renders the body as an `EuiPanel` (white background with padding). |
| `@color` | `'subdued' \| 'transparent'` |  | Panel background: `'subdued'` or `'transparent'`. |
| `@hasBorder` | `boolean` |  | Adds a border to the panel. |
| `@hasShadow` | `boolean` |  | Adds a shadow to the panel. |
| `@style` | `Record<string, string>` |  | Inline styles, merged with the max width. |

| Block | Description |
| --- | --- |
| default block | Usually an `EuiPageHeader` and `EuiPageContent`. |

### EuiPageContent

A panel holding the page's main content, inside EuiPageBody.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@role` | `string` | `'main'`; pass `null` for none | `role` of the content. |
| `@verticalPosition` | `'center' \| 'bottom'` |  | Vertically centers (`'center'`) or bottom-aligns the content panel. |
| `@horizontalPosition` | `'center'` |  | Horizontally centers the content panel (e.g. an empty prompt). |
| `@hasShadow` | `boolean` |  | Adds a shadow. |
| `@hasBorder` | `boolean` |  | Adds a border. |
| `@paddingSize` |  | `'l'` | Padding, any `EuiPanel` padding size. |
| `@borderRadius` |  |  | Border radius: `'none'` or `'m'`. |
| `@color` |  |  | Background, any `EuiPanel` color. |
| `@grow` | `boolean` |  | Fills the remaining height. |

| Block | Description |
| --- | --- |
| default block | `EuiPageContentHeader` and `EuiPageContentBody`, or any content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiPageContentBody

The content of an EuiPageContent.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@restrictWidth` | `boolean \| number \| string` | `false` (no limit) | Max width of the content: `true` for EUI's default (1000px), a number in px, or any CSS width. |
| `@paddingSize` |  |  | Padding: `'none'`, `'s'`, `'m'` or `'l'`. |
| `@style` | `{ [key: string]: string; }` |  | Inline styles, merged with the max width. |

| Block | Description |
| --- | --- |
| default block | The content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
