---
order: 6
---

# Pinnable list group

<EuiText>

**EuiPinnableListGroup** is simply an extra wrapper around an **EuiListGroup** that provides visual indicators for **pinning**.

Pinning is the concept that users can click a pin icon and add it to a subset of links (most likely shown in different list group). By providing an `@onPinClick` handler, the component will automatically add the pin action to the item. However, the consuming application must manage the `@listItems` and their `pinned` state.

In order to get the full benefit of using **EuiPinnableListGroup**, the component only supports providing list items via the `@listItems` argument and does not support a block.

</EuiText>

```hbs template
<EuiPinnableListGroup
  @listItems={{this.itemList}}
  @onPinClick={{this.togglePin}}
  @maxWidth="none"
  @pinTitle={{this.pinTitle}}
  @unpinTitle={{this.unpinTitle}}
/>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class PinnableDemo extends Component {
  @tracked itemList = [
    { id: '1', label: 'Label with iconType', iconType: 'home', pinned: false },
    { id: '2', label: 'Pinned button with onClick', pinned: true, onClick: () => {} },
    { id: '6', label: 'Link with href and custom pin titles', href: '/#', pinned: false, color: 'primary' },
    { id: '3', label: 'Active link', isActive: true, href: '/#', pinned: false },
    {
      id: '4',
      label: 'Custom extra actions will override pinning ability',
      extraAction: { iconType: 'bell', alwaysShow: true, 'aria-label': 'bell' },
    },
    { id: '5', label: 'Item with pinnability turned off', pinnable: false },
  ];

  pinTitle = (item) => `Pin ${item.label}`;
  unpinTitle = (item) => `Unpin ${item.label}`;

  @action
  togglePin(selectedItem) {
    if (Object.prototype.hasOwnProperty.call(selectedItem, 'pinned')) {
      this.itemList = this.itemList.map((item) =>
        item.id === selectedItem.id ? { ...item, pinned: !item.pinned } : item,
      );
    }
  }
}
```
