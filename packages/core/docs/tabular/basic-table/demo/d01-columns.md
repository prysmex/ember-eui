---
order: 1
---

# Columns and data types

<EuiText>

Field columns format their values by `dataType`; numbers are right
aligned. `render` returns text, a computed column derives its content from
the whole item and footers can total the column.

</EuiText>

```hbs template
<EuiBasicTable
  @tableCaption="Deployments"
  @items={{this.items}}
  @columns={{this.columns}}
  @rowHeader="service"
/>
```

```js component
import Component from '@glimmer/component';
import { htmlSafe } from '@ember/template';

export default class BasicTableColumns extends Component {
  items = [
    { id: 1, service: 'checkout', version: '3.2.0', instances: 12, healthy: true, deployed: new Date(2026, 8, 1, 9, 30), owner: { team: 'Payments' } },
    { id: 2, service: 'search', version: '1.14.2', instances: 30, healthy: true, deployed: new Date(2026, 8, 3, 14, 5), owner: { team: 'Discovery' } },
    { id: 3, service: 'accounts', version: '7.0.0-rc.1', instances: 4, healthy: false, deployed: new Date(2026, 8, 5, 18, 45), owner: { team: 'Identity' } },
  ];

  columns = [
    { field: 'service', name: 'Service', footer: 'Total' },
    { field: 'owner.team', name: 'Team' },
    { field: 'version', name: 'Version', render: (version) => htmlSafe(`<code>${version}</code>`) },
    { field: 'healthy', name: 'Healthy', dataType: 'boolean' },
    { field: 'deployed', name: 'Deployed', dataType: 'date' },
    {
      field: 'instances',
      name: 'Instances',
      dataType: 'number',
      footer: ({ items }) => String(items.reduce((sum, item) => sum + item.instances, 0)),
    },
    { name: 'Status', render: (item) => (item.healthy ? 'Serving' : 'Degraded'), nameTooltip: { content: 'Computed from the health check' } },
  ];
}
```
