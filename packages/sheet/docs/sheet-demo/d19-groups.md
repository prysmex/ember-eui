---
order: 19
---

# Group by

<EuiText>

A `localRecords` store groups its records: `store.view` gives
`@records` and `@groups`, and its `setGroupBy` and `toggleGroup` are the
sheet's `@onGroupByChange` and `@onGroupToggle`. Pick a field, add a
second level, collapse a group with its chevron (or Enter on its header),
and add a record from a group's add row: it gets the group's values.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import {
  EuiButtonEmpty,
  EuiButtonGroup,
  EuiFlexGroup,
  EuiFlexItem,
  EuiSwitch,
} from '@ember-eui/core/components';
import { EuiSheet, localRecords } from '@ember-eui/sheet';

const FIELDS = [
  { id: 'name', label: 'Name', required: true },
  {
    id: 'status',
    label: 'Status',
    type: 'singleSelect',
    options: [
      { value: 'todo', label: 'To do', color: 'default' },
      { value: 'doing', label: 'Doing', color: 'primary' },
      { value: 'done', label: 'Done', color: 'success' },
    ],
  },
  { id: 'city', label: 'City' },
  { id: 'hours', label: 'Hours', type: 'number', min: 0 },
];

const CITIES = ['Monterrey', 'Madrid', 'Lima'];
const STATUSES = ['todo', 'doing', 'done', 'doing'];

const RECORDS = Array.from({ length: 14 }, (_, i) => ({
  id: `t${i + 1}`,
  name: ['Ana', 'Bruno', 'Carla', 'Diego', 'Elena'][i % 5] + ` ${i + 1}`,
  status: i === 13 ? null : STATUSES[i % STATUSES.length],
  city: CITIES[(i * 2) % CITIES.length],
  hours: (i * 7) % 24,
}));

export default class SheetGroups extends Component {
  getId = (record) => record.id;
  store = localRecords(RECORDS, {
    getRecordId: this.getId,
    fields: FIELDS,
    groupBy: [{ field: 'status', direction: 'asc' }],
    summaries: { hours: 'sum' },
  });

  fieldOptions = [
    { id: 'none', label: 'None' },
    { id: 'status', label: 'Status' },
    { id: 'city', label: 'City' },
  ];

  get field() {
    return this.store.groupBy[0]?.field ?? 'none';
  }

  get secondLevel() {
    return this.store.groupBy.length > 1;
  }

  /** The other field, as the second level. */
  get secondField() {
    return this.field === 'city' ? 'status' : 'city';
  }

  levels(field, second) {
    if (field === 'none') return [];
    const levels = [{ field, direction: 'asc' }];
    if (second) {
      levels.push({ field: field === 'city' ? 'status' : 'city', direction: 'asc' });
    }
    return levels;
  }

  setField = (field) => {
    this.store.setGroupBy(this.levels(field, this.secondLevel));
  };

  toggleSecond = (event) => {
    this.store.setGroupBy(this.levels(this.field, event.target.checked));
  };

  /** Collapses every outermost group (their children with them). */
  collapseAll = () => {
    const keys = this.store.view.groups
      .filter((group) => group.depth === 0)
      .map((group) => group.key);
    this.store.collapsedGroups = new Set(keys);
  };

  expandAll = () => {
    this.store.collapsedGroups = new Set();
  };

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.view.records}}
      @groups={{this.store.view.groups}}
      @groupBy={{this.store.groupBy}}
      @onGroupByChange={{this.store.setGroupBy}}
      @onGroupToggle={{this.store.toggleGroup}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @height={{420}}
      @ariaLabel='Tasks'
    >
      <:toolbar>
        <EuiFlexGroup @gutterSize='m' @alignItems='center' @wrap={{true}} @responsive={{false}}>
          <EuiFlexItem @grow={{false}}>
            <EuiButtonGroup
              @legend='Group by'
              @options={{this.fieldOptions}}
              @idSelected={{this.field}}
              @onChange={{this.setField}}
              @buttonSize='compressed'
            />
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiSwitch
              @label='Then by {{this.secondField}}'
              @checked={{this.secondLevel}}
              @disabled={{if this.store.groupBy.length false true}}
              @compressed={{true}}
              @onChange={{this.toggleSecond}}
            />
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiButtonEmpty @size='s' @iconType='arrowRight' {{on 'click' this.collapseAll}}>
              Collapse all
            </EuiButtonEmpty>
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiButtonEmpty @size='s' @iconType='arrowDown' {{on 'click' this.expandAll}}>
              Expand all
            </EuiButtonEmpty>
          </EuiFlexItem>
        </EuiFlexGroup>
      </:toolbar>
    </EuiSheet>
  </template>
}
```
