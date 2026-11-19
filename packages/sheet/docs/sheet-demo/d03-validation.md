---
order: 3
---

# Validation

<EuiText>

`@validate` gets every record, the cells written since its last run and
an `AbortSignal`. It may return its errors or a promise of them. This
one has a record rule (End must not be before Start), a cross-row rule
(each email once) and a fake server check that takes 800 ms (the
domains `mailinator.com` and `example.org` are blocked). The sheet runs
it on the first render and after each change; a newer run aborts the
older one, and a late result of an older run is discarded. Edit two
cells quickly and watch the runs list.

**Save** stands in for your API: it answers with errors for names that
start with "Test", passed as `@cellErrors`, which are shown after the
other messages. Hover a red cell to read its messages.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { EuiButton, EuiButtonEmpty, EuiFlexGroup, EuiFlexItem, EuiSpacer, EuiText } from '@ember-eui/core/components';
import { EuiSheet, localRecords } from '@ember-eui/sheet';

const FIELDS = [
  { id: 'name', label: 'Name', required: true },
  { id: 'email', label: 'Email', pattern: /^[^@\s]+@[^@\s]+$/, patternMessage: 'Not an email' },
  { id: 'start', label: 'Start', type: 'date' },
  { id: 'end', label: 'End', type: 'date' },
];

const RECORDS = [
  { id: 'v1', name: 'Ana Ruiz', email: 'ana@prysmex.com', start: '2026-11-03', end: '2026-11-07' },
  { id: 'v2', name: 'Bruno Vela', email: 'bruno@mailinator.com', start: '2026-11-10', end: '2026-11-08' },
  { id: 'v3', name: 'Carla Soto', email: 'carla@prysmex.com', start: '2026-11-12', end: null },
  { id: 'v4', name: 'Test user', email: 'ana@prysmex.com', start: null, end: null },
  { id: 'v5', name: 'Diego Paz', email: 'diego@example.org', start: '2026-12-01', end: '2026-12-02' },
];

const BLOCKED = ['mailinator.com', 'example.org'];

/** A fake API: the blocked emails, after 800 ms. It rejects when the signal aborts. */
function checkEmails(emails, signal) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      resolve(emails.filter((email) => BLOCKED.includes(email.split('@')[1]?.toLowerCase())));
    }, 800);
    signal.addEventListener('abort', () => {
      clearTimeout(timer);
      reject(new DOMException('Aborted', 'AbortError'));
    });
  });
}

function addError(errors, id, fieldId, message) {
  const record = (errors[id] ??= {});
  record[fieldId] = [...(record[fieldId] ?? []), message];
}

export default class SheetValidation extends Component {
  getId = (record) => record.id;
  store = localRecords(RECORDS, { getRecordId: this.getId, fields: FIELDS });

  @tracked runs = [];
  @tracked cellErrors = {};
  runCount = 0;

  setRun(number, state) {
    const others = this.runs.filter((run) => run.number !== number);
    this.runs = [{ number, state }, ...others].sort((a, b) => b.number - a.number).slice(0, 5);
  }

  validate = async ({ records, changed, signal }) => {
    const number = ++this.runCount;
    this.setRun(number, `checking (${changed.length} changed cells)`);
    const errors = {};

    // a record rule
    for (const record of records) {
      if (record.start && record.end && record.end < record.start) {
        addError(errors, record.id, 'end', 'Must not be before the start date');
      }
    }

    // a cross-row rule
    const byEmail = new Map();
    for (const record of records) {
      const email = record.email?.trim().toLowerCase();
      if (email) byEmail.set(email, [...(byEmail.get(email) ?? []), record.id]);
    }
    for (const ids of byEmail.values()) {
      if (ids.length > 1) for (const id of ids) addError(errors, id, 'email', 'Used by another row');
    }

    // a server rule
    let blocked;
    try {
      blocked = await checkEmails(records.map((record) => record.email ?? ''), signal);
    } catch (error) {
      this.setRun(number, 'discarded: a newer run started');
      throw error;
    }
    for (const record of records) {
      if (blocked.includes(record.email)) addError(errors, record.id, 'email', 'This domain is blocked');
    }
    this.setRun(number, 'applied');
    return errors;
  };

  save = () => {
    const errors = {};
    for (const record of this.store.records) {
      if (/^test/i.test(record.name ?? '')) {
        errors[record.id] = { name: 'The server does not save test names' };
      }
    }
    this.cellErrors = errors;
  };

  clearCellErrors = () => {
    this.cellErrors = {};
  };

  <template>
    <EuiFlexGroup @gutterSize='l' @wrap={{true}}>
      <EuiFlexItem @grow={{2}}>
        <EuiSheet
          @fields={{this.store.fields}}
          @records={{this.store.records}}
          @getRecordId={{this.getId}}
          @onChange={{this.store.apply}}
          @validate={{this.validate}}
          @cellErrors={{this.cellErrors}}
          @height={{240}}
          @ariaLabel='Team'
        />
        <EuiSpacer @size='s' />
        <EuiFlexGroup @gutterSize='s' @responsive={{false}}>
          <EuiFlexItem @grow={{false}}>
            <EuiButton @size='s' {{on 'click' this.save}}>Save</EuiButton>
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiButtonEmpty @size='s' {{on 'click' this.clearCellErrors}}>Clear server errors</EuiButtonEmpty>
          </EuiFlexItem>
        </EuiFlexGroup>
      </EuiFlexItem>
      <EuiFlexItem @grow={{1}}>
        <EuiText @size='s'>
          <h4>@validate runs</h4>
          <ul>
            {{#each this.runs as |run|}}
              <li>#{{run.number}}: {{run.state}}</li>
            {{/each}}
          </ul>
        </EuiText>
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```
