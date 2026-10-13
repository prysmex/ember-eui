---
order: 13
---

# Extra: computed columns, nested fields and HTML

<EuiText>

An Ember EUI example beyond upstream's: a `field` can be a nested path
(`owner.team`), `render` can return `htmlSafe` markup, a computed column
(no `field`) derives its content from the whole item with `render(item)`,
and a function footer totals the column.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { htmlSafe } from '@ember/template';
import { EuiBasicTable } from '@ember-eui/core/components';

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

  <template>
    <EuiBasicTable
      @tableCaption="Deployments"
      @items={{this.items}}
      @columns={{this.columns}}
      @rowHeader="service"
    />
  </template>
}
```
