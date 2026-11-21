---
order: 1
---

# The shortcut list

<EuiText>

The toolbar's **Keyboard shortcuts** button calls the block's
`showShortcuts()`; Ctrl/Cmd+/ on a cell, a row number or a header opens
the same list. It has every key of the table on this page, without the
ones this sheet turns off: it is `@readOnly` here when the switch is on,
so the editing, paste and insert keys leave the list. Escape closes it
and focus goes back to the cell.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { EuiButtonEmpty, EuiSwitch } from '@ember-eui/core/components';
import { EuiSheet, localRecords } from '@ember-eui/sheet';
import { employees } from 'site/utils/sheet-docs-data';

const FIELDS = [
  { id: 'name', label: 'Name', required: true },
  { id: 'role', label: 'Role' },
  { id: 'start', label: 'Start', type: 'date' },
  { id: 'certified', label: 'Certified', type: 'checkbox' }
];

export default class ShortcutList extends Component {
  getId = (record) => record.id;
  store = localRecords(employees(), {
    getRecordId: this.getId,
    fields: FIELDS
  });

  @tracked readOnly = false;

  toggle = (event) => (this.readOnly = event.target.checked);

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @readOnly={{this.readOnly}}
      @height={{220}}
      @ariaLabel='People'
    >
      <:toolbar as |sheet|>
        <EuiButtonEmpty
          @size='s'
          @iconType='keyboard'
          {{on 'click' sheet.showShortcuts}}
        >Keyboard shortcuts</EuiButtonEmpty>
        <EuiSwitch
          @label='Read-only'
          @checked={{this.readOnly}}
          @onChange={{this.toggle}}
        />
      </:toolbar>
    </EuiSheet>
  </template>
}
```
