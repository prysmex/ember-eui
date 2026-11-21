---
order: 3
---

# Another date picker

<EuiText>

The date type's editor is the browser's date input. To use another
picker, keep the date type and replace its editor:
`{ ...dateType, editor: FlatpickrDateEditor }` under the name `date`.
The value stays an ISO date, so parsing, display, copy and paste are
the date type's. This editor uses `@ember-eui/flatpickr`: Enter, F2 or
a double-click opens the calendar, and a digit still opens the text
input (`SheetInputEditor`). flatpickr puts its calendar at the end of
`<body>`, so the editor marks it with the class `euiSheetEditorSurface`:
focus moving there does not close the editor.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiSheet, SheetInputEditor, dateType, localRecords } from '@ember-eui/sheet';
import EuiFlatpickr from '@ember-eui/flatpickr/components/eui-flatpickr';

class FlatpickrDateEditor extends Component {
  get date() {
    return this.args.value ?? null;
  }

  get label() {
    return this.args.field.label ?? this.args.field.id;
  }

  // the calendar is outside the sheet: mark it as part of the editor, and
  // open it (flatpickr is set up after the editor is inserted)
  onReady = (_dates, _text, instance) => {
    const calendar = instance.calendarContainer;
    calendar.classList.add('euiSheetEditorSurface');
    instance.open();
  };

  // the editor focuses itself when inserted
  focus = (input) => input.focus();

  pick = (_dates, iso) => this.args.onCommit({ value: iso || null });

  <template>
    {{#if @initialKey}}
      {{! typing a digit: the text input, parsed by the date type }}
      <SheetInputEditor
        @value={{@value}}
        @field={{@field}}
        @record={{@record}}
        @draft={{@draft}}
        @initialKey={{@initialKey}}
        @onDraftChange={{@onDraftChange}}
        @onCommit={{@onCommit}}
        @onCancel={{@onCancel}}
        @messages={{@messages}}
        @themeClass={{@themeClass}}
      />
    {{else}}
      <EuiFlatpickr
        @date={{this.date}}
        @dateFormat='Y-m-d'
        @ariaLabel={{this.label}}
        @compressed={{true}}
        @inputRef={{this.focus}}
        @onReady={{this.onReady}}
        @onChange={{this.pick}}
      />
    {{/if}}
  </template>
}

const FIELDS = [
  { id: 'task', label: 'Task' },
  { id: 'due', label: 'Due', type: 'date' },
  { id: 'done', label: 'Done on', type: 'date' },
];

const RECORDS = [
  { id: 'd1', task: 'Fire drill', due: '2026-11-24', done: null },
  { id: 'd2', task: 'Audit stairs', due: '2026-12-03', done: '2026-11-18' },
  { id: 'd3', task: 'Renew permits', due: null, done: null },
];

export default class SheetDatePicker extends Component {
  fieldTypes = { date: { ...dateType, editor: FlatpickrDateEditor } };
  getId = (record) => record.id;
  store = localRecords(RECORDS, { getRecordId: this.getId });

  <template>
    <EuiSheet
      @fields={{FIELDS}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @fieldTypes={{this.fieldTypes}}
      @height={{200}}
      @ariaLabel='Tasks'
    />
  </template>
}
```
