---
order: 2
---

# Optional styling

<EuiText>

`EuiTreeView` supports a compressed mode with `@display="compressed"`. When using the compressed version it's highly recommended to use the small size of `EuiIcon` and the extra small size of `EuiToken`. This will help prevent awkward alignment issues when used alongside the `@showExpansionArrows` argument.

The `@showExpansionArrows` argument provides an additional visual indicator. Ideal for when a tree's items use icons that don't immediately let a user know that there are nested nodes that may not be visible.

In some cases, you may want to automatically expand all the items with children. In those instances, you can use the `@expandByDefault` argument, as seen in the example below.

Lastly, each node can also accept a custom `className` should you need to style them individually.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiToken, EuiTreeView } from '@ember-eui/core/components';

const tokenIcon = (token) => <template><EuiToken @iconType={{token}} @size='xs' /></template>;

export default class extends Component {
  items = [
    {
      label: 'transporter',
      id: 'transporter',
      icon: tokenIcon('tokenObject'),
      children: [
        { label: 'service', id: 'service', icon: tokenIcon('tokenString') },
        {
          label: 'auth',
          id: 'auth',
          icon: tokenIcon('tokenObject'),
          children: [
            { label: 'user', id: 'user', icon: tokenIcon('tokenVariable') },
            { label: 'pass', id: 'pass', icon: tokenIcon('tokenVariable') },
          ],
        },
      ],
    },
    {
      label: 'getContact',
      id: 'getContact',
      icon: tokenIcon('tokenFunction'),
      children: [
        {
          label: 'render',
          id: 'render',
          icon: tokenIcon('tokenFunction'),
          children: [{ label: 'title', id: 'title', icon: tokenIcon('tokenString') }],
        },
      ],
    },
    {
      label: 'postContact',
      id: 'postContact',
      icon: tokenIcon('tokenFunction'),
      children: [
        { label: 'errors', id: 'errors', icon: tokenIcon('tokenConstant') },
        {
          label: 'A custom class is on this one',
          id: 'customClass',
          icon: tokenIcon('tokenObject'),
          className: 'docsTreeViewNode',
        },
      ],
    },
    { label: 'smokeMonster', id: 'smokeMonster', icon: tokenIcon('tokenMethod') },
  ];

  <template>
    <style>
      .docsTreeViewNode { background-color: rgba(255, 220, 0, 0.2); }
    </style>
    <div style='width: 20rem'>
      <EuiTreeView
        @items={{this.items}}
        @display='compressed'
        @expandByDefault={{true}}
        @showExpansionArrows={{true}}
        aria-label='Document Outline' />
    </div>
  </template>
}
```

