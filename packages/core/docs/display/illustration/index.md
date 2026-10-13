---
title: Illustration
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Illustration"/>
<EuiSpacer @size="l" />

<EuiText>

**EuiIllustration** renders theme-adaptive SVGs. Each illustration ships a `light` and a `dark` variant and the component inlines the one that matches the current theme.

An asset is an object `{ id, title, light, dark }` where `light` and `dark` are SVG markup, the shape exported by [`@elastic/eui-illustrations`](https://github.com/elastic/eui/tree/main/packages/illustrations), a standalone package that is independently versioned and published from `@elastic/eui`, so the catalog can grow without an EUI release.

## Using `@elastic/eui-illustrations` (optional)

Ember EUI does **not** depend on or bundle the illustrations package, exactly like upstream's `@elastic/eui`. Install it in your own app when you want Elastic's catalog:

```sh
pnpm add @elastic/eui-illustrations
```

Every export is an asset in the shape above, so import one and pass it as `@type`:

```js
import { EuiIllustration } from '@ember-eui/core/components';
import { dashboard } from '@elastic/eui-illustrations';

<template>
  <div style="max-inline-size: 360px">
    <EuiIllustration @type={{dashboard}} />
  </div>
</template>
```

To list the whole catalog, the package also exports `illustrations`, an object keyed by export name (upstream's gallery sorts `Object.values` by `title` and filters on `title` and `id`):

```js
import { illustrations } from '@elastic/eui-illustrations';

const items = Object.entries(illustrations)
  .map(([exportName, illustration]) => ({ exportName, ...illustration }))
  .sort((a, b) => a.title.localeCompare(b.title));
```

Any object with `{ id, title, light, dark }` works, so you can also pass your own SVG assets.

**License:** the illustrations are copyright Elasticsearch B.V. and licensed under the Elastic License 2.0 or the Server Side Public License, v 1, not under Ember EUI's license. See `packages/core/NOTICE.md` for how these terms apply to this repository.

This site installs the package to show the searchable gallery below ("All illustrations").

The markup is inserted as-is: only pass trusted, package-authored SVGs, never user-supplied markup.

</EuiText>

<EuiSpacer />

<EuiCallOut @title="Accessibility recommendation" @color="success" @iconType="accessibility">
  <p>The accessible label defaults to the illustration's <code>title</code>. Provide a more specific <code>@alt</code> when the illustration conveys meaning or pass <code>@alt=""</code> to mark it as purely decorative (it will be hidden from assistive technology). It fills its container's width unless <code>@fullWidth=\{{false}}</code>.</p>
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
