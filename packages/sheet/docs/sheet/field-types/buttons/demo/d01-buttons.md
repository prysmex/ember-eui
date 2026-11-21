---
order: 1
---

# Start and escalate an inspection

<EuiText>

Two `button` fields, one handler. `@onButtonPress` gets the record and
the field's id, and routes by it. **Start** has a label per record
(`buttonLabel(record)`: "Start" or "Resume") and is disabled on closed
inspections (`disabled(record)`); its press takes 700 ms and sets the
status, through your own data, not a change set (a press is not undoable).
**Escalate** is red (`color: 'danger'`) and fails for inspections
without an inspector: the cell shows the error until the next press.
While a press runs the cell shows a spinner and ignores more presses.
Enter or Space on a selected button cell presses it too.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { applyChangeSet, EuiSheet } from '@ember-eui/sheet';
import { inspections, STATUSES, wait } from 'site/utils/sheet-docs-data';

const FIELDS = [
  { id: 'title', label: 'Inspection', width: 220 },
  { id: 'status', label: 'Status', type: 'singleSelect', options: STATUSES },
  {
    id: 'start',
    label: 'Start',
    type: 'button',
    icon: 'play',
    buttonLabel: (record) =>
      record.status === 'progress' ? 'Resume' : 'Start',
    disabled: (record) => record.status === 'closed'
  },
  {
    id: 'escalate',
    label: 'Escalate',
    type: 'button',
    icon: 'bell',
    color: 'danger',
    buttonLabel: 'Escalate'
  }
];

export default class Buttons extends Component {
  getId = (record) => record.id;

  @tracked records = inspections();
  @tracked message = 'Press a button.';

  onChange = (changeSet) => {
    this.records = applyChangeSet(this.records, changeSet, {
      getRecordId: this.getId
    });
  };

  onButtonPress = async ({ recordId, fieldId, record }, { signal }) => {
    await wait(700, signal);
    if (fieldId === 'start') {
      this.records = this.records.map((r) =>
        r.id === recordId ? { ...r, status: 'progress' } : r
      );
      this.message = `Started "${record.title}".`;
    } else if (!record.inspector) {
      throw new Error('No inspector to notify');
    } else {
      this.message = `Escalated "${record.title}" to ${record.inspector.label}'s manager.`;
    }
  };

  <template>
    <EuiSheet
      @fields={{FIELDS}}
      @records={{this.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.onChange}}
      @onButtonPress={{this.onButtonPress}}
      @height={{270}}
      @ariaLabel='Inspections'
    />
    <p>{{this.message}}</p>
  </template>
}
```
