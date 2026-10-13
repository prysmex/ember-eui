---
order: 12
---

# EuiFlyoutMenu in the flyout's block

<EuiText>

`EuiFlyoutMenu` can also be placed first in the flyout's block (pass
`@hideCloseButton={{true}}` to the flyout), e.g. to drive a back button and
history yourself without session management. It can show a back
button, a history popover (from two `@historyItems`, most recent first),
`@leadingActions` and `@trailingActions` icon buttons, or `@pagination`
controls with a position counter, followed by the flyout's close button.
The title is visually hidden by default; pass `@titleId` to label the flyout
with it.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiButton, EuiFlyout, EuiFlyoutBody, EuiFlyoutMenu, EuiText } from '@ember-eui/core/components';

export default class DemoFlyoutMenuComponent extends Component {
  @tracked isOpen = false;
  @tracked page = 1;
  @tracked history = [];

  get hasHistory() {
    return this.history.length > 0;
  }

  get backButtonProps() {
    return { onClick: this.back };
  }

  get historyItems() {
    return this.history.map((page) => ({
      title: `Page ${page}`,
      iconType: 'document',
      onClick: () => this.goTo(page)
    }));
  }

  actions = [{ iconType: 'share', ariaLabel: 'Share', toolTipContent: 'Share this page' }];

  @action
  openFlyout() {
    this.page = 1;
    this.history = [];
    this.isOpen = true;
  }

  @action
  closeFlyout() {
    this.isOpen = false;
  }

  @action
  next() {
    this.history = [this.page, ...this.history];
    this.page++;
  }

  @action
  back() {
    const [previous, ...rest] = this.history;

    this.page = previous;
    this.history = rest;
  }

  @action
  goTo(page) {
    this.history = this.history.slice(this.history.indexOf(page) + 1);
    this.page = page;
  }

  <template>
  <EuiButton {{on 'click' this.openFlyout}}>
    Open flyout with a menu
  </EuiButton>
  {{#if this.isOpen}}
    <EuiFlyout @onClose={{this.closeFlyout}} @hideCloseButton={{true}} aria-labelledby='menu-flyout-title'>
      <EuiFlyoutMenu
        @title='Page {{this.page}}'
        @titleId='menu-flyout-title'
        @showBackButton={{this.hasHistory}}
        @backButtonProps={{this.backButtonProps}}
        @historyItems={{this.historyItems}}
        @trailingActions={{this.actions}}
        @onClose={{this.closeFlyout}}
      />
      <EuiFlyoutBody>
        <EuiText>
          <p>Page {{this.page}}</p>
          <EuiButton @size='s' {{on 'click' this.next}}>Go to the next page</EuiButton>
        </EuiText>
      </EuiFlyoutBody>
    </EuiFlyout>
  {{/if}}
  </template>
}
```
