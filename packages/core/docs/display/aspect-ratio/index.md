---
title: Aspect ratio
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Aspect ratio"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiAspectRatio` keeps one child (an `<iframe>`, `<video>`, image or map)
at a fixed ratio while it takes the available width: `@width={{16}}
@height={{9}}` for widescreen video, `1` and `1` for a square.

```hbs
<EuiAspectRatio @width={{16}} @height={{9}}>
  <iframe title="Product demo" src="https://www.youtube.com/embed/…"></iframe>
</EuiAspectRatio>
```

The child is stretched to fill the box, so it should not set its own
size. `@maxWidth` limits how wide it grows.

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
