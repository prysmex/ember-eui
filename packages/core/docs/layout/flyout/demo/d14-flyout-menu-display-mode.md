---
order: 14
---

# Menu display mode

<EuiText>
  <p>
    By default the menu is rendered when <EuiCode>@flyoutMenuProps</EuiCode>
    is set and the menu has meaningful content. Control this with
    <EuiCode>@flyoutMenuDisplayMode</EuiCode>:
  </p>
  <ul>
    <li>
      <EuiCode>'auto'</EuiCode> (default): only render the menu when it has
      navigation content (back button, history, pagination or actions) or a
      visible title. Otherwise the flyout keeps its standalone close button.
    </li>
    <li>
      <EuiCode>'always'</EuiCode>: always render the menu, even when it only
      contains the close button.
    </li>
  </ul>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { EuiButton, EuiButtonGroup, EuiFlyout, EuiFlyoutBody, EuiSpacer, EuiText } from '@ember-eui/core/components';

export default class FlyoutMenuDisplayModeComponent extends Component {
  @tracked isOpen = false;
  @tracked displayMode = 'auto';

  modes = [
    { id: 'auto', label: 'auto' },
    { id: 'always', label: 'always' }
  ];

  @action
  setMode(id) {
    this.displayMode = id;
  }

  @action
  open() {
    this.isOpen = true;
  }

  @action
  close() {
    this.isOpen = false;
  }

  <template>
  <EuiButtonGroup
    @legend="Menu display mode"
    @options={{this.modes}}
    @idSelected={{this.displayMode}}
    @onChange={{this.setMode}}
  />
  <EuiSpacer />
  <EuiButton {{on "click" this.open}}>Show flyout</EuiButton>

  {{#if this.isOpen}}
    <EuiFlyout
      @onClose={{this.close}}
      @flyoutMenuProps={{hash title="Flyout with a hidden menu title"}}
      @flyoutMenuDisplayMode={{this.displayMode}}
    >
      <EuiFlyoutBody>
        <EuiText>
          <p>
            The menu only has a (visually hidden) title. With
            <code>{{this.displayMode}}</code> the flyout
            {{if (eq this.displayMode "always") "renders a close-only menu" "keeps its standalone close button"}}.
          </p>
        </EuiText>
      </EuiFlyoutBody>
    </EuiFlyout>
  {{/if}}
  </template>
}

function eq(a, b) {
  return a === b;
}
```
