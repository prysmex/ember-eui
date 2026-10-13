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

```hbs template
<style>
  .docsTreeViewNode { background-color: rgba(255, 220, 0, 0.2); }
</style>
<div style='width: 20rem'>
  <EuiTreeView
    @items={{this.items}}
    @display='compressed'
    @expandByDefault={{true}}
    @showExpansionArrows={{true}}
    aria-label='Document Outline'
  >
    <:label as |node|>
      <EuiToken @iconType={{node.token}} @size='xs' />
      {{node.label}}
    </:label>
  </EuiTreeView>
</div>
```

```js component
import Component from '@glimmer/component';

export default class extends Component {
  items = [
    {
      label: 'transporter',
      id: 'transporter',
      token: 'tokenObject',
      children: [
        { label: 'service', id: 'service', token: 'tokenString' },
        {
          label: 'auth',
          id: 'auth',
          token: 'tokenObject',
          children: [
            { label: 'user', id: 'user', token: 'tokenVariable' },
            { label: 'pass', id: 'pass', token: 'tokenVariable' },
          ],
        },
      ],
    },
    {
      label: 'getContact',
      id: 'getContact',
      token: 'tokenFunction',
      children: [
        {
          label: 'render',
          id: 'render',
          token: 'tokenFunction',
          children: [{ label: 'title', id: 'title', token: 'tokenString' }],
        },
      ],
    },
    {
      label: 'postContact',
      id: 'postContact',
      token: 'tokenFunction',
      children: [
        { label: 'errors', id: 'errors', token: 'tokenConstant' },
        {
          label: 'A custom class is on this one',
          id: 'customClass',
          token: 'tokenObject',
          className: 'docsTreeViewNode',
        },
      ],
    },
    { label: 'smokeMonster', id: 'smokeMonster', token: 'tokenMethod' },
  ];
}
```
