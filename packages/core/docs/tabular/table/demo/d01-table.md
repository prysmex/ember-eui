---
order: 1
---

# A basic table

<EuiText>

Header, rows and a footer with a total. Numbers are right aligned; long
text is truncated in the "Notes" column.

</EuiText>

```hbs template
<EuiTable>
  <EuiTableHeader>
    <EuiTableHeaderCell @width="30%">Service</EuiTableHeaderCell>
    <EuiTableHeaderCell>Notes</EuiTableHeaderCell>
    <EuiTableHeaderCell @align="right" @width={{120}} @description="Requests per minute">Load</EuiTableHeaderCell>
  </EuiTableHeader>
  <EuiTableBody>
    {{#each this.services as |service|}}
      <EuiTableRow>
        <EuiTableRowCell @setScopeRow={{true}}>{{service.name}}</EuiTableRowCell>
        <EuiTableRowCell @truncateText={{true}}>{{service.notes}}</EuiTableRowCell>
        <EuiTableRowCell @align="right">{{service.load}}</EuiTableRowCell>
      </EuiTableRow>
    {{/each}}
  </EuiTableBody>
  <EuiTableFooter>
    <EuiTableFooterCell>Total</EuiTableFooterCell>
    <EuiTableFooterCell />
    <EuiTableFooterCell @align="right">{{this.total}}</EuiTableFooterCell>
  </EuiTableFooter>
</EuiTable>
```

```js component
import Component from '@glimmer/component';

export default class BasicTable extends Component {
  services = [
    { name: 'checkout', notes: 'Handles payments and the order confirmation emails', load: 1200 },
    { name: 'search', notes: 'Full-text search over the product catalog', load: 5400 },
    { name: 'accounts', notes: 'Sign-in, sign-up and profile pages', load: 800 },
  ];

  get total() {
    return this.services.reduce((sum, service) => sum + service.load, 0);
  }
}
```
