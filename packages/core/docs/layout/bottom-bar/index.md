---
title: Bottom bar
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Bottom bar"/>

<EuiSpacer/>

<EuiCallOut>
  <:body>
    <EuiText @size='s'>
      <strong>EuiBottomBar</strong>
      offers a quick way to apply a bottom bar to your page layouts.
    </EuiText>
  </:body>
</EuiCallOut>

<EuiHorizontalRule/>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiBottomBar

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@affordForDisplacement` | `boolean` | `true` | With `@position="fixed"`, pads the bottom of `<body>` by the bar's height so it does not cover the end of the page. |
| `@bodyClassName` | `string` |  | Class added to `<body>` while the bar is rendered. |
| `@position` | `'fixed' \| 'static' \| 'sticky'` | `'fixed'` | `'fixed'` renders the bar in a portal, fixed to the bottom of the window. `'sticky'` keeps it at the bottom of its scrolling container, `'static'` renders it in place. |
| `@paddingSize` | `'none' \| 's' \| 'm' \| 'l'` | `'m'` | Padding inside the bar: `'none'`, `'s'`, `'m'` or `'l'`. |
| `@landmarkHeading` | `string` | "Page level controls" | Accessible name of the bar's region landmark (announced to screen readers). Currently only used when `@position` is `'sticky'` or `'static'`. |
| `@top` | `number` | `0` | Distance from the top in px (only for `'sticky'` / `'static'`). |
| `@right` | `number` | `0` | Distance from the right edge in px. |
| `@left` | `number` | `0` | Distance from the left edge in px, e.g. the width of a side nav. |
| `@bottom` | `number` | `0` | Distance from the bottom in px. |

Deprecated: `@usePortal` (Has no effect: the bar uses a portal when `@position` is `'fixed'`.).

| Block | Description |
| --- | --- |
| default block | The bar's content, usually buttons in an EuiFlexGroup. |

</EuiText>
<!-- api:end -->
