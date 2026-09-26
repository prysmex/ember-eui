---
title: Image
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Image"/>

 <EuiSpacer />
    <EuiText>
    <p>Use <strong>EuiImage</strong> when you need to place a static image into a page with an optional caption.</p>
    </EuiText>

  <EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiImage

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@alt` (required) | `string` |  | Separate from the caption is a title on the alt tag itself. This one is required for accessibility. |
| `@size` | `ImageSize \| number \| string` | `'original'` | `'s'` (100px), `'m'` (200px), `'l'` (360px), `'xl'` (600px), `'fullWidth'`, `'original'`, or a number for a max size in px. |
| `@fullScreenIconColor` | `FullScreenIconColor` |  | Changes the color of the icon that floats above the image when it can be clicked to fullscreen. The default value of `light` is fine unless your image has a white background, in which case you should change it to `dark`. |
| `@url` (required) | `string` |  | URL of the image. |
| `@caption` | `string` |  | Provides the visible caption to the image |
| `@hasShadow` | `boolean` |  | When set to `true` (default) will apply a slight shadow to the image |
| `@allowFullScreen` | `boolean` |  | When set to `true` will make the image clickable to a larger version |
| `@float` | `'left' \| 'right' \| 'none'` |  | Floats the image `'left'` or `'right'` of the text around it. |
| `@margin` | `'none' \| 's' \| 'm' \| 'l' \| 'xl'` |  | Space around the image: `'none'`, `'s'`, `'m'`, `'l'` or `'xl'`. |
| `@ariaLabel` | `string` |  | Accessible label of the full screen button (`@allowFullScreen`). |
| `@src` | `string` |  | Same as `@url`. |

</EuiText>
<!-- api:end -->
