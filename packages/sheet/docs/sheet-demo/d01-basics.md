---
order: 1
---

# Basics

<EuiText>

Twenty records in a `localRecords` store. Edit a few cells, select a
range with Shift+arrows or by dragging the mouse and press Delete, or
copy a block from Excel or Google Sheets and paste it on a cell: rows
past the end become new records. Ctrl/Cmd+D fills a range down from its
top row (or a cell from the one above), and pasting one cell into a range
fills the whole range. Ctrl/Cmd+Z undoes any of these and Ctrl/Cmd+Shift+Z
redoes it. The panel shows the last change sets, with their `source`
(`edit`, `paste`, `clear`, `fill`, `undo`, `redo`), `patches`, `inserts`,
`deletes` (an undone paste's new rows) and `rejected` texts (paste `abc`
on Hours).

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiCodeBlock, EuiFlexGroup, EuiFlexItem, EuiTitle } from '@ember-eui/core/components';
import { EuiSheet, localRecords } from '@ember-eui/sheet';

const FIELDS = [
  { id: 'name', label: 'Name', required: true },
  { id: 'city', label: 'City' },
  { id: 'hours', label: 'Hours', type: 'number', min: 0 },
  { id: 'active', label: 'Active', type: 'checkbox' },
];

const NAMES = ['Ana', 'Bruno', 'Carla', 'Diego', 'Elena', 'Félix', 'Gabriela', 'Héctor', 'Inés', 'Jorge'];
const CITIES = ['Monterrey', 'Madrid', 'Lima', 'Bogotá', 'Quito'];

const RECORDS = Array.from({ length: 20 }, (_, i) => ({
  id: `p${i + 1}`,
  name: `${NAMES[i % NAMES.length]} ${i + 1}`,
  city: CITIES[i % CITIES.length],
  hours: (i * 7) % 40,
  active: i % 3 !== 0,
}));

export default class SheetBasics extends Component {
  getId = (record) => record.id;
  store = localRecords(RECORDS, { getRecordId: this.getId, fields: FIELDS });

  @tracked changeSets = [];

  onChange = (changeSet) => {
    this.store.apply(changeSet);
    this.changeSets = [changeSet, ...this.changeSets].slice(0, 3);
  };

  get log() {
    return this.changeSets.length
      ? JSON.stringify(this.changeSets, null, 2)
      : '// edit, clear or paste a cell';
  }

  <template>
    <EuiFlexGroup @gutterSize='l' @wrap={{true}}>
      <EuiFlexItem @grow={{2}}>
        <EuiSheet
          @fields={{this.store.fields}}
          @records={{this.store.records}}
          @getRecordId={{this.getId}}
          @onChange={{this.onChange}}
          @height={{360}}
          @ariaLabel='People'
        />
      </EuiFlexItem>
      <EuiFlexItem @grow={{1}}>
        <EuiTitle @size='xxs'><h4>Last change sets ({{this.store.records.length}} records)</h4></EuiTitle>
        <EuiCodeBlock @language='json' @fontSize='s' @paddingSize='s' @overflowHeight={{330}}>{{this.log}}</EuiCodeBlock>
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```
