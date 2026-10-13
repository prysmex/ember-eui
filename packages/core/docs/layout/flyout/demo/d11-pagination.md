---
order: 11
---

# Pagination

<EuiText>
  <p>
    Pass a <EuiCode>@pagination</EuiCode> object to
    <EuiCode>EuiFlyoutMenu</EuiCode> to render Prev/Next navigation controls and
    a position counter in the flyout menu bar. This is useful when the flyout
    displays one item from an ordered list (e.g. a data table or search results)
    and the user should be able to step through items without closing the
    flyout.
  </p>
  <p>
    Use <EuiCode>@leadingActions</EuiCode> to render actions grouped alongside
    the pagination controls. A divider is automatically shown between the
    pagination controls and <EuiCode>@leadingActions</EuiCode>.
  </p>
  <p>
    The Prev/Next buttons default to up/down chevrons. When
    <EuiCode>onFirst</EuiCode>/<EuiCode>onLast</EuiCode> jump controls are
    provided, the Prev/Next icons automatically switch to left/right chevrons to
    match the horizontal navigation axis.
  </p>
</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiButton, EuiFlyout, EuiFlyoutBody, EuiFlyoutHeader, EuiFlyoutMenu, EuiText, EuiTitle } from '@ember-eui/core/components';

const ITEMS = [
  { title: 'Item 1', body: 'Details for item 1.' },
  { title: 'Item 2', body: 'Details for item 2.' },
  { title: 'Item 3', body: 'Details for item 3.' },
  { title: 'Item 4', body: 'Details for item 4.' },
  { title: 'Item 5', body: 'Details for item 5.' }
];

export default class FlyoutMenuPaginationComponent extends Component {
  @tracked isOpen = false;
  @tracked currentIndex = 0;

  leadingActions = [
    {
      iconType: 'documents',
      ariaLabel: 'View surrounding documents',
      toolTipContent: 'View surrounding documents',
      onClick: () => {
        window.alert('View surrounding documents clicked');
      }
    }
  ];

  get item() {
    return ITEMS[this.currentIndex];
  }

  get pagination() {
    return {
      currentIndex: this.currentIndex,
      total: ITEMS.length,
      onPrevious: this.previous,
      onNext: this.next
    };
  }

  @action
  open() {
    this.isOpen = true;
  }

  @action
  close() {
    this.isOpen = false;
  }

  @action
  previous() {
    this.currentIndex = Math.max(0, this.currentIndex - 1);
  }

  @action
  next() {
    this.currentIndex = Math.min(ITEMS.length - 1, this.currentIndex + 1);
  }

  <template>
  <EuiButton @isDisabled={{this.isOpen}} {{on "click" this.open}}>
    Open flyout
  </EuiButton>

  {{#if this.isOpen}}
    <EuiFlyout
      @onClose={{this.close}}
      @hideCloseButton={{true}}
      aria-label="Item details"
    >
      <EuiFlyoutMenu
        @pagination={{this.pagination}}
        @leadingActions={{this.leadingActions}}
        @onClose={{this.close}}
      />
      <EuiFlyoutHeader @hasBorder={{true}}>
        <EuiTitle @size="m">{{this.item.title}}</EuiTitle>
      </EuiFlyoutHeader>
      <EuiFlyoutBody>
        <EuiText>
          <p>{{this.item.body}}</p>
        </EuiText>
      </EuiFlyoutBody>
    </EuiFlyout>
  {{/if}}
  </template>
}
```
