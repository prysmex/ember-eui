---
order: 2
---

# List of links

<EuiText>

Display **EuiListGroupItems** as links by providing an `@href` value and change their state with the `@isActive` and `@isDisabled` arguments.

If your link is external or will open in a new tab, you can manually set the `@external` argument. However, just like with the [EuiLink](/docs/navigation/link) component, setting `@target="_blank"` defaults to `@external={{true}}`.

As in this example, **EuiListGroup** can also take an array of items through `@listItems`: objects with the arguments of **EuiListGroupItem** (`label`, `href`, `iconType`, `isActive`, `target`, `extraAction`, …). The list's `@color`, `@wrapText` and `@showToolTips` are passed down to each item, and the block is ignored while there are `@listItems`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiListGroup } from '@ember-eui/core/components';

export default class ListOfLinksDemo extends Component {
  links = [
    {
      label: 'First link',
      href: '#/display/list-group',
      iconType: 'calendar',
    },
    {
      label: 'This is an active link with very long label that truncates',
      href: '#/display/list-group',
      isActive: true,
      iconType: 'clock',
    },
    {
      label: 'Third link is disabled',
      href: '#/display/list-group',
      isDisabled: true,
      iconType: 'compute',
    },
    {
      label: 'Fourth link',
      href: '#/display/list-group',
      iconType: 'copyClipboard',
    },
    {
      label: 'Fifth link will open in new tab',
      href: 'http://www.elastic.co',
      iconType: 'crosshairs',
      target: '_blank',
    },
  ];

  <template>
    <EuiListGroup @listItems={{this.links}} @color="primary" />
  </template>
}
```

