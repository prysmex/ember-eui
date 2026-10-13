---
order: 2
---

# Controlled and persisted expansion

<EuiText>

The expanded ids are owned by the demo and saved to `localStorage`. Expand
a few rows and reload the page: they stay expanded.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { get, hash } from '@ember/helper';
import { EuiCode, EuiDataGrid, EuiSpacer, EuiText } from '@ember-eui/core/components';

const KEY = 'ember-eui-docs:tree-expansion';

function load() {
  try {
    return JSON.parse(window.localStorage.getItem(KEY)) ?? ['emea'];
  } catch {
    return ['emea'];
  }
}

export default class ControlledDemo extends Component {
  @tracked expandedRowIds = load();

  columns = [
    { id: 'name', displayAsText: 'Region' },
    { id: 'revenue', displayAsText: 'Revenue (k$)', schema: 'numeric' }
  ];

  regions = [
    {
      id: 'emea',
      name: 'EMEA',
      revenue: 820,
      children: [
        { id: 'emea-fr', name: 'France', revenue: 300, children: [{ id: 'emea-fr-paris', name: 'Paris', revenue: 300 }] },
        { id: 'emea-de', name: 'Germany', revenue: 520 }
      ]
    },
    {
      id: 'amer',
      name: 'Americas',
      revenue: 940,
      children: [
        { id: 'amer-mx', name: 'Mexico', revenue: 410 },
        { id: 'amer-us', name: 'United States', revenue: 530 }
      ]
    }
  ];

  get expandedLabel() {
    return this.expandedRowIds.length ? this.expandedRowIds.join(', ') : '(none)';
  }

  @action onExpandedChange(ids) {
    this.expandedRowIds = ids;
    try {
      window.localStorage.setItem(KEY, JSON.stringify(ids));
    } catch {
      // storage unavailable (private mode): keep the state in memory
    }
  }

  <template>
    <EuiText @size="s">
      <p>Expanded: <EuiCode>{{this.expandedLabel}}</EuiCode></p>
    </EuiText>
    <EuiSpacer @size="s" />
    <EuiDataGrid
      aria-label="Controlled expansion"
      @columns={{this.columns}}
      @rowTree={{hash
        rows=this.regions
        expandedRowIds=this.expandedRowIds
        onExpandedChange=this.onExpandedChange
      }}
      @toolbarVisibility={{false}}
      @height={{280}}
    >
      <:cell as |cell|>{{get cell.row cell.columnId}}</:cell>
    </EuiDataGrid>
  </template>
}
```
