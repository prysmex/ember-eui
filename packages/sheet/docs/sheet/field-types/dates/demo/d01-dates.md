---
order: 1
---

# Incident dates and times

<EuiText>

**Date** is a `date` (stored `2026-11-19`, shown day first); **Date
(US)** the same values with `dateOrder: 'mdy'`, so `11/19/2026` is read
and shown month first. **Due** has a range (`min`, `max`: in December
2026). **Reported** is a `dateTime` in the plant's zone
(`timeZone: 'America/Monterrey'`, a 12-hour clock), and **Reported
(UTC)** starts with the same instants, shown in UTC with seconds. Type
`19/11/2026 3:30 pm` in the last Reported cell (3:30 pm in Monterrey)
and copy it: the clipboard has the instant, `2026-11-19T21:30:00.000Z`;
paste it on the last Reported (UTC) cell and it shows `19/11/2026
21:30:00`, the same moment in the other zone. On a date cell a digit opens a
text input and Enter the browser's date picker. Select Due of rows 1
and 2 and drag the fill handle down: a week apart, they go on weekly.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiSheet, localRecords } from '@ember-eui/sheet';

const FIELDS = [
  { id: 'incident', label: 'Incident', required: true, width: 200 },
  { id: 'date', label: 'Date', type: 'date' },
  { id: 'dateUs', label: 'Date (US)', type: 'date', dateOrder: 'mdy' },
  {
    id: 'due',
    label: 'Due',
    type: 'date',
    min: '2026-12-01',
    max: '2026-12-31'
  },
  {
    id: 'reported',
    label: 'Reported',
    type: 'dateTime',
    timeZone: 'America/Monterrey',
    hour12: true,
    width: 190
  },
  {
    id: 'reportedUtc',
    label: 'Reported (UTC)',
    type: 'dateTime',
    timeZone: 'utc',
    seconds: true,
    width: 190
  }
];

const INCIDENTS = [
  {
    incident: 'Slip near dock 2',
    date: '2026-11-03',
    due: '2026-12-01',
    reported: '2026-11-03T14:05:00.000Z'
  },
  {
    incident: 'Forklift near miss',
    date: '2026-11-09',
    due: '2026-12-08',
    reported: '2026-11-09T21:40:30.000Z'
  },
  {
    incident: 'Chemical splash, store 1',
    date: '2026-11-14',
    due: '2026-11-28',
    reported: '2026-11-14T16:00:00.000Z'
  },
  { incident: 'Cut on a guard edge', date: null, due: null, reported: null }
].map((incident, index) => ({
  id: `inc-${index + 1}`,
  ...incident,
  dateUs: incident.date,
  reportedUtc: incident.reported
}));

export default class Dates extends Component {
  getId = (record) => record.id;
  store = localRecords(INCIDENTS, { getRecordId: this.getId, fields: FIELDS });

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @height={{230}}
      @ariaLabel='Incidents'
    />
  </template>
}
```
