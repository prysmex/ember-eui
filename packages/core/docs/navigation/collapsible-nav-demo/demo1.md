---
order: 1
---

# Collapsible nav

<EuiText>

This is a high level component that creates a flyout-style navigational pane.

**EuiCollapsibleNav** is a custom implementation of **EuiFlyout**; the visibility of which must still be maintained by the consuming application. An extra feature that it provides is the ability to `dock` the flyout (`@isDocked`). This affixes the flyout to the window and pushes the body content by adding left side padding.

Docking is not possible on small screens because it would force less real estate for the page content.

The toggle button goes in the `<:button>` block and the nav's content in the `<:content>` block.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiButton, EuiCode, EuiCollapsibleNav, EuiSpacer, EuiText, EuiTitle } from '@ember-eui/core/components';

const STORAGE_KEY = 'euiCollapsibleNavExample--isDocked';

function readDocked() {
  try {
    return JSON.parse(String(localStorage.getItem(STORAGE_KEY))) || false;
  } catch {
    return false;
  }
}

export default class DemoComponent extends Component {
  @tracked navIsOpen = readDocked();
  @tracked navIsDocked = readDocked();

  @action
  toggleNav() {
    this.navIsOpen = !this.navIsOpen;
  }

  @action
  closeNav() {
    this.navIsOpen = false;
  }

  @action
  toggleDocked() {
    this.navIsDocked = !this.navIsDocked;
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(this.navIsDocked));
    } catch {
      // storage can be unavailable
    }
  }

  <template>
    <EuiCollapsibleNav
      @isOpen={{this.navIsOpen}}
      @isDocked={{this.navIsDocked}}
      @size={{240}}
      @onClose={{this.closeNav}}
    >
      <:button as |handlers|>
        <EuiButton {{on "click" this.toggleNav}} {{handlers}}>
          Toggle nav
        </EuiButton>
      </:button>
      <:content>
        <div style="padding: 16px">
          <EuiTitle @tagName="h2">I am some nav</EuiTitle>
          <EuiSpacer />
          <EuiText @size="s" @color="subdued">
            <p>
              The docked status is being stored in <EuiCode>localStorage</EuiCode>.
            </p>
          </EuiText>
          <EuiSpacer />
          <EuiButton {{on "click" this.toggleDocked}}>
            Docked: {{if this.navIsDocked "on" "off"}}
          </EuiButton>
        </div>
      </:content>
    </EuiCollapsibleNav>

    {{#if this.navIsDocked}}
      <EuiText @size="s" @color="subdued">
        <p>
          The <EuiCode>button</EuiCode> gets hidden by default when the nav is
          docked unless you set
          <EuiCode @language="js">@showButtonIfDocked=&#123;&#123;true&#125;&#125;</EuiCode>.
        </p>
      </EuiText>
    {{/if}}
  </template>
}
```
