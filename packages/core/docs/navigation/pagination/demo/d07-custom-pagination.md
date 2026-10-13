---
order: 7
---

# Custom pagination

<EuiText>

Or you can use **EuiFlexGroup** and **EuiContextMenu** to set up your own custom pagination layout.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { EuiButtonEmpty, EuiContextMenuItem, EuiContextMenuPanel, EuiFlexGroup, EuiFlexItem, EuiPagination, EuiPopover } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked isPopoverOpen = false;
  @tracked activePage = 0;
  @tracked rowSize = 50;

  getIconType = (size) => (size === this.rowSize ? 'check' : 'empty');

  @action
  onButtonClick() {
    this.isPopoverOpen = !this.isPopoverOpen;
  }

  @action
  closePopover() {
    this.isPopoverOpen = false;
  }

  @action
  goToPage(pageNumber) {
    this.activePage = pageNumber;
  }

  @action
  setRowSize(size) {
    this.closePopover();
    this.rowSize = size;
  }

  <template>
    <EuiFlexGroup
      @justifyContent="spaceBetween"
      @alignItems="center"
      @responsive={{false}}
      @wrap={{true}}
    >
      <EuiFlexItem @grow={{false}}>
        <EuiPopover
          @isOpen={{this.isPopoverOpen}}
          @closePopover={{this.closePopover}}
          @panelPaddingSize="none"
        >
          <:button>
            <EuiButtonEmpty
              @size="xs"
              @color="text"
              @iconType="chevronSingleDown"
              @iconSide="right"
              {{on "click" this.onButtonClick}}
            >
              Rows per page: {{this.rowSize}}
            </EuiButtonEmpty>
          </:button>
          <:content>
            <EuiContextMenuPanel>
              <EuiContextMenuItem @icon={{this.getIconType 10}} {{on "click" (fn this.setRowSize 10)}}>
                10 rows
              </EuiContextMenuItem>
              <EuiContextMenuItem @icon={{this.getIconType 20}} {{on "click" (fn this.setRowSize 20)}}>
                20 rows
              </EuiContextMenuItem>
              <EuiContextMenuItem @icon={{this.getIconType 50}} {{on "click" (fn this.setRowSize 50)}}>
                50 rows
              </EuiContextMenuItem>
            </EuiContextMenuPanel>
          </:content>
        </EuiPopover>
      </EuiFlexItem>

      <EuiFlexItem @grow={{false}}>
        <EuiPagination
          aria-label="Custom pagination example"
          @pageCount={{10}}
          @activePage={{this.activePage}}
          @onPageClick={{this.goToPage}}
        />
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```
