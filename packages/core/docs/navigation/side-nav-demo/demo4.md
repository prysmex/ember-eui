---
order: 4
---

# Nested item options

<EuiText>

Typically, the children of nested items progressively shows as users traverse the pages themselves. However, you can bypass this functionality and force open items by setting `items[n].forceOpen = true`.

Arrow indicators will show only if the item has children but **does not** have an interaction itself. The component will then handle the toggling of the displayed children as well.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiSideNav } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked isSideNavOpenOnMobile = false;
  @tracked selectedItemName = null;

  @action
  toggleOpenOnMobile() {
    this.isSideNavOpenOnMobile = !this.isSideNavOpenOnMobile;
  }

  // NOTE: Duplicate `name` values will cause `id` collisions.
  createItem = (name, data = {}) => ({
    id: name,
    name,
    isSelected: this.selectedItemName === name,
    onClick: () => {
      this.selectedItemName = name;
    },
    ...data
  });

  get sideNav() {
    const createItem = this.createItem;

    return [
      {
        name: 'Kibana',
        id: 'Kibana',
        icon: 'logoKibana',
        items: [
          createItem('Has normal children', {
            items: [
              createItem('Without forceOpen', {
                items: [createItem('Child 1'), createItem('Child 2')]
              })
            ]
          }),
          createItem('Normally not open', {
            items: [
              createItem('Has forceOpen:true', {
                forceOpen: true,
                items: [createItem('Child 3'), createItem('Child 4')]
              })
            ]
          }),
          createItem('With forceOpen:true', {
            forceOpen: true,
            items: [
              createItem('Normal child', {
                items: [createItem('Child 5'), createItem('Child 6')]
              })
            ]
          }),
          createItem('Children only, no link', {
            onClick: undefined,
            items: [
              createItem('Another child', {
                items: [createItem('Child 7'), createItem('Child 8')]
              })
            ]
          })
        ]
      }
    ];
  }

  <template>
    <EuiSideNav
      aria-label="Force-open example"
      @mobileTitle="Navigate within $APP_NAME"
      @toggleOpenOnMobile={{this.toggleOpenOnMobile}}
      @isOpenOnMobile={{this.isSideNavOpenOnMobile}}
      @items={{this.sideNav}}
      style="width: 192px"
    />
  </template>
}
```
