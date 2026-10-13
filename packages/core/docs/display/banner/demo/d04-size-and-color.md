---
order: 4
---

# Size and color

<EuiText>

Use the `@size` argument to control the visual density. The `'s'` variant uses a more compact layout and expects a smaller media element.

The `@color` argument controls the background of the banner. Choose `@color` depending on the surrounding content and the level of emphasis you want the banner to have.

</EuiText>

```hbs template
<EuiBanner
  @title="Default size, highlighted"
  @text="The default medium banner on a highlighted background. Use when the announcement should stand out."
  @actionProps={{hash primary=(hash children="Get started" onClick=this.noop)}}
>
  <:media><img src="https://placehold.co/80x80" alt="" aria-hidden="true" /></:media>
</EuiBanner>
<EuiSpacer @size="m" />
<EuiBanner
  @color="plain"
  @title="Default size, plain"
  @text="A medium banner on a plain background. Use when the banner sits on an already-tinted surface."
  @actionProps={{hash primary=(hash children="Get started" onClick=this.noop)}}
>
  <:media><img src="https://placehold.co/80x80" alt="" aria-hidden="true" /></:media>
</EuiBanner>
<EuiSpacer @size="m" />
<EuiBanner
  @size="s"
  @title="Small size, highlighted"
  @text="A compact banner for persistent but less prominent messages."
  @actionProps={{hash primary=(hash children="Get started" onClick=this.noop)}}
>
  <:media><img src="https://placehold.co/32x32" alt="" aria-hidden="true" /></:media>
</EuiBanner>
<EuiSpacer @size="m" />
<EuiBanner
  @size="s"
  @color="plain"
  @title="Small size, plain"
  @text="A compact banner on a plain background."
  @actionProps={{hash primary=(hash children="Get started" onClick=this.noop)}}
>
  <:media><img src="https://placehold.co/32x32" alt="" aria-hidden="true" /></:media>
</EuiBanner>
```

```js component
import Component from '@glimmer/component';

export default class BannerSizeDemo extends Component {
  noop = () => {};
}
```
