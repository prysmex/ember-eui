---
order: 6
---

# Without ownFocus

<EuiText>
  <p>
    Like modals, you will usually want to obscure the page content beneath with
    <EuiCode>@ownFocus</EuiCode> which wraps the flyout with an overlay mask.
    However, there are use-cases where flyouts present more information or
    controls, but need to maintain the interactions of the page content. By
    setting <EuiCode>@ownFocus=\{{false}}</EuiCode>, the underlying page content
    will be visible and clickable.
  </p>
</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiButton, EuiFlyout, EuiFlyoutBody, EuiFlyoutHeader, EuiText, EuiTitle } from '@ember-eui/core/components';

export default class FlyoutWithoutOwnFocusComponent extends Component {
  @tracked isFlyoutVisible = false;

  @action
  toggleFlyout() {
    this.isFlyoutVisible = !this.isFlyoutVisible;
  }

  @action
  closeFlyout() {
    this.isFlyoutVisible = false;
  }

  <template>
  <EuiButton {{on "click" this.toggleFlyout}}>
    Toggle flyout
  </EuiButton>

  {{#if this.isFlyoutVisible}}
    <EuiFlyout
      @ownFocus={{false}}
      @onClose={{this.closeFlyout}}
      aria-labelledby="withoutFocusFlyoutTitle"
    >
      <EuiFlyoutHeader @hasBorder={{true}}>
        <EuiTitle @size="s" id="withoutFocusFlyoutTitle">A flyout without ownFocus</EuiTitle>
      </EuiFlyoutHeader>
      <EuiFlyoutBody>
        <EuiText>
          <p>
            The page contents is still interactive though screen reader users
            will find themselves still within the bounds of the flyout.
          </p>
        </EuiText>
      </EuiFlyoutBody>
    </EuiFlyout>
  {{/if}}
  </template>
}
```
