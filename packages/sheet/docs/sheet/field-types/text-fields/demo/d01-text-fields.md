---
order: 1
---

# Findings and their notes

<EuiText>

**Finding** is `text` (the default type) with `maxLength: 60`;
**Action** is `text` with a `pattern` (it must start with a verb from a
list) and its own message; **Notes** is `longText`. The rows are two
lines high (`@rowHeight='medium'`), so a note shows its first lines.
Enter on a Notes cell opens a text area that grows with its lines:
Shift+Enter or Alt+Enter adds a line, Enter saves. Copy a Notes cell
and paste it in a text editor: a text with line breaks is copied in
quotes, as Excel does, and pastes back as one cell.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiSheet, localRecords } from '@ember-eui/sheet';

const FIELDS = [
  {
    id: 'finding',
    label: 'Finding',
    required: true,
    maxLength: 60,
    width: 220
  },
  {
    id: 'action',
    label: 'Action',
    pattern: /^(Replace|Repair|Train|Remove|Label|Clean)\b/,
    patternMessage: 'Start with Replace, Repair, Train, Remove, Label or Clean',
    width: 220
  },
  { id: 'notes', label: 'Notes', type: 'longText', maxLength: 500, width: 300 }
];

const FINDINGS = [
  {
    id: 'f1',
    finding: 'Extinguisher B-4 pressure low',
    action: 'Replace the cartridge',
    notes: 'Gauge in the red zone.\nLast service: March 2026.'
  },
  {
    id: 'f2',
    finding: 'Exit sign out, stair 2',
    action: 'Repair the light',
    notes: 'Reported by the night shift.'
  },
  {
    id: 'f3',
    finding: 'Oil on the floor near press 4',
    action: 'clean it up',
    notes:
      'Leak from the hydraulic hose.\nArea taped off.\nMaintenance notified.'
  },
  {
    id: 'f4',
    finding:
      'Missing guard on the belt conveyor at the end of line 3, next to the loading area',
    action: 'Train',
    notes: ''
  }
];

export default class TextFields extends Component {
  getId = (record) => record.id;
  store = localRecords(FINDINGS, { getRecordId: this.getId, fields: FIELDS });

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @rowHeight='medium'
      @height={{260}}
      @ariaLabel='Findings'
    />
  </template>
}
```
