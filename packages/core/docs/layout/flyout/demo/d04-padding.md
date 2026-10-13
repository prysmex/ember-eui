---
order: 4
---

# Padding

<EuiText>
  <p>
    All the inner flyout components inherit their padding from the wrapping
    <strong>EuiFlyout</strong> component. This ensures that all the horizontal
    edges line up no matter the <EuiCode>@paddingSize</EuiCode>. When using the
    <EuiCode>"none"</EuiCode> size, you will need to accommodate your content
    with some other way of creating distance to the edges of the flyout.
  </p>
</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiButton, EuiButtonEmpty, EuiButtonGroup, EuiCallOut, EuiFlexGroup, EuiFlexItem, EuiFlyout, EuiFlyoutBody, EuiFlyoutFooter, EuiFlyoutHeader, EuiFormRow, EuiTitle } from '@ember-eui/core/components';

export default class FlyoutPaddingComponent extends Component {
  @tracked isFlyoutVisible = false;
  @tracked paddingSize = 'l';

  sizes = [
    { id: 'none', label: 'None' },
    { id: 's', label: 'Small' },
    { id: 'm', label: 'Medium' },
    { id: 'l', label: 'Large' }
  ];

  get paddingSizeName() {
    return this.sizes
      .find((size) => size.id === this.paddingSize)
      .label.toLowerCase();
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
    this.paddingSize = id;
  }

  <template>
  <EuiButton
    aria-controls="mediumPaddingFlyout"
    aria-expanded={{if this.isFlyoutVisible "true" "false"}}
    aria-haspopup="true"
    aria-label="Show padding size flyout"
    {{on "click" this.showFlyout}}
  >
    Show flyout to test padding sizes
  </EuiButton>

  {{#if this.isFlyoutVisible}}
    <EuiFlyout
      @ownFocus={{true}}
      @onClose={{this.closeFlyout}}
      @paddingSize={{this.paddingSize}}
      id="mediumPaddingFlyout"
      aria-labelledby="mediumPaddingFlyoutTitle"
    >
      <EuiFlyoutHeader @hasBorder={{true}}>
        <EuiTitle @size="m" id="mediumPaddingFlyoutTitle">
          A flyout with a {{this.paddingSizeName}} padding
        </EuiTitle>
      </EuiFlyoutHeader>
      <EuiFlyoutBody>
        <:banner>
          <EuiCallOut
            @title="The banner left and right padding is {{this.paddingSizeName}} to match that of flyout"
          />
        </:banner>
        <:default>
          <EuiFormRow @label="Change the paddingSize">
            <EuiButtonGroup
              @legend="Flyout paddingSize"
              @color="primary"
              @buttonSize="s"
              @options={{this.sizes}}
              @idSelected={{this.paddingSize}}
              @onChange={{this.onChange}}
            />
          </EuiFormRow>
        </:default>
      </EuiFlyoutBody>
      <EuiFlyoutFooter>
        <EuiFlexGroup @justifyContent="spaceBetween">
          <EuiFlexItem @grow={{false}}>
            <EuiButtonEmpty @iconType="cross" @flush="left" {{on "click" this.closeFlyout}}>
              Close
            </EuiButtonEmpty>
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiButton @fill={{true}} {{on "click" this.closeFlyout}}>
              Save
            </EuiButton>
          </EuiFlexItem>
        </EuiFlexGroup>
      </EuiFlyoutFooter>
    </EuiFlyout>
  {{/if}}
  </template>
}
```
