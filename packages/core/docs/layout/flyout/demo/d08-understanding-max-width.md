---
order: 8
---

# Understanding max-width

<EuiText>

A flyout's `@size` sets its width (`s`, `m`, `l`, or any CSS width).
`@maxWidth` caps it: `true` uses EUI's default cap, a number caps it in
pixels. On narrow windows flyouts always shrink to fit.

</EuiText>

```hbs template
<EuiButton {{on "click" (fn this.open 800 600)}}>size 800px, maxWidth 600</EuiButton>
<EuiButton {{on "click" (fn this.open "l" true)}}>size l, default maxWidth</EuiButton>

{{#if this.isOpen}}
  <EuiFlyout
    @size={{this.size}}
    @maxWidth={{this.maxWidth}}
    @onClose={{this.close}}
    @closeButtonAriaLabel="Close"
  >
    <EuiFlyoutHeader @hasBorder={{true}}>
      <EuiTitle @size="m" @tagName="h2">Max width {{this.maxWidth}}</EuiTitle>
    </EuiFlyoutHeader>
    <EuiFlyoutBody>
      <EuiText>
        <p>This flyout asks for a width of {{this.size}} but is capped.</p>
      </EuiText>
    </EuiFlyoutBody>
  </EuiFlyout>
{{/if}}
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class FlyoutMaxWidthDemo extends Component {
  @tracked isOpen = false;
  @tracked size;
  @tracked maxWidth;

  @action
  open(size, maxWidth) {
    this.size = size;
    this.maxWidth = maxWidth;
    this.isOpen = true;
  }

  @action
  close() {
    this.isOpen = false;
  }
}
```
