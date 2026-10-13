---
order: 2
---

# With actions

<EuiText>

Use `actionProps.primary` and `actionProps.secondary` to render call-to-action buttons. You can use the `fill` argument on the primary action to opt in to a filled style for extra emphasis.

</EuiText>

```hbs template
<EuiBanner
  @title="Upgrade your plan"
  @text="Unlock advanced capabilities and get priority support with a higher-tier subscription."
  @actionProps={{hash
    primary=(hash children="Upgrade now" onClick=this.noop)
    secondary=(hash children="Learn more" onClick=this.noop)
  }}
>
  <:media>
    <img src="https://placehold.co/80x80" alt="" aria-hidden="true" />
  </:media>
</EuiBanner>
```

```js component
import Component from '@glimmer/component';

export default class BannerActionsDemo extends Component {
  noop = () => {};
}
```
