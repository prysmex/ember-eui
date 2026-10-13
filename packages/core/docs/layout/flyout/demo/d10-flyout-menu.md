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
    <EuiCode>EuiFlyoutMenu</EuiCode> is the top menu bar of a flyout. In Ember
    EUI it is a regular component that you place first inside
    <EuiCode>EuiFlyout</EuiCode> (upstream controls it with the
    <EuiCode>flyoutMenuProps</EuiCode> prop of <EuiCode>EuiFlyout</EuiCode>).
    Pass <EuiCode>@hideCloseButton={{true}}</EuiCode> to the flyout, so the
    menu renders the close button.
  </p>
  <p>
    Actions rendered via <EuiCode>@trailingActions</EuiCode> show a tooltip when
    <EuiCode>toolTipContent</EuiCode> is provided, and are placed before the
    close button. Use <EuiCode>@leadingActions</EuiCode> to render actions at
    the start of the menu bar, after any built-in leading controls (pagination,
    or back/history); a divider is shown automatically between the built-in
    controls and <EuiCode>@leadingActions</EuiCode> when both are present.
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
    The <EuiCode>@customActions</EuiCode> argument is deprecated in favor of
    <EuiCode>@trailingActions</EuiCode>, which takes precedence if both are
    supplied.
  </p>
</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiButton, EuiFlyout, EuiFlyoutBody, EuiFlyoutFooter, EuiFlyoutMenu } from '@ember-eui/core/components';

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
      @hideCloseButton={{true}}
      aria-labelledby="menuFlyoutTitle"
    >
      <EuiFlyoutMenu
        @title="My flyout with a menu"
        @titleId="menuFlyoutTitle"
        @trailingActions={{this.trailingActions}}
        @onClose={{this.closeFlyout}}
      />
      <EuiFlyoutBody>Flyout body</EuiFlyoutBody>
      <EuiFlyoutFooter>Flyout footer</EuiFlyoutFooter>
    </EuiFlyout>
  {{/if}}
  </template>
}
```
