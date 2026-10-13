---
order: 2
---

# Side nav heading

<EuiText>

Since **EuiSideNav** renders a `<nav>` section element, it is recommended that the element contain a heading. Pass a string to the `@heading` argument to display within an `<h2>`. Though you can also adjust this heading element with `@headingProps` (`element`).

If the heading is visually unnecessary for your application, pass `screenReaderOnly` in `@headingProps` to ensure proper accessibility for those using assistive technology.

When providing a heading, this will then be the default display for the mobile button title.

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
      id: 'headingExample-root',
      items: [
        {
          name: 'Item with onClick',
          id: 'headingExample-onclick',
          onClick: () => {}
        },
        {
          name: 'Item with href',
          id: 'headingExample-href',
          href: '#/navigation/side-nav'
        },
        {
          name: 'Selected item',
          id: 'headingExample-selected',
          onClick: () => {},
          isSelected: true
        },
        {
          name: 'Disabled item',
          id: 'headingExample-disabled',
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
      @heading="Nav heading"
      @toggleOpenOnMobile={{this.toggleOpenOnMobile}}
      @isOpenMobile={{this.isSideNavOpenOnMobile}}
      style="width: 192px"
      @items={{this.sideNav}}
    />
  </template>
}
```
