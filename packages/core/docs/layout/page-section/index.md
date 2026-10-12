---
title: Page sections
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Page sections"/>
<EuiSpacer @size="l" />

<EuiText>

Building blocks for custom page layouts, ported from EUI's page components.

- **`EuiPageSection`** is a full-width band of a page: a header area, a
  colored call to action or the main content. The inline padding sits on
  the section and the block padding on an inner content `<div>`, which
  `@restrictWidth` limits and centers. Use `@component="main"` for the main
  landmark and `@grow` to fill a flex column.
- **`EuiPageSidebar`** is the side column of a row `EuiPage`, e.g. with an
  `EuiSideNav`. It keeps a `@minWidth` (248px), can be `@sticky`, and takes
  the full width on the `@responsive` breakpoints (`xs` and `s`).

```hbs
<EuiPage @paddingSize="none">
  <EuiPageSidebar @paddingSize="m" @sticky={{true}}>
    <EuiSideNav @items={{this.navItems}} />
  </EuiPageSidebar>
  <EuiPageBody>
    <EuiPageSection @bottomBorder={{true}} @restrictWidth={{true}}>
      <EuiTitle><h1>Page title</h1></EuiTitle>
    </EuiPageSection>
    <EuiPageSection @component="main" @grow={{true}} @color="plain">
      Content
    </EuiPageSection>
  </EuiPageBody>
</EuiPage>
```

`EuiPageSideBar` (the older Ember name) renders the same styles as
`EuiPageSidebar` with the `euiPageSideBar` class.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiPageSection

A full-width band of a page (upstream `EuiPageSection`), e.g. a header
area, a colored call to action or the main content. Its content is
wrapped in an inner `<div>` that `@restrictWidth` limits and centers.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@paddingSize` | `EuiPagePaddingSize` | `'l'` | Padding: `'none'`, `'xs'`, `'s'`, `'m'`, `'l'` or `'xl'`. The inline padding is on the section, the block padding on the content. |
| `@color` | `EuiPageSectionColor` | `'transparent'` | Background color: `'transparent'`, `'plain'`, `'subdued'`, `'highlighted'`, `'accent'`, `'accentSecondary'`, `'primary'`, `'success'`, `'warning'`, `'danger'`, `'neutral'` or `'risk'`. |
| `@bottomBorder` | `boolean \| 'extended'` |  | Adds a bottom border under the content; `'extended'` puts it on the section so it spans the inline padding too. |
| `@restrictWidth` | `EuiPageRestrictWidth` | `false` | Max width of the content, centered: `true` for EUI's default (1200px), a number in px, or any CSS width. |
| `@grow` | `boolean` | `false` | Grows to fill the height of a flex column parent. |
| `@alignment` | `EuiPageSectionAlignment` | `'top'` | Alignment of the content: `'top'`, `'center'` (both axes) or `'horizontalCenter'`. |
| `@contentProps` | `EuiPageSectionContentProps` |  | Class, styles, `@css` and labels of the inner content `<div>`. |
| `@component` | `string` | `'section'` | The element to render, e.g. `'main'` or `'div'`. |
| `@css` | `EuiCss` |  | Styles composed last into the section's class (upstream's `css`). |

| Block | Description |
| --- | --- |
| default block | The section content. |

### EuiPageSidebar

The side column of an `EuiPage` (upstream `EuiPageSidebar`), e.g. with an
`EuiSideNav`. Place it before an `EuiPageBody` in a row `EuiPage`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@sticky` | `boolean \| { offset?: number }` |  | Keeps the sidebar in view (and scrollable) while the page scrolls, except on `@responsive` breakpoints. `true` offsets it by the `--euiFixedHeadersOffset` CSS variable (fixed headers); pass `{ offset: 48 }` for a pixel offset. |
| `@paddingSize` | `EuiPagePaddingSize` | `'none'` | Padding: `'none'`, `'xs'`, `'s'`, `'m'`, `'l'` or `'xl'`. |
| `@minWidth` | `number \| string` | `248` | Minimum width, in px or any CSS width; take `@paddingSize` into account. |
| `@responsive` | `EuiPageBreakpoint[] \| false` | `['xs', 's']` | Theme breakpoints where the sidebar takes the full width and is never sticky (an `EuiPage` stacks it above the body there). `false` keeps the desktop layout everywhere. |
| `@hasEmbellish` | `boolean` |  | Adds a subtle diagonal embellishment to the top start corner. |
| `@css` | `EuiCss` |  | Styles composed last into the sidebar's class (upstream's `css`). |

| Block | Description |
| --- | --- |
| default block | The sidebar content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
