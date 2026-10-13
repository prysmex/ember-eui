---
order: 2
---

# With single panel

<EuiText>

Use **EuiContextMenuPanel** for simple, non-nested context menus. The below pagination example has no nesting and no title.

The selected context menu item should receive the `aria-current="true"` attribute, which tells screen readers which item is selected.

As upstream, the panel takes its items as data with `@items` (the same entries as an **EuiContextMenu** panel's `items`; keys that are not item args, like `aria-current`, become attributes). The list then gets `role="menu"` and each item `role="menuitem"`. You can also render **EuiContextMenuItem**s in its block.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiButtonEmpty, EuiContextMenuPanel, EuiPopover } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked isPopoverOpen = false;
  @tracked rowSize = 50;

  sizes = [10, 20, 50, 100];

  get items() {
    return this.sizes.map((size) => ({
      key: `${size} rows`,
      name: `${size} rows`,
      icon: size === this.rowSize ? 'check' : 'empty',
      'aria-current': size === this.rowSize ? 'true' : undefined,
      onClick: () => this.setRowSize(size)
    }));
  }

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
        <EuiContextMenuPanel @items={{this.items}} />
      </:content>
    </EuiPopover>
  </template>
}
```
