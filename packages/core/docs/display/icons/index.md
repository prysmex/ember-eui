---
title: Icons
manualDemoInsertion: true
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Icons"/>
<EuiSpacer @size="l" />

<EuiText>

`<EuiIcon>` renders one of EUI's ~470 named icons, an svg component of your
own, or an image URL. Components with an `@iconType` argument (`EuiButton`,
`EuiBadge`, `EuiCallOut`, `EuiListGroupItem`, …) render an `EuiIcon` for you
and accept the same values.

```hbs
<EuiIcon @type="bell" />
<EuiIcon @type="logoElastic" @size="xl" />
<EuiIcon @type="alert" @color="danger" @title="Error" />
<EuiButton @iconType="plusInCircle">Add</EuiButton>
```

## What `@type` accepts

| `@type`                         | Renders                                                                  |
| ------------------------------- | ------------------------------------------------------------------------ |
| An EUI icon name, e.g. `"bell"` | That icon as an inline `<svg>`. Browse them all in the gallery below.     |
| A name registered in `euiIcon.icons` | Your own icon, by name (see *Registering icons by name*).           |
| A component                     | The component, with the icon classes and attributes (see *Custom SVGs*). |
| Any other string                | An `<img>` with that string as `src`, for image URLs.                    |

## Setup

Nothing to configure: EUI's icons ship with `@ember-eui/core`. Each icon is
its own small chunk that is loaded the first time it renders, so an app only
downloads the icons it uses. Until an icon arrives an empty icon of the same
size keeps its place (see *Lazy loading*).

For your own svg files, add [`@svg-jar/plugin`](https://github.com/svg-jar/plugin)
to your app so `import Rocket from './icons/rocket.svg'` gives a component:

```js
// vite.config.mjs
import svgJar from '@svg-jar/plugin/vite';

export default defineConfig({
  plugins: [
    // ...ember(), babel(), etc.
    svgJar({ target: 'ember' }),
  ],
});
```

The full list of arguments is in the *API reference* at the end of the page.

## All icons

Search by name or filter by category; click an icon to copy its tag.

</EuiText>

<EuiSpacer @size="m" />

<IconGallery />

<EuiSpacer @size="xl" />

<EuiText>

## Examples

</EuiText>

[[demos-all]]

<EuiSpacer @size="l" />
<EuiHorizontalRule/>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiIcon

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@type` (required) | `IconType` |  | `Enum` is any of the named icons listed in the docs, `string` is usually a URL to an SVG file, and `elementType` is any Ember Icon SVG component |
| `@color` | `IconColor` |  | One of EUI's color palette or a valid CSS color value https://developer.mozilla.org/en-US/docs/Web/CSS/color_value. Note that coloring only works if your SVG is removed of fill attributes. |
| `@size` | `IconSize` |  | Note that every size other than `original` assumes the provided SVG sits on a square viewbox. |
| `@title` | `string` |  | Descriptive title for naming the icon based on its use |
| `@titleId` | `string` |  | A unique identifier for the title element |
| `@tabIndex` | `unknown` |  |  |
| `@aria-labelledby` | `string` |  | Its value should be one or more element IDs |
| `@onIconLoad` | `() => void` |  | Callback when the icon has been loaded & rendered |
| `@iconClasses` | `string` |  | Classes to pass to the icon |

Deprecated: `@useSvg` (No longer has any effect. EUI icons are always inline svgs, icons registered through the `euiIcon.icons` config are rendered as components and any other string is treated as an image URL.); `@useComponent` (Not needed anymore: a component passed as `@type` is always rendered as a component.).

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<img>`.

</EuiText>
<!-- api:end -->
