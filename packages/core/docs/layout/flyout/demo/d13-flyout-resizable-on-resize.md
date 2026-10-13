---
order: 13
---

# EuiFlyoutResizable and onResize

<EuiText>

`EuiFlyoutResizable` is an `EuiFlyout` with `@resizable` already set. Drag the
handle, or focus it and press the left and right arrow keys to resize in 10px
steps. The width is kept as a share of the window and limited by `@minWidth`,
`@maxWidth` (a number in pixels) and 90% of the window. `@onResize` receives
the width in pixels after a drag ends and on each key press.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiButton, EuiFlyoutBody, EuiFlyoutHeader, EuiFlyoutResizable, EuiText, EuiTitle } from '@ember-eui/core/components';

export default class DemoResizableFlyoutComponent extends Component {
  @tracked isOpen = false;
  @tracked width = 480;

  @action
  openFlyout() {
    this.isOpen = true;
  }

  @action
  closeFlyout() {
    this.isOpen = false;
  }

  @action
  onResize(width) {
    this.width = Math.round(width);
  }

  <template>
  <EuiButton {{on 'click' this.openFlyout}}>
    Open resizable flyout
  </EuiButton>

  {{#if this.isOpen}}
    <EuiFlyoutResizable
      @size={{480}}
      @minWidth={{320}}
      @maxWidth={{900}}
      @onResize={{this.onResize}}
      @onClose={{this.closeFlyout}}
      aria-labelledby='resizable-flyout-title'
    >
      <EuiFlyoutHeader @hasBorder={{true}}>
        <EuiTitle @size='m'><h2 id='resizable-flyout-title'>Resizable flyout</h2></EuiTitle>
      </EuiFlyoutHeader>
      <EuiFlyoutBody>
        <EuiText>
          <p>Width: {{this.width}}px</p>
        </EuiText>
      </EuiFlyoutBody>
    </EuiFlyoutResizable>
  {{/if}}
  </template>
}
```
