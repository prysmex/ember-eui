---
order: 18
---

# Editing: fill handle, series, cut

<EuiText>

Sixty days of a work log, wider than the sheet. Select Day and Date of
rows 1 and 2 (they hold `1, 2` and two dates a week apart), then drag
the small square at the range's bottom-right corner down: the cells are
outlined while you drag, and the release continues both series (`3, 4,
…` and one week per row). Hold Ctrl or Alt (Option) at the release to
repeat the two rows instead; Escape during the drag cancels it. A single
date dragged down goes on by one day; a Status dragged down repeats.

Ctrl/Cmd+X cuts the range (Ctrl/Cmd+V puts it back elsewhere), Ctrl/Cmd+D
fills down and Ctrl/Cmd+R fills right. Ctrl/Cmd+arrows jump to the edge
of the data (the Notes column is empty from row 21: try Ctrl+ArrowDown
on it), with Shift they extend the range; Shift+End and Ctrl/Cmd+Shift+End
too; PageDown moves by a screen. Drag a selection down past the grid's
bottom edge and hold it: the grid scrolls and the range follows.

Click Reviewer, the last column, then click it again (or press Enter):
the grid scrolls it into view and its editor stays open. With a dead key
(`´` then `e`) or an IME, typing on a cell opens the editor with the
composed text.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import {
  EuiCodeBlock,
  EuiFlexGroup,
  EuiFlexItem,
  EuiTitle,
} from '@ember-eui/core/components';
import { EuiSheet, localRecords } from '@ember-eui/sheet';

const STATUS = [
  { value: 'todo', label: 'To do' },
  { value: 'doing', label: 'Doing', color: 'primary' },
  { value: 'done', label: 'Done', color: 'success' },
];

const FIELDS = [
  { id: 'day', label: 'Day', type: 'number', width: 90 },
  { id: 'date', label: 'Date', type: 'date', width: 130 },
  { id: 'hours', label: 'Hours', type: 'duration', width: 100 },
  { id: 'rate', label: 'Rate', type: 'currency', currency: 'USD', locale: 'en-US', width: 120 },
  { id: 'done', label: 'Done', type: 'percent', width: 100 },
  { id: 'status', label: 'Status', type: 'singleSelect', options: STATUS, width: 130 },
  { id: 'task', label: 'Task', width: 200 },
  { id: 'notes', label: 'Notes', width: 220 },
  { id: 'reviewer', label: 'Reviewer', width: 180 },
];

const RECORDS = Array.from({ length: 60 }, (_, i) => ({
  id: `log-${i + 1}`,
  day: i < 2 ? i + 1 : null,
  date: i === 0 ? '2026-01-05' : i === 1 ? '2026-01-12' : null,
  hours: i < 2 ? 3600 * (i + 1) : null,
  rate: i < 2 ? 40 + 5 * i : null,
  done: i < 2 ? 0.25 * (i + 1) : null,
  status: i < 2 ? ['todo', 'doing'][i] : null,
  task: ['Inspect', 'Report', 'Train', 'Audit'][i % 4],
  notes: i < 20 ? `Note ${i + 1}` : '',
  reviewer: ['Ana', 'Luis', 'Marta'][i % 3],
}));

export default class SheetEditing extends Component {
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
      : '// drag the fill handle, cut, or press Ctrl/Cmd+R';
  }

  <template>
    <EuiFlexGroup @gutterSize='l' @wrap={{true}}>
      <EuiFlexItem @grow={{2}} style='min-width: 0'>
        <EuiSheet
          @fields={{this.store.fields}}
          @records={{this.store.records}}
          @getRecordId={{this.getId}}
          @onChange={{this.onChange}}
          @height={{360}}
          @ariaLabel='Work log'
        />
      </EuiFlexItem>
      <EuiFlexItem @grow={{1}}>
        <EuiTitle @size='xxs'><h4>Last change sets</h4></EuiTitle>
        <EuiCodeBlock @language='json' @fontSize='s' @paddingSize='s' @overflowHeight={{360}}>{{this.log}}</EuiCodeBlock>
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```
