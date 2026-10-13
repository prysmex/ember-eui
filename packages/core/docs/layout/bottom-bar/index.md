---
title: Bottom bar
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Bottom bar"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiBottomBar` pins actions to the bottom of the window, e.g. "Save" and
"Discard" for a form with unsaved changes. By default it is fixed to the
bottom (rendered in a portal) and pads the page so it doesn't cover the
content. `EuiPageTemplate` offers a quick way to apply a bottom bar to your
page layouts.

```hbs
{{#if this.hasChanges}}
  <EuiBottomBar>
    <EuiFlexGroup @justifyContent="flexEnd" @gutterSize="s">
      <EuiFlexItem @grow={{false}}>
        <EuiButtonEmpty @color="text" {{on "click" this.discard}}>Discard</EuiButtonEmpty>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiButton @color="success" @fill={{true}} {{on "click" this.save}}>Save</EuiButton>
      </EuiFlexItem>
    </EuiFlexGroup>
  </EuiBottomBar>
{{/if}}
```

The bar is dark: use `@color="text"` for buttons on it. `@position`
switches to `sticky` (bottom of its scrolling container) or `static`, and
`@left` / `@right` leave room for a side navigation.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiBottomBar

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@affordForDisplacement` | `boolean` | `true` | With `@position="fixed"` (in a portal), pads the bottom of `<body>` by the bar's height so it does not cover the end of the page, and sets the `--euiBottomBarOffset` CSS variable on `<html>`. |
| `@bodyClassName` | `string` |  | Class added to `<body>` while the bar is rendered. |
| `@position` | `'fixed' \| 'static' \| 'sticky'` | `'fixed'` | `'fixed'` fixes the bar to the bottom of the window (in a portal). `'sticky'` keeps it at the bottom of its scrolling container, `'static'` renders it in place. |
| `@usePortal` | `boolean` | `true` | With `@position="fixed"`, renders the bar in a portal at the end of `<body>`. `false` renders a fixed bar in place (and skips the body displacement). Other positions never use a portal. |
| `@paddingSize` | `'none' \| 's' \| 'm' \| 'l'` | `'m'` | Padding inside the bar: `'none'`, `'s'`, `'m'` or `'l'`. |
| `@landmarkHeading` | `string` | "Page level controls" | Accessible name of the bar's region landmark (announced to screen readers). With a portal, screen readers are also told the bar appeared at the end of the page. |
| `@top` | `number \| string` | none, so a sticky bar sticks to the bottom | Distance from the top, in px or any CSS length (`'sticky'` / `'static'`). |
| `@right` | `number \| string` | `0` | Distance from the right edge, in px or any CSS length. |
| `@left` | `number \| string` | `0` | Distance from the left edge, in px or any CSS length, e.g. the width of a side nav. |
| `@bottom` | `number \| string` | `0` | Distance from the bottom, in px or any CSS length. |

| Block | Description |
| --- | --- |
| default block | The bar's content, usually buttons in an EuiFlexGroup. |

</EuiText>
<!-- api:end -->
