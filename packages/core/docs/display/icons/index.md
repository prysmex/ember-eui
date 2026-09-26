---
title: Icons
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

### What `@type` accepts

| `@type`                         | Renders                                                                  |
| ------------------------------- | ------------------------------------------------------------------------ |
| An EUI icon name, e.g. `"bell"` | That icon as an inline `<svg>`. Browse them all in the gallery below.     |
| A name registered in `euiIcon.icons` | Your own icon, by name (see *Registering icons by name*).           |
| A component                     | The component, with the icon classes and attributes (see *Custom SVGs*). |
| Any other string                | An `<img>` with that string as `src`, for image URLs.                    |

### Setup

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

### Arguments

| Argument         | Type                                   | Default | Description |
| ---------------- | -------------------------------------- | ------- | ----------- |
| `@type`          | icon name, component or URL            | —       | What to render, see above. Required. |
| `@size`          | `'s'` `'m'` `'l'` `'xl'` `'xxl'` `'original'` | `'m'` | 12, 16, 24, 32 or 40px square; `original` keeps the svg's own size. |
| `@color`         | EUI color name or any CSS color        | inherits text color | `primary`, `success`, `accent`, `warning`, `danger`, `text`, `subdued`, `ghost`, `default`, `inherit`, or e.g. `'#DA8B45'`. |
| `@title`         | `string`                               | —       | Accessible name. Without `@title`, `aria-label` or `aria-labelledby` the icon is decorative (`aria-hidden="true"`). |
| `@titleId`       | `string`                               | generated | Id of the title element, when you need to reference it. |
| `@aria-label`    | `string`                               | —       | Accessible name, instead of `@title`. |
| `@aria-labelledby` | `string`                             | —       | Id(s) of the element(s) labelling the icon. |
| `@tabIndex`      | `number`                               | —       | Makes the icon focusable, e.g. inside a tooltip anchor. |
| `@iconClasses`   | `string`                               | —       | Extra classes for the `<svg>`. Plain `class` works as well. |

Other attributes (`class`, `data-test-*`, `style`, …) are passed to the
`<svg>` (or `<img>`).

### All icons

Search by name or filter by category; click an icon to copy its tag.

</EuiText>

<EuiSpacer @size="m" />

<IconGallery />

<EuiSpacer @size="l" />
<EuiHorizontalRule/>
