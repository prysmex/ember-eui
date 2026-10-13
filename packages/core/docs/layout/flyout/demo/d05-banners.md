---
order: 5
---

# Banners

<EuiText>
  <p>
    To highlight some information at the top of a flyout, you can pass an
    <strong>EuiCallOut</strong> in the <EuiCode>&lt;:banner&gt;</EuiCode> block
    available in <strong>EuiFlyoutBody</strong> and its layout will adjust
    appropriately.
  </p>
</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiButton, EuiCallOut, EuiFlyout, EuiFlyoutBody, EuiFlyoutHeader, EuiLink, EuiText, EuiTitle } from '@ember-eui/core/components';

export default class FlyoutBannerComponent extends Component {
  @tracked isFlyoutVisible = false;

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
    Show flyout with banner
  </EuiButton>

  {{#if this.isFlyoutVisible}}
    <EuiFlyout
      @ownFocus={{true}}
      @onClose={{this.closeFlyout}}
      aria-labelledby="bannerFlyoutTitle"
    >
      <EuiFlyoutHeader @hasBorder={{true}}>
        <EuiTitle @size="m" id="bannerFlyoutTitle">A flyout with a banner</EuiTitle>
      </EuiFlyoutHeader>
      <EuiFlyoutBody>
        <:banner>
          <EuiCallOut @iconType="help">
            <p>
              Here&rsquo;s some stuff that you need to know. This banner helps
              highlight important information.
              <EuiLink @href="#">View docs</EuiLink>
            </p>
          </EuiCallOut>
        </:banner>
        <:default>
          <EuiText>
            <p>
              This flyout is using the banner block in
              <strong>EuiFlyoutBody</strong>.
            </p>
          </EuiText>
        </:default>
      </EuiFlyoutBody>
    </EuiFlyout>
  {{/if}}
  </template>
}
```
