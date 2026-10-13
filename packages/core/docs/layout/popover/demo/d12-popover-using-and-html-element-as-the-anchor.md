---
order: 12
---

# Popover using an HTML element as the anchor

<EuiText>
  <p>
    <strong>EuiWrappingPopover</strong> is an extra popover component that allows any existing DOM element to be passed as the <EuiCode>@button</EuiCode> argument. Here the button is plain HTML inserted outside of Ember's rendering, and the popover wraps it.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { tracked } from '@glimmer/tracking';
import { EuiWrappingPopover } from '@ember-eui/core/components';
import { action } from '@ember/object';

export default class PopoverDemo extends Component {
  @tracked anchor = null;
  @tracked isPopoverOpen = false;

  @action
  insertAnchor(container) {
    // a plain HTML element, created outside of Ember's rendering
    container.innerHTML = `
      <button id="popoverAnchorButton" type="button">
        This is an HTML button
      </button>
    `;
    const anchor = container.querySelector('#popoverAnchorButton');
    anchor.addEventListener('click', this.onButtonClick);
    this.anchor = anchor;
  }

  @action
  onButtonClick() {
    this.isPopoverOpen = !this.isPopoverOpen;
  }

  @action
  closePopover() {
    this.isPopoverOpen = false;
  }

  <template>
    <div {{didInsert this.insertAnchor}}></div>

    {{#if this.anchor}}
      <EuiWrappingPopover
        @button={{this.anchor}}
        @isOpen={{this.isPopoverOpen}}
        @closePopover={{this.closePopover}}
      >
        <div>Normal template content populates the popover.</div>
      </EuiWrappingPopover>
    {{/if}}
  </template>
}
```
