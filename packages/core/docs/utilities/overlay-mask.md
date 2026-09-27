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

`@onClick` is called for clicks on the mask itself (not its content);
`@headerZindexLocation="below"` keeps the page header above the mask.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiOverlayMask

A dark overlay covering the page, rendered in a portal, e.g. behind a
modal. Prevents scrolling the page while shown.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@onClick` | `(e: Event) => void` |  | Called when the mask itself (not its content) is clicked. |
| `@headerZindexLocation` | `'above' \| 'below'` | `'above'` | Whether the mask covers the page header (`'above'`) or leaves it visible (`'below'`). |

| Block | Description |
| --- | --- |
| default block | Content shown above the mask. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
