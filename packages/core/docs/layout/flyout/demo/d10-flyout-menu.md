---
order: 10
---

# Flyout menu

<EuiCallOut @title="Beta" @color="accent" @iconType="beta">
  This component is still in beta and may change in the future.
</EuiCallOut>

<EuiSpacer />

<EuiText>
  <p>
    <EuiCode>@flyoutMenuProps</EuiCode> renders a menu bar at the top of the
    flyout, in place of its close button: the menu has its own close button,
    which calls the flyout's <EuiCode>@onClose</EuiCode>. It takes the
    arguments of <EuiCode>EuiFlyoutMenu</EuiCode> as an object, and the flyout
    is labelled by the menu title (visually hidden by default).
  </p>
  <p>
    Actions rendered via <EuiCode>trailingActions</EuiCode> show a tooltip when
    <EuiCode>toolTipContent</EuiCode> is provided, and are placed before the
    close button. Use <EuiCode>leadingActions</EuiCode> to render actions at
    the start of the menu bar, after any built-in leading controls (pagination,
    or back/history); a divider is shown automatically between the built-in
    controls and <EuiCode>leadingActions</EuiCode> when both are present.
  </p>
  <p>
    Each action accepts <EuiCode>iconType</EuiCode>, <EuiCode>ariaLabel</EuiCode>,
    <EuiCode>onClick</EuiCode>, <EuiCode>href</EuiCode>, <EuiCode>isDisabled</EuiCode>,
    <EuiCode>toolTipContent</EuiCode> and <EuiCode>dataTestSubj</EuiCode>. The menu
    bar sets the color, size and display itself so every action looks the same.
    When an action is disabled, provide <EuiCode>toolTipContent</EuiCode> to
    explain why.
  </p>
  <p>
    The <EuiCode>customActions</EuiCode> field is deprecated in favor of
    <EuiCode>trailingActions</EuiCode>, which takes precedence if both are
    supplied. In managed session flyouts (see Session management below)
    the flyout manager adds a back button and a history popover to the menu.
    You can still place <EuiCode>EuiFlyoutMenu</EuiCode> in the flyout's block
    yourself (see the back button and history example below); without
    <EuiCode>@onClose</EuiCode> its close button closes the flyout.
  </p>
</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { hash } from '@ember/helper';
import { EuiButton, EuiFlyout, EuiFlyoutBody, EuiFlyoutFooter } from '@ember-eui/core/components';

export default class FlyoutMenuBasicComponent extends Component {
  @tracked isFlyoutVisible = false;

  trailingActions = [
    {
      iconType: 'gear',
      ariaLabel: 'Settings',
      toolTipContent: 'Settings',
      onClick: () => {
        window.alert('Settings clicked');
      }
    }
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
    Show flyout with menu
  </EuiButton>

  {{#if this.isFlyoutVisible}}
    <EuiFlyout
      @onClose={{this.closeFlyout}}
      @flyoutMenuProps={{hash
        title="My flyout with a menu"
        trailingActions=this.trailingActions
      }}
    >
      <EuiFlyoutBody>Flyout body</EuiFlyoutBody>
      <EuiFlyoutFooter>Flyout footer</EuiFlyoutFooter>
    </EuiFlyout>
  {{/if}}
  </template>
}
```
