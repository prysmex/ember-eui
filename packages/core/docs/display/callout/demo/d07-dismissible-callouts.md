---
order: 7
---

# Dismissible callouts

<EuiText>

To render a cross icon in the top right hand corner, pass an `@onDismiss` action that handles conditionally rendering your callout.

</EuiText>

```hbs template
<div style="max-inline-size: 500px;">
  <EuiFlexGroup>
    <EuiSwitch
      @label="Show text"
      @checked={{this.showText}}
      @onChange={{this.toggleText}}
      @compressed={{true}}
    />
    <EuiSwitch
      @label="Small size"
      @checked={{this.smallSize}}
      @onChange={{this.toggleSize}}
      @compressed={{true}}
    />
  </EuiFlexGroup>
  <EuiSpacer />
  {{#if this.showCallOut}}
    <EuiCallOut
      @onDismiss={{this.onDismiss}}
      @title="You can dismiss this callout by clicking the Close button in the top right corner"
      @size={{if this.smallSize "s" "m"}}
    >
      {{#if this.showText}}
        <p>
          Here’s more some stuff users need to know. But maybe users don't
          need to know it on every page refresh, so you could remember
          whether or not to display this callout in local storage.
        </p>
      {{/if}}
    </EuiCallOut>
  {{else}}
    <EuiButtonEmpty {{on "click" this.resetDemo}}>
      The callout has been dismissed. Click to reset the demo
    </EuiButtonEmpty>
  {{/if}}
</div>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class CallOutDismissDemo extends Component {
  @tracked showCallOut = true;
  @tracked showText = true;
  @tracked smallSize = false;

  @action onDismiss() {
    this.showCallOut = false;
  }

  @action resetDemo() {
    this.showCallOut = true;
  }

  @action toggleText(event) {
    this.showText = event.target.checked;
  }

  @action toggleSize(event) {
    this.smallSize = event.target.checked;
  }
}
```
