---
order: 1
---

# Inspectors and reviewers

<EuiText>

**Inspector** is a `user` field with a known list (`options`): its
picker lists them, and a pasted name or email (`carla@prysmex.com`) is
matched at once. **Reviewers** has `multiple: true` and no list: its
picker asks `search(query, { signal })`, a fake directory that answers
after 300 ms, and a pick toggles a person, as in a multi-select. Text
typed or pasted there (`Ana Ruiz, Diego Paz`) needs the directory too,
so it goes to `@onResolve`: the cells show as pending, then the names
found arrive as one more change set (one Ctrl/Cmd+Z undoes both). A
cell with a name the directory does not know (`Ana Ruiz, Zoe`) is
rejected as a whole.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiSheet, localRecords } from '@ember-eui/sheet';
import { inspections, INSPECTORS, wait } from 'site/utils/sheet-docs-data';

/** A fake directory of people. */
async function findPeople(query, signal) {
  await wait(300, signal);
  const text = query.trim().toLowerCase();
  return INSPECTORS.filter(
    (user) =>
      user.label.toLowerCase().includes(text) || user.email.startsWith(text)
  );
}

const FIELDS = [
  { id: 'title', label: 'Inspection', width: 220 },
  {
    id: 'inspector',
    label: 'Inspector',
    type: 'user',
    options: INSPECTORS,
    width: 170
  },
  {
    id: 'reviewers',
    label: 'Reviewers',
    type: 'user',
    multiple: true,
    search: (query, { signal }) => findPeople(query, signal),
    width: 240
  }
];

export default class Users extends Component {
  getId = (record) => record.id;
  store = localRecords(
    inspections().map((record, index) => ({
      ...record,
      reviewers: index % 2 ? [INSPECTORS[3]] : []
    })),
    { getRecordId: this.getId, fields: FIELDS }
  );

  /** One request per field: each text to the person of that name, or null. */
  onResolve = async (requests, { signal }) => {
    const result = {};
    for (const { fieldId, texts } of requests) {
      result[fieldId] = {};
      for (const text of texts) {
        const [person] = (await findPeople(text, signal)).filter(
          (user) => user.label.toLowerCase() === text.trim().toLowerCase()
        );
        result[fieldId][text] = person ?? null;
      }
    }
    return result;
  };

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @onResolve={{this.onResolve}}
      @height={{260}}
      @ariaLabel='Inspections'
    />
  </template>
}
```
