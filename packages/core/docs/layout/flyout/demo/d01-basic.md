---
order: 1
---

# Component

<EuiCallOut @title="Accessibility requirement" @iconType="accessibility" @color="warning">
  Use <code>aria-labelledby</code> pointing at the flyout's title id to ensure
  the flyout is announced to screen readers.
</EuiCallOut>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiButton, EuiCodeBlock, EuiFlyout, EuiFlyoutBody, EuiFlyoutHeader, EuiText, EuiTitle } from '@ember-eui/core/components';

export default class FlyoutBasicComponent extends Component {
  @tracked isFlyoutVisible = false;

  htmlCode = `<EuiFlyout @onClose={{this.closeFlyout}} aria-labelledby="flyoutTitle">
  <EuiFlyoutHeader @hasBorder={{true}}>
    <EuiTitle @size="m" id="flyoutTitle">...</EuiTitle>
  </EuiFlyoutHeader>
  <EuiFlyoutBody>
    ...
  </EuiFlyoutBody>
</EuiFlyout>
`;

  @action
  showFlyout() {
    this.isFlyoutVisible = true;
  }

  @action
  closeFlyout() {
    this.isFlyoutVisible = false;
  }

  <template>
  <EuiButton {{on "click" this.showFlyout}}>
    Show flyout
  </EuiButton>

  {{#if this.isFlyoutVisible}}
    <EuiFlyout
      @ownFocus={{true}}
      @onClose={{this.closeFlyout}}
      aria-labelledby="simpleFlyoutTitle"
    >
      <EuiFlyoutHeader @hasBorder={{true}}>
        <EuiTitle @size="m" id="simpleFlyoutTitle">A typical flyout</EuiTitle>
      </EuiFlyoutHeader>
      <EuiFlyoutBody>
        <EuiText>
          <p>
            For consistency across the many flyouts, please utilize the
            following code for implementing the flyout with a header.
          </p>
        </EuiText>
        <EuiCodeBlock @language="html" @isCopyable={{false}}>{{this.htmlCode}}</EuiCodeBlock>
      </EuiFlyoutBody>
    </EuiFlyout>
  {{/if}}
  </template>
}
```
