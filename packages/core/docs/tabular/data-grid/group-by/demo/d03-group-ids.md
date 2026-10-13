---
order: 3
---

# Controlling groups by id

<EuiText>

The expanded groups are controlled. The buttons build ids with the
`group:` + JSON format, and the list shows what `onExpandedChange`
reports.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { array, get, hash } from '@ember/helper';
import { on } from '@ember/modifier';
import {
  EuiButton,
  EuiCode,
  EuiDataGrid,
  EuiFlexGroup,
  EuiFlexItem,
  EuiSpacer,
  EuiText,
} from '@ember-eui/core/components';

const groupId = (...values) => `group:${JSON.stringify(values)}`;

export default class GroupIdsDemo extends Component {
  @tracked expandedGroupIds = [];

  columns = [
    { id: 'office', displayAsText: 'Office', initialWidth: 260 },
    { id: 'country', displayAsText: 'Country' },
    { id: 'city', displayAsText: 'City' }
  ];

  offices = [
    { office: 'Opéra', country: 'France', city: 'Paris' },
    { office: 'La Défense', country: 'France', city: 'Paris' },
    { office: 'Part-Dieu', country: 'France', city: 'Lyon' },
    { office: 'San Pedro', country: 'Mexico', city: 'Monterrey' },
    { office: 'Polanco', country: 'Mexico', city: 'Mexico City' }
  ];

  get label() {
    return this.expandedGroupIds.length ? this.expandedGroupIds.join('  ') : '(none)';
  }

  @action onExpandedChange(ids) {
    this.expandedGroupIds = ids;
  }

  @action openParis() {
    this.expandedGroupIds = [groupId('France'), groupId('France', 'Paris')];
  }

  @action closeAll() {
    this.expandedGroupIds = [];
  }

  <template>
    <EuiFlexGroup @gutterSize="s" @responsive={{false}} @wrap={{true}}>
      <EuiFlexItem @grow={{false}}>
        <EuiButton @size="s" {{on "click" this.openParis}}>Open France › Paris</EuiButton>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiButton @size="s" {{on "click" this.closeAll}}>Close all</EuiButton>
      </EuiFlexItem>
    </EuiFlexGroup>
    <EuiSpacer @size="s" />
    <EuiText @size="s"><p>expandedGroupIds: <EuiCode>{{this.label}}</EuiCode></p></EuiText>
    <EuiSpacer @size="s" />
    <EuiDataGrid
      aria-label="Controlled groups"
      @columns={{this.columns}}
      @grouping={{hash
        groupBy=(array "country" "city")
        rows=this.offices
        expandedGroupIds=this.expandedGroupIds
        onExpandedChange=this.onExpandedChange
      }}
      @toolbarVisibility={{false}}
      @height={{300}}
    >
      <:cell as |cell|>{{get cell.row cell.columnId}}</:cell>
    </EuiDataGrid>
  </template>
}
```
