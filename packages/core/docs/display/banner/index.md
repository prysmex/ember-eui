---
title: Banner
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Banner"/>
<EuiSpacer @size="l" />

<EuiText>

Use a banner for a prominent announcement inside a page, such as a new
feature or a promotion. It combines an illustration (the `<:media>` block),
a `@title`, optional `@text` and content, up to two actions and an optional
dismiss button. The layout follows the banner's own width through container
queries: narrow banners stack, wide ones put the actions at the end.

```hbs
<EuiBanner
  @title="Try the new dashboards"
  @text="Build visualizations faster with the new editor."
  @actionProps={{hash
    primary=(hash children="Try it" onClick=this.tryIt)
    secondary=(hash children="Learn more" href="/docs")
  }}
  @onDismiss={{this.dismiss}}
>
  <:media><img src="/dashboards.svg" alt="" /></:media>
</EuiBanner>
```

For status messages (success, warning, errors) use an `EuiCallOut` instead.
`@announceOnMount` reads the banner out to screen readers when it appears;
use it only when the banner is feedback to a user action.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiBanner

A prominent announcement inside a page, e.g. a new feature or a
promotion, with an illustration, a title, text, optional actions and an
optional dismiss button (upstream `EuiBanner`). The layout adapts to the
banner's own width (container queries): narrow banners stack, wide ones
put the actions at the end.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@title` (required) | `string` |  | Heading shown at the top (required). |
| `@headingElement` | `EuiBannerHeadingElement` | `'h2'` | Element of the title: `'h2'`–`'h6'`. |
| `@text` | `string` |  | Supporting text below the title. |
| `@size` | `EuiBannerSize` | `'m'` | `'s'` (compact, title and text on one line) or `'m'`. |
| `@color` | `EuiBannerColor` | `'highlighted'` | Background: `'highlighted'` or `'plain'`. |
| `@actionProps` |  |  | Action buttons: `primary` renders an `EuiButton`, `secondary` an `EuiButtonEmpty` (`{ children, onClick, href, iconType, … }`). |
| `@onDismiss` | `(event: MouseEvent) => void` |  | Renders a dismiss (cross) button in the top end corner; called when it is clicked. |
| `@dismissButtonProps` | `EuiBannerDismissButtonProps` |  | Label, size and `css` of the dismiss button. |
| `@announceOnMount` | `boolean` | `false` | Announces the title, text and content to screen readers when the banner is inserted. Use it only when the banner is feedback to a user action, not on page load. |
| `@css` | `EuiCss` |  | Styles composed last into the banner's class (upstream's `css`). |

| Block | Description |
| --- | --- |
| `<:media>` | The illustration (upstream's required `media`), shown in a square slot; an `<img>` or `<svg>` fills it. |
| default block | Extra content below the text. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
