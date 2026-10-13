---
title: Overlay mask
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Overlay mask"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiOverlayMask` covers the page with a dark overlay, rendered in a
portal, and stops the page from scrolling. Modals and flyouts use it;
use it directly to build your own overlays.

```hbs
{{#if this.showOverlay}}
  <EuiOverlayMask @onClick={{this.close}}>
    <EuiPanel>…</EuiPanel>
  </EuiOverlayMask>
{{/if}}
```

`@onClick` is called for clicks on the mask itself (not its content).

### Masks with header

Managing z-index levels of multiple portal-positioned components and their different contexts is complicated from within the library. **EuiOverlayMask** gives you control over whether it should appear below or above an `EuiHeader` by providing the `@headerZindexLocation` argument. By default this is set to `"above"` for common cases like with `EuiModal` where the header should be obscured. However, a component like `EuiFlyout` which utilizes the overlay mask but should keep the header visible should use `"below"`.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiOverlayMask

A dark overlay covering the page, rendered at the end of `<body>`, e.g.
behind a modal. Prevents scrolling the page while shown.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@onClick` | `(e: MouseEvent) => void` |  | Called when the mask itself (not its content) is clicked. |
| `@headerZindexLocation` | `'above' \| 'below'` | `'above'` | Whether the mask covers the page header (`'above'`, z-index `levels.mask`) or leaves it visible (`'below'`, z-index `levels.maskBelowHeader`, starting below `--euiFixedHeadersOffset`). |
| `@hasAnimation` | `boolean` | `true` | Fades the mask in. |
| `@maskRef` | `(element: HTMLDivElement) => void` |  | Called with the mask element once it is rendered. |

| Block | Description |
| --- | --- |
| default block | Content shown above the mask. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
