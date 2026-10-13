---
title: Illustration
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Illustration"/>
<EuiSpacer @size="l" />

<EuiText>

**EuiIllustration** renders theme-adaptive SVGs. Each illustration ships a `light` and a `dark` variant and the component inlines the one that matches the current theme.

An asset is an object `{ id, title, light, dark }` where `light` and `dark` are SVG markup, the shape exported by [`@elastic/eui-illustrations`](https://github.com/elastic/eui/tree/main/packages/illustrations), a standalone package that is independently versioned and published from `@elastic/eui`, so the catalog can grow without an EUI release.

```js
import { dashboard } from '@elastic/eui-illustrations';
```

```hbs
<EuiIllustration @type={{dashboard}} />
```

The markup is inserted as-is: only pass trusted, package-authored SVGs, never user-supplied markup.

</EuiText>

<EuiSpacer />

<EuiCallOut @title="Accessibility recommendation" @color="success" @iconType="accessibility">
  <p>The accessible label defaults to the illustration's <code>title</code>. Provide a more specific <code>@alt</code> when the illustration conveys meaning or pass <code>@alt=""</code> to mark it as purely decorative (it will be hidden from assistive technology). It fills its container's width unless <code>@fullWidth=&#123;&#123;false&#125;&#125;</code>.</p>
</EuiCallOut>

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
