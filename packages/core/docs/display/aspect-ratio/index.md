---
title: Aspect ratio
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Aspect ratio"/>
<EuiSpacer @size="l" />

<EuiCallOut @color="warning" @title="Embed support" @size="s">
  <p>In some cases, aspect ratio sizing may not be supported by the embed. This component will only work with ones that do, like YouTube.</p>
</EuiCallOut>
<EuiSpacer />

<EuiText>

**EuiAspectRatio** provides a way to responsively resize a single block level child element to a specified ratio. This is useful for things like YouTube iframes or other embeds that initially have a fixed size. If you need something similar for images, take a look at CSS's [object-fit property](https://www.w3schools.com/css/css3_object-fit.asp).

Pass `@width` and `@height` for the ratio, and `@maxWidth` to limit how wide it grows.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiAspectRatio

Keeps its content (an iframe, video, image or map) at a fixed aspect
ratio while it takes the available width.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@width` (required) | `number` |  | Width part of the ratio, e.g. `16` for 16:9. |
| `@height` (required) | `number` |  | Height part of the ratio, e.g. `9` for 16:9. |
| `@maxWidth` | `number \| string` |  | Maximum width, e.g. `500` (px) or `'50%'`. |

| Block | Description |
| --- | --- |
| default block | One element that fills the box, e.g. an `<iframe>`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
