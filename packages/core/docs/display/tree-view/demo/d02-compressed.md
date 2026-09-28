---
order: 2
---

# Compressed with arrows

<EuiText>

`@display="compressed"` and `@showExpansionArrows` suit dense side
panels; `@expandByDefault` opens every level at first. The `<:label>`
block renders each node's label, here with a token for its type.

</EuiText>

```hbs template
<div style="width: 260px;">
  <EuiTreeView
    @items={{this.items}}
    @display="compressed"
    @showExpansionArrows={{true}}
    @expandByDefault={{true}}
    aria-label="Index fields"
  >
    <:label as |node|>
      {{#if node.type}}
        <EuiToken @iconType={{node.type}} @size="xs" />
      {{/if}}
      {{node.label}}
    </:label>
  </EuiTreeView>
</div>
```

```js component
import Component from '@glimmer/component';

export default class CompressedTree extends Component {
  items = [
    {
      id: 'customer',
      label: 'customer',
      children: [
        { id: 'customer-name', label: 'name', type: 'tokenString' },
        { id: 'customer-age', label: 'age', type: 'tokenNumber' },
        {
          id: 'customer-address',
          label: 'address',
          children: [
            { id: 'address-city', label: 'city', type: 'tokenKeyword' },
            { id: 'address-location', label: 'location', type: 'tokenGeo' },
          ],
        },
      ],
    },
    { id: 'timestamp', label: '@timestamp', type: 'tokenDate' },
  ];
}
```
