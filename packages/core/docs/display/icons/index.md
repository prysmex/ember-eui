---
title: Icons
manualDemoInsertion: true
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Icons"/>
<EuiSpacer @size="l" />

<EuiText>

`<EuiIcon>` renders one of the ~570 named icons of EUI 123.1.0, an svg
component of your own, or an image URL. Components with an `@iconType` argument (`EuiButton`,
`EuiBadge`, `EuiCallOut`, `EuiListGroupItem`, …) render an `EuiIcon` for you
and accept the same values.

```hbs
<EuiIcon @type="bell" />
<EuiIcon @type="logoElastic" @size="xl" />
<EuiIcon @type="warning" @color="danger" @title="Error" />
<EuiButton @iconType="plusCircle">Add</EuiButton>
```

Provide a descriptive `@title` based on the icon use, if possible. Without a title the icon is considered purely decorative and defaults to `aria-hidden="true"` (see *Accessibility* below).

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

## Renamed icons

The icons are the current upstream (Borealis) set, under upstream's names.
Names from earlier EUI releases keep working: names upstream renamed render
the renamed icon (e.g. `arrowDown` → `chevronSingleDown`, `popout` →
`external`, `questionInCircle` → `question`, `editorBold` → `textBold`), and
the few without an upstream equivalent keep their previous artwork. Upstream's
own deprecated names (e.g. `search`, `alert`) render what upstream renders.
These names are left out of the gallery; prefer the upstream names in new code.
The full lists are exported next to the icon map:

```js
import {
  legacyIconAliases, // { arrowDown: 'chevronSingleDown', … }
  legacyIconTypes, // legacy names that keep their previous artwork
  deprecatedIconTypes // upstream deprecations: { search: 'magnify', … }
} from '@ember-eui/core/utils/css-mappings/eui-icon';
```

An icon registered in `euiIcon.icons` under the same name as an EUI icon
wins, so app icons keep rendering when EUI adds icons with their names.

## All icons

Glyphs, Elastic logos, apps, machine learning icons and tokens. Glyphs are small, monochromatic icons that should use the default `@size="m"`; logos and app icons are drawn for `xl`. Tokens (`EuiToken`) have their own [page](/docs/display/token).

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
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |
| `@type` (required) | `IconType` |  | `Enum` is any of the named icons listed in the docs, `string` is usually a URL to an SVG file, and `elementType` is any Ember Icon SVG component |
| `@color` | `IconColor` |  | One of EUI's named colors (`'default'`, `'primary'`, `'neutral'`, `'success'`, `'accent'`, `'accentSecondary'`, `'warning'`, `'risk'`, `'danger'`, `'text'`, `'subdued'`, `'ghost'`, `'inherit'`) or a valid CSS color value https://developer.mozilla.org/en-US/docs/Web/CSS/color_value. Without a color, the icon uses the inherited text color. Note that coloring only works if your SVG is removed of fill attributes. |
| `@size` | `IconSize` | `'m'` | `'s'` (12px), `'m'` (16px), `'l'` (24px), `'xl'` (32px), `'xxl'` (40px) or `'original'` (the svg's own width and height). Note that every size other than `original` assumes the provided SVG sits on a square viewbox. |
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
