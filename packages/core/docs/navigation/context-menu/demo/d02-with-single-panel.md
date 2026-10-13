---
order: 2
---

# With single panel

<EuiText>

Use **EuiContextMenuPanel** for simple, non-nested context menus. The below pagination example has no nesting and no title.

The selected context menu item should receive the `aria-current="true"` attribute, which tells screen readers which item is selected.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { eq } from 'ember-truth-helpers';
import { EuiButtonEmpty, EuiContextMenuItem, EuiContextMenuPanel, EuiPopover } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked isPopoverOpen = false;
  @tracked rowSize = 50;

  sizes = [10, 20, 50, 100];

  @action
  onButtonClick() {
    this.isPopoverOpen = !this.isPopoverOpen;
  }

  @action
  closePopover() {
    this.isPopoverOpen = false;
  }

  @action
  setRowSize(size) {
    this.closePopover();
    this.rowSize = size;
  }

  <template>
    <EuiPopover
      @isOpen={{this.isPopoverOpen}}
      @closePopover={{this.closePopover}}
      @panelPaddingSize="none"
      @anchorPosition="downLeft"
    >
      <:button>
        <EuiButtonEmpty
          @size="s"
          @iconType="chevronSingleDown"
          @iconSide="right"
          {{on "click" this.onButtonClick}}
        >
          Rows per page: {{this.rowSize}}
        </EuiButtonEmpty>
      </:button>
      <:content>
        <EuiContextMenuPanel @size="s">
          {{#each this.sizes as |size|}}
            <EuiContextMenuItem
              @icon={{if (eq size this.rowSize) "check" "empty"}}
              aria-current={{if (eq size this.rowSize) "true"}}
              {{on "click" (fn this.setRowSize size)}}
            >
              {{size}} rows
            </EuiContextMenuItem>
          {{/each}}
        </EuiContextMenuPanel>
      </:content>
    </EuiPopover>
  </template>
}
```
