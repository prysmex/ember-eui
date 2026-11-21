---
order: 27
---

# Cell colours

<EuiText>

`@cellColor={{this.cellColor}}` returns a colour per cell, drawn as a
3 px bar along the cell's bottom edge. Here a due date before today on a
task that is not done is `'danger'`, more hours spent than estimated is
`'warning'`, and a done task's name is `'success'`. The rule is the
app's; the sheet only draws the colour. Tick Done on an overdue task, or
change its date, and the bar goes.

An overdue task with no owner also gets an error (`@cellErrors`): the
red border and the bar show together. The first field is frozen: scroll
sideways and its bar stays. The bar is drawn at every row height.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiButtonGroup, EuiFlexGroup, EuiFlexItem, EuiText } from '@ember-eui/core/components';
import { EuiSheet, localRecords } from '@ember-eui/sheet';

/** A local date `offset` days from today, as `YYYY-MM-DD`. */
function isoDay(offset) {
  const day = new Date();
  day.setDate(day.getDate() + offset);
  const pad = (n) => String(n).padStart(2, '0');
  return `${day.getFullYear()}-${pad(day.getMonth() + 1)}-${pad(day.getDate())}`;
}

const TODAY = isoDay(0);

const FIELDS = [
  { id: 'name', label: 'Task', required: true, width: 200 },
  { id: 'due', label: 'Due', type: 'date', width: 130 },
  { id: 'done', label: 'Done', type: 'checkbox', width: 80 },
  { id: 'estimate', label: 'Estimate (h)', type: 'number', min: 0, width: 120 },
  { id: 'spent', label: 'Spent (h)', type: 'number', min: 0, width: 110 },
  { id: 'owner', label: 'Owner', width: 120 },
  { id: 'notes', label: 'Notes', type: 'longText', width: 260 },
];

const TASKS = [
  ['Write the brief', -6, true, 4, 3, 'Ana', 'Sent to the client'],
  ['Book the venue', -3, false, 2, 5, 'Bruno', 'Waiting for a quote'],
  ['Order the badges', -1, false, 1, 0, '', ''],
  ['Call the caterer', 0, false, 1, 1, 'Carla', ''],
  ['Print the menus', 2, false, 3, 1, 'Ana', ''],
  ['Test the sound', 5, false, 2, 3, 'Bruno', 'Bring the spare cables'],
  ['Send the invites', -10, true, 2, 2, 'Carla', ''],
  ['Plan the seating', -2, false, 3, 1, '', 'Needs the final list'],
  ['Pick the music', 8, false, 1, 2, 'Ana', ''],
  ['Pay the deposit', 1, false, 1, 0, 'Carla', ''],
];

const RECORDS = TASKS.map(([name, due, done, estimate, spent, owner, notes], i) => ({
  id: `t${i + 1}`,
  name,
  due: isoDay(due),
  done,
  estimate,
  spent,
  owner,
  notes,
}));

const HEIGHTS = [
  { id: 'short', label: 'Short' },
  { id: 'medium', label: 'Medium' },
  { id: 'tall', label: 'Tall' },
  { id: 'extraTall', label: 'Extra tall' },
];

const isOverdue = (task) => !task.done && !!task.due && task.due < TODAY;

export default class SheetCellColor extends Component {
  heights = HEIGHTS;
  getId = (record) => record.id;
  store = localRecords(RECORDS, { getRecordId: this.getId, fields: FIELDS });
  @tracked rowHeight = 'short';

  // called for each rendered cell: cheap, and only this record's values
  cellColor = (task, field) => {
    if (field.id === 'due') return isOverdue(task) ? 'danger' : undefined;
    if (field.id === 'spent') return task.spent > task.estimate ? 'warning' : undefined;
    if (field.id === 'name') return task.done ? 'success' : undefined;
    return undefined;
  };

  get cellErrors() {
    const errors = {};
    for (const task of this.store.records) {
      if (isOverdue(task) && !task.owner) errors[task.id] = { due: 'Overdue, and nobody owns it' };
    }
    return errors;
  }

  setRowHeight = (rowHeight) => {
    this.rowHeight = rowHeight;
  };

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @cellColor={{this.cellColor}}
      @cellErrors={{this.cellErrors}}
      @rowHeight={{this.rowHeight}}
      @onRowHeightChange={{this.setRowHeight}}
      @frozenFields={{1}}
      @height={{420}}
      @ariaLabel='Tasks with due dates'
    >
      <:toolbar>
        <EuiFlexGroup @gutterSize='m' @alignItems='center' @responsive={{false}}>
          <EuiFlexItem @grow={{false}}>
            <EuiButtonGroup
              @legend='Row height'
              @options={{this.heights}}
              @idSelected={{this.rowHeight}}
              @onChange={{this.setRowHeight}}
              @buttonSize='compressed'
              data-test-subj='cellColorRowHeight'
            />
          </EuiFlexItem>
          <EuiFlexItem>
            <EuiText @size='xs' @color='subdued'>
              Today is {{TODAY}}.
            </EuiText>
          </EuiFlexItem>
        </EuiFlexGroup>
      </:toolbar>
    </EuiSheet>
  </template>
}
```

<EuiText>

The colour has no text: a screen reader does not hear it, and the
cell's label does not change. Put the meaning in a field too (here the
date itself, and the error), or in `@cellErrors`.

</EuiText>
