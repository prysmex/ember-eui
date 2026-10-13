---
order: 3
---

# Dismissible

<EuiText>

Pass an `@onDismiss` action to render a dismiss button in the top-right corner to allow users to close the banner.

</EuiText>

```hbs template
{{#if this.isVisible}}
  <EuiBanner
    @title="You have unread notifications"
    @text="Check your inbox for important updates from your team."
    @onDismiss={{this.hide}}
  >
    <:media>
      <img src="https://placehold.co/80x80" alt="" aria-hidden="true" />
    </:media>
  </EuiBanner>
{{else}}
  <EuiButtonEmpty {{on "click" this.show}}>
    The banner has been dismissed. Click to reset.
  </EuiButtonEmpty>
{{/if}}
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class BannerDismissDemo extends Component {
  @tracked isVisible = true;

  @action hide() {
    this.isVisible = false;
  }

  @action show() {
    this.isVisible = true;
  }
}
```
