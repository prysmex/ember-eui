---
order: 1
---

# Fields from the grid

<EuiText>

The owner owns the fields; here a `localRecords` store does the work, so
its `createField`, `updateField` and `deleteField` are passed as
`@onFieldCreate`, `@onFieldUpdate` and `@onFieldDelete`. Each handler
shows its own controls:

- The **"+"** at the right of the headers (or ArrowRight from the last
  header, then Enter) opens the field editor to add a field at the end:
  a name, a type, the type's options (a select's options and colours, a
  currency's code), a description and Required.
- A column's **menu** has Edit field, Duplicate field (with its values:
  the store copies them), Insert left, Insert right and Delete field,
  which asks first. "Name" is the first field: nothing goes to its left
  and it cannot be deleted. "Id" has `manageable: false` (a system field):
  no Edit, Duplicate or Delete.

**Changing a type converts the values** here, because the store applies
`convertField`: each value goes through the paste path (the old type's
copy text, then the new type's `parse`). What could be pasted converts
(`12` in a text field becomes the number 12; `Lima` becomes the option
"Lima" of a select that has it); what could not is cleared and listed in
the change set's `rejected`, shown on the right. Try Hours → Single line
text → Number, or City → Single select: add an option "Lima" in the
editor before saving, and only the other cities are lost. The sheet itself changes no value: without
`convertField`, the cells would show the stored values through the new
type.

Field changes are not undoable from the sheet (Ctrl/Cmd+Z undoes cell
edits only); after a delete, the deleted field's edits are dropped from
the history.

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
  {
    id: 'status',
    label: 'Status',
    type: 'singleSelect',
    options: [
      { value: 'open', label: 'Open', color: 'success' },
      { value: 'closed', label: 'Closed', color: 'danger' },
    ],
  },
  { id: 'id', label: 'Id', readOnly: true, manageable: false },
];

const CITIES = ['Monterrey', 'Madrid', 'Lima', 'Bogotá'];

const RECORDS = Array.from({ length: 8 }, (_, i) => ({
  id: `p${i + 1}`,
  name: ['Ana', 'Bruno', 'Carla', 'Diego'][i % 4] + ` ${i + 1}`,
  city: CITIES[i % CITIES.length],
  hours: (i * 7) % 40,
  status: i % 3 === 0 ? 'closed' : 'open',
}));

export default class SheetFields extends Component {
  getId = (record) => record.id;
  store = localRecords(RECORDS, { getRecordId: this.getId, fields: FIELDS });

  @tracked log = [];

  note(entry) {
    this.log = [entry, ...this.log].slice(0, 6);
  }

  createField = (draft, position) => {
    this.store.createField(draft, position);
    this.note({ intent: 'create', draft, position });
  };

  updateField = (fieldId, draft, context) => {
    const before = this.store.log.length;
    this.store.updateField(fieldId, draft, context);
    const converted = this.store.log.slice(before)[0];
    this.note({
      intent: 'update',
      fieldId,
      draft,
      ...(converted
        ? { converted: converted.patches.length, rejected: converted.rejected.map(({ recordId, text, message }) => ({ recordId, text, message })) }
        : {}),
    });
  };

  deleteField = (fieldId) => {
    this.store.deleteField(fieldId);
    this.note({ intent: 'delete', fieldId });
  };

  get text() {
    return this.log.length ? JSON.stringify(this.log, null, 2) : '// add, edit or delete a field';
  }

  <template>
    <EuiFlexGroup @gutterSize='l' @wrap={{true}}>
      <EuiFlexItem @grow={{2}}>
        <EuiSheet
          @fields={{this.store.fields}}
          @records={{this.store.records}}
          @getRecordId={{this.getId}}
          @onChange={{this.store.apply}}
          @onFieldCreate={{this.createField}}
          @onFieldUpdate={{this.updateField}}
          @onFieldDelete={{this.deleteField}}
          @height={{340}}
          @ariaLabel='People'
        />
      </EuiFlexItem>
      <EuiFlexItem @grow={{1}}>
        <EuiTitle @size='xxs'><h4>Field intents</h4></EuiTitle>
        <EuiCodeBlock @language='json' @fontSize='s' @paddingSize='s' @overflowHeight={{310}}>{{this.text}}</EuiCodeBlock>
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```
