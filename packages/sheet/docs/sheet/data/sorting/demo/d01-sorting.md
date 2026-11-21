---
order: 1
---

# Sort a local array

<EuiText>

Open a column's menu and choose a sort (the sheet never sorts by itself). `@onSortChange` stores the keys, the component sorts a copy of the records with `compareValues` (each key in turn; `desc` reverses it) and passes `@sort` so the header draws the arrows. Edit a cell and the order follows.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import {
  EuiButtonEmpty,
  EuiFlexGroup,
  EuiFlexItem,
  EuiText
} from '@ember-eui/core/components';
import {
  EuiSheet,
  builtInFieldTypes,
  compareValues,
  localRecords
} from '@ember-eui/sheet';
import { inspections, SITES } from 'site/utils/sheet-docs-data';

const FIELDS = [
  { id: 'title', label: 'Inspection', width: 230 },
  {
    id: 'site',
    label: 'Site',
    type: 'singleSelect',
    options: SITES,
    width: 170
  },
  { id: 'date', label: 'Date', type: 'date', width: 130 },
  { id: 'score', label: 'Score', type: 'percent', min: 0, max: 1, width: 100 },
  { id: 'findings', label: 'Findings', type: 'number', min: 0, width: 110 }
];

export default class SheetSorting extends Component {
  getId = (record) => record.id;
  store = localRecords(inspections(), {
    getRecordId: this.getId,
    fields: FIELDS
  });

  @tracked sort = [];

  get sorted() {
    const keys = this.sort
      .map(({ field, direction }) => ({
        field: FIELDS.find((f) => f.id === field),
        id: field,
        direction
      }))
      .filter((key) => key.field);
    if (!keys.length) return this.store.records;
    return [...this.store.records].sort((a, b) => {
      for (const { field, id, direction } of keys) {
        const result = compareValues(builtInFieldTypes, field, a[id], b[id]);
        if (result !== 0) return direction === 'desc' ? -result : result;
      }
      return 0;
    });
  }

  get sortText() {
    return this.sort.length
      ? this.sort
          .map(({ field, direction }) => `${field} ${direction}`)
          .join(', ')
      : 'not sorted';
  }

  onSortChange = (sort) => {
    this.sort = sort;
  };

  clear = () => {
    this.sort = [];
  };

  <template>
    <EuiFlexGroup @gutterSize='s' @alignItems='center' @responsive={{false}}>
      <EuiFlexItem @grow={{false}}>
        <EuiText @size='s'><p>Sort:
            <strong>{{this.sortText}}</strong></p></EuiText>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiButtonEmpty @size='xs' {{on 'click' this.clear}}>Clear sort</EuiButtonEmpty>
      </EuiFlexItem>
    </EuiFlexGroup>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.sorted}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @sort={{this.sort}}
      @onSortChange={{this.onSortChange}}
      @height={{260}}
      @ariaLabel='Inspections, sortable'
    />
  </template>
}
```
