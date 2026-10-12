---
order: 3
---

# Actions and expanded rows

<EuiText>

More than two actions move to an "All actions" menu; primary actions stay
inline and show on hover. The expander column toggles rows of
`@itemIdToExpandedRowMap`, rendered by the `<:expandedRow>` block.

</EuiText>

```hbs template
<EuiBasicTable
  @items={{this.items}}
  @itemId="id"
  @columns={{this.columns}}
  @itemIdToExpandedRowMap={{this.expanded}}
  @rowProps={{this.rowProps}}
>
  <:expandedRow as |item|>
    <EuiDescriptionList @compressed={{true}} @listItems={{this.details item}} />
  </:expandedRow>
</EuiBasicTable>
<EuiSpacer @size="s" />
<EuiText @size="s" @color="subdued"><p>{{this.lastAction}}</p></EuiText>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class BasicTableActions extends Component {
  @tracked expanded = {};
  @tracked lastAction = 'Click a row or an action.';

  items = [
    { id: 'a', name: 'Alerts', owner: 'Ops', rules: 12 },
    { id: 'b', name: 'Billing', owner: 'Finance', rules: 3 },
    { id: 'c', name: 'Builds', owner: 'Platform', rules: 27 },
  ];

  log = (text) => (this.lastAction = text);

  columns = [
    {
      name: 'Details',
      isExpander: true,
      width: '90px',
      render: (item) => (this.expanded[item.id] ? 'Collapse' : 'Expand'),
    },
    { field: 'name', name: 'Name' },
    { field: 'owner', name: 'Owner' },
    { field: 'rules', name: 'Rules', dataType: 'number' },
    {
      name: 'Actions',
      actions: [
        { name: 'Edit', description: 'Edit', isPrimary: true, type: 'icon', icon: 'pencil', onClick: (item) => this.log(`Edit ${item.name}`) },
        { name: 'Clone', description: 'Clone', type: 'icon', icon: 'copy', onClick: (item) => this.log(`Clone ${item.name}`) },
        { name: 'Share', description: 'Share', type: 'icon', icon: 'share', onClick: (item) => this.log(`Share ${item.name}`) },
        { name: 'Delete', description: 'Delete', type: 'icon', icon: 'trash', color: 'danger', isPrimary: true, onClick: (item) => this.log(`Delete ${item.name}`) },
      ],
    },
  ];

  rowProps = (item) => ({
    'data-test-subj': `row-${item.id}`,
    onClick: (event) => {
      if (event.target.closest('button')) return;
      const expanded = { ...this.expanded };
      if (expanded[item.id]) delete expanded[item.id];
      else expanded[item.id] = true;
      this.expanded = expanded;
    },
  });

  details = (item) => [
    { title: 'Owner', description: item.owner },
    { title: 'Rules', description: String(item.rules) },
  ];
}
```
