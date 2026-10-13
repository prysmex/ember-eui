---
order: 9
---

# Resizable flyout

<EuiText>
  <p>
    Set the <EuiCode>@resizable={{true}}</EuiCode> argument to render a flyout
    that users can drag with their mouse or use arrow keys to resize. This may
    be useful for scenarios where the available space can be unpredictable due
    to dynamic content. Resizable flyouts allow users to adjust content to better
    fit their personal screens and workflows.
  </p>
  <p>
    Alternatively, you can also use the <EuiCode>EuiFlyoutResizable</EuiCode>
    component which is a thin wrapper around <EuiCode>EuiFlyout</EuiCode> that
    sets <EuiCode>@resizable</EuiCode> for you. When writing new code, we
    recommend using the regular <EuiCode>EuiFlyout</EuiCode> component with
    <EuiCode>@resizable={{true}}</EuiCode> added.
  </p>
  <p>
    We strongly recommend setting reasonable numerical
    <EuiCode>@minWidth</EuiCode> and <EuiCode>@maxWidth</EuiCode> arguments
    based on the flyout content and page content that you <em>can</em> predict.
  </p>
</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { set } from 'ember-set-helper';
import { EuiButton, EuiButtonGroup, EuiFlyout, EuiFlyoutBody, EuiFlyoutHeader, EuiSpacer, EuiText, EuiTitle } from '@ember-eui/core/components';

export default class FlyoutResizableComponent extends Component {
  @tracked isFlyoutVisible = false;
  @tracked flyoutType = 'overlay';
  @tracked flyoutSide = 'right';

  typeOptions = [
    { id: 'overlay', label: 'Overlay' },
    { id: 'push', label: 'Push' }
  ];

  sideOptions = [
    { id: 'right', label: 'Right' },
    { id: 'left', label: 'Left' }
  ];

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
    Show resizable flyout
  </EuiButton>

  {{#if this.isFlyoutVisible}}
    <EuiFlyout
      @resizable={{true}}
      @type={{this.flyoutType}}
      @side={{this.flyoutSide}}
      @onClose={{this.closeFlyout}}
      aria-labelledby="resizableFlyoutTitle"
    >
      <EuiFlyoutHeader @hasBorder={{true}}>
        <EuiTitle @size="m" id="resizableFlyoutTitle">A resizable flyout</EuiTitle>
      </EuiFlyoutHeader>
      <EuiFlyoutBody>
        <EuiText>
          <p>
            This flyout is resizable by both mouse drag and arrow keys (when the
            resizable edge is focused). Both push and overlay flyouts can be
            resizable, on either side.
          </p>
        </EuiText>
        <EuiSpacer />
        <EuiTitle @size="xxs" @tagName="h3">Flyout type</EuiTitle>
        <EuiSpacer @size="s" />
        <EuiButtonGroup
          @legend="Flyout type"
          @options={{this.typeOptions}}
          @idSelected={{this.flyoutType}}
          @onChange={{set this "flyoutType"}}
        />
        <EuiSpacer />
        <EuiTitle @size="xxs" @tagName="h3">Flyout side</EuiTitle>
        <EuiButtonGroup
          @legend="Flyout side"
          @options={{this.sideOptions}}
          @idSelected={{this.flyoutSide}}
          @onChange={{set this "flyoutSide"}}
        />
      </EuiFlyoutBody>
    </EuiFlyout>
  {{/if}}
  </template>
}
```
