---
title: Image
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Image"/>

<EuiSpacer />
<EuiText>

Use **EuiImage** when you need to place a static image into a page with an optional caption.

</EuiText>

<EuiSpacer />

<EuiCallOut @title="Writing meaningful image alt text" @color="success" @iconType="accessibility">
  <p>The examples on this page have alt text written to aid screen reader users, as well as several examples of when <em>not</em> to include alt text. When an image is decorative, or if the image is adequately described by surrounding text, it is better to pass an empty <code>""</code> string instead.</p>
  <p>When an image is not already sufficiently described, the alt text passed should help non-visual users understand the purpose of the image within the context of the overall page. See <a href="https://webaim.org/techniques/alttext/" target="_blank" rel="noopener noreferrer">WebAIM</a> for a more detailed guide to writing effective alt text.</p>
</EuiCallOut>

  <EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiImage

An image with an optional caption, shadow and full screen view.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@alt` (required) | `string` |  | Describes the image for screen reader users (required). Pass an empty string when the image is decorative or described by nearby text. |
| `@size` | `EuiImageSize \| number \| string` | `'original'` | `'s'` (100px), `'m'` (200px), `'l'` (360px), `'xl'` (600px), `'fullWidth'`, `'original'`, or a custom maximum size: a number (px) or a CSS length such as `'50%'`. |
| `@fullScreenIconColor` | `'light' \| 'dark'` |  | Color of the icon over a full screen image: `'light'` (default) or `'dark'` (for images with a white background). |
| `@url` | `string` |  | URL of the image. |
| `@caption` | `string` |  | A visible caption, also the figure's accessible name. |
| `@hasShadow` | `boolean` | `false`, as upstream | Adds a slight shadow to the image. |
| `@allowFullScreen` | `boolean` |  | Makes the image clickable to show a larger version over the page. |
| `@float` | `'left' \| 'right' \| 'none'` |  | Floats the image `'left'` or `'right'` of the text around it (from the `m` breakpoint). |
| `@margin` | `'none' \| 's' \| 'm' \| 'l' \| 'xl'` |  | Space around the image: `'none'`, `'s'`, `'m'`, `'l'` or `'xl'`. |
| `@ariaLabel` | `string` |  | Accessible label of the full screen button (`@allowFullScreen`), replacing the instructions. |
| `@onFullScreen` | `(isFullScreen: boolean) => void` |  | Called with `true` / `false` when the full screen view opens / closes. |
| `@src` | `string` |  | Same as `@url`; wins when both are given. |

</EuiText>
<!-- api:end -->
