---
order: 5
---

# Emphasized side nav sections

<EuiText>

Adding `emphasize: true` to a **EuiSideNav** item will enhance the visual appearance of that section and its nested items. This is helpful for when you need to indicate a dynamic navigational item like a user-created object.

The emphasized nav item's background color extends beyond the horizontal bounds of the component to allow it to reach its parent's bounds. Be sure to add `overflow: hidden` to whichever container you'd like it to stop at.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiSideNav } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked isSideNavOpenOnMobile = false;
  @tracked selectedItemName = 'Transactions';

  @action
  toggleOpenOnMobile() {
    this.isSideNavOpenOnMobile = !this.isSideNavOpenOnMobile;
  }

  // NOTE: Duplicate `name` values will cause `id` collisions.
  createItem = (name, data = {}) => ({
    ...data,
    id: name,
    name,
    isSelected: this.selectedItemName === name,
    onClick: () => {
      this.selectedItemName = name;
    }
  });

  get sideNav() {
    const createItem = this.createItem;

    return [
      createItem('APM', {
        items: [
          createItem('Services', {
            items: [
              createItem('opbeans-java', {
                emphasize: true,
                items: [
                  createItem('Transactions'),
                  createItem('Errors'),
                  createItem('JVMs')
                ]
              })
            ]
          }),
          createItem('Traces'),
          createItem('Service map')
        ]
      })
    ];
  }

  <template>
    <EuiSideNav
      aria-label="Emphasized side nav example"
      @mobileTitle="Navigate within $APP_NAME"
      @toggleOpenOnMobile={{this.toggleOpenOnMobile}}
      @isOpenMobile={{this.isSideNavOpenOnMobile}}
      @items={{this.sideNav}}
      style="width: 192px; overflow: hidden"
    />
  </template>
}
```
