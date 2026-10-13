---
order: 1
---

# Side nav

<EuiText>

**EuiSideNav** is a responsive menu system that usually sits on the left side of a page layout. It will expand to the width of its container.

Configure the content of a **EuiSideNav** by passing in an `@items` array. Refer to the source code for an example of this data structure’s anatomy.

The responsive behavior converts the list into an accordion style component with a mobile only button. You will need to pass a string to the argument `@mobileTitle` to label the mobile button.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiSideNav } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked isSideNavOpenOnMobile = false;

  sideNav = [
    {
      name: 'Root item',
      id: 'basicExample-root',
      items: [
        {
          name: 'Item with onClick',
          id: 'basicExample-onclick',
          onClick: () => {}
        },
        {
          name: 'Item with href',
          id: 'basicExample-href',
          href: '#/navigation/side-nav'
        },
        {
          name: 'Selected item',
          id: 'basicExample-selected',
          onClick: () => {},
          isSelected: true
        },
        {
          name: 'Disabled item',
          id: 'basicExample-disabled',
          disabled: true
        }
      ]
    }
  ];

  @action
  toggleOpenOnMobile() {
    this.isSideNavOpenOnMobile = !this.isSideNavOpenOnMobile;
  }

  <template>
    <EuiSideNav
      aria-label="Basic example"
      @mobileTitle="Basic example"
      @toggleOpenOnMobile={{this.toggleOpenOnMobile}}
      @isOpenMobile={{this.isSideNavOpenOnMobile}}
      style="width: 192px"
      @items={{this.sideNav}}
    />
  </template>
}
```
