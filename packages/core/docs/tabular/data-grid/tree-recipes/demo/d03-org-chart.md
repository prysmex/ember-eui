---
order: 3
---

# Org chart

<EuiText>

Flat rows (as exported from an HR system) with `email` ids and a
`managerEmail`, mapped with `getRowId` and `getParentId`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { get, hash } from '@ember/helper';
import { eq } from 'ember-truth-helpers';
import { EuiAvatar, EuiDataGrid } from '@ember-eui/core/components';

export default class OrgChartDemo extends Component {
  columns = [
    { id: 'name', displayAsText: 'Name', initialWidth: 300 },
    { id: 'title', displayAsText: 'Title' },
    { id: 'reports', displayAsText: 'Direct reports', schema: 'numeric' }
  ];

  people = [
    { email: 'ada@example.com', name: 'Ada Lovelace', title: 'CEO' },
    { email: 'grace@example.com', managerEmail: 'ada@example.com', name: 'Grace Hopper', title: 'CTO' },
    { email: 'katherine@example.com', managerEmail: 'ada@example.com', name: 'Katherine Johnson', title: 'CFO' },
    { email: 'linus@example.com', managerEmail: 'grace@example.com', name: 'Linus Torvalds', title: 'Kernel lead' },
    { email: 'margaret@example.com', managerEmail: 'grace@example.com', name: 'Margaret Hamilton', title: 'Engineering manager' },
    { email: 'dennis@example.com', managerEmail: 'margaret@example.com', name: 'Dennis Ritchie', title: 'Engineer' },
    { email: 'barbara@example.com', managerEmail: 'margaret@example.com', name: 'Barbara Liskov', title: 'Engineer' },
    { email: 'alan@example.com', managerEmail: 'katherine@example.com', name: 'Alan Turing', title: 'Analyst' }
  ];

  getRowId = (person) => person.email;
  getParentId = (person) => person.managerEmail;

  reportCount = (person) => this.people.filter((other) => other.managerEmail === person.email).length;

  <template>
    <EuiDataGrid
      aria-label="Org chart"
      @columns={{this.columns}}
      @rowTree={{hash
        rows=this.people
        getRowId=this.getRowId
        getParentId=this.getParentId
        defaultExpandedRowIds="all"
      }}
      @rowHeightsOptions={{hash defaultHeight=44}}
      @height={{380}}
    >
      <:cell as |cell|>
        {{#if (eq cell.columnId "name")}}
          <EuiAvatar @name={{cell.row.name}} @size="s" />
          {{cell.row.name}}
        {{else if (eq cell.columnId "reports")}}
          {{this.reportCount cell.row}}
        {{else}}
          {{get cell.row cell.columnId}}
        {{/if}}
      </:cell>
    </EuiDataGrid>
  </template>
}
```
