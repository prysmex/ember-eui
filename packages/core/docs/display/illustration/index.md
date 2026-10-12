---
title: Illustration
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Illustration"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiIllustration` inlines an illustration asset and picks its light or dark
artwork from the nearest theme's color mode. An asset is an object
`{ id, title, light, dark }` where `light` and `dark` are SVG markup, the
shape exported by `@elastic/eui-illustrations`.

```js
import { someIllustration } from '@elastic/eui-illustrations';
```

```hbs
<EuiIllustration @type={{someIllustration}} />
```

The markup is inserted as-is: only pass trusted, package-authored SVGs, never
user-supplied markup.

The illustration is an image labelled with the asset's `title`; pass `@alt`
to change the label, or `@alt=""` when it is decorative (it is then hidden
from screen readers). It fills its container's width unless
`@fullWidth={{false}}`.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiIllustration

An inline SVG illustration that follows the nearest theme's color mode.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@type` (required) | `EuiIllustrationType` |  | The illustration asset (`{ id, title, light, dark }`), typically imported from `@elastic/eui-illustrations`. Its markup is inlined verbatim, so it must be trusted. |
| `@alt` | `string` | the illustration's `title` | Accessible label; pass `''` to mark the illustration as decorative (`aria-hidden`). |
| `@fullWidth` | `boolean` | `true` | When `true`, the SVG stretches to the container's full width; when `false`, it keeps its intrinsic width. |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<span>`.

</EuiText>
<!-- api:end -->
