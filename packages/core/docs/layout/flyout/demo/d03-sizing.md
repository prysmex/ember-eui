---
order: 3
---

# Sizing

<EuiText>
  <p>
    Flyouts come in three predefined <EuiCode>@size</EuiCode>s of
    <EuiCode>'s' | 'm' | 'l'</EuiCode>, which define the width
    <strong>relative to the window size</strong> with a minimum width defined in
    pixels. You can otherwise supply your own fixed width in number or string
    format.
  </p>
</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiButton, EuiButtonGroup, EuiFlyout, EuiFlyoutBody, EuiFlyoutHeader, EuiFormRow, EuiTitle } from '@ember-eui/core/components';

export default class FlyoutSizingComponent extends Component {
  @tracked isFlyoutVisible = false;
  @tracked size = 'l';

  sizes = [
    { id: 's', label: 'Small' },
    { id: 'm', label: 'Medium' },
    { id: 'l', label: 'Large' },
    { id: '400px', label: 'Fixed (400)' }
  ];

  get sizeName() {
    return this.sizes.find((size) => size.id === this.size).label.toLowerCase();
  }

  @action
  showFlyout() {
    this.isFlyoutVisible = true;
  }

  @action
  closeFlyout() {
    this.isFlyoutVisible = false;
  }

  @action
  onChange(id) {
    this.size = id;
  }

  <template>
  <EuiButton {{on "click" this.showFlyout}}>
    Show flyout to test widths
  </EuiButton>

  {{#if this.isFlyoutVisible}}
    <EuiFlyout
      @ownFocus={{true}}
      @onClose={{this.closeFlyout}}
      @size={{this.size}}
      aria-labelledby="largeFlyoutTitle"
    >
      <EuiFlyoutHeader @hasBorder={{true}}>
        <EuiTitle @size="m" id="largeFlyoutTitle">A {{this.sizeName}} flyout</EuiTitle>
      </EuiFlyoutHeader>
      <EuiFlyoutBody>
        <EuiFormRow @label="Change the flyout size">
          <EuiButtonGroup
            @legend="Flyout size"
            @color="primary"
            @buttonSize="s"
            @options={{this.sizes}}
            @idSelected={{this.size}}
            @onChange={{this.onChange}}
          />
        </EuiFormRow>
      </EuiFlyoutBody>
    </EuiFlyout>
  {{/if}}
  </template>
}
```
