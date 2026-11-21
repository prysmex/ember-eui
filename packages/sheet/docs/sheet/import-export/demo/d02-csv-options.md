---
order: 2
---

# CSV export options

<EuiText>

`toCsv(ctx, records, fields, options)` takes `delimiter` (`';'` for
Excel in locales with a decimal comma), `headers` (`false` leaves out the
first line) and `escapeFormulas` (on by default: a cell like `=SUM(A1)`
gets a leading `'`). The fields are your choice: add the view's hidden
fields to export them too. Toggle the switches and read the text below;
the **Score note** cell of Guard rails starts with `=`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import {
  EuiCodeBlock,
  EuiFlexGroup,
  EuiFlexItem,
  EuiSpacer,
  EuiSwitch
} from '@ember-eui/core/components';
import {
  EuiSheet,
  builtInFieldTypes,
  defaultMessages,
  localRecords,
  toCsv
} from '@ember-eui/sheet';
import { inspections, SITES, STATUSES } from 'site/utils/sheet-docs-data';

const VISIBLE = [
  { id: 'title', label: 'Inspection', width: 200 },
  {
    id: 'site',
    label: 'Site',
    type: 'singleSelect',
    options: SITES,
    width: 150
  },
  { id: 'date', label: 'Date', type: 'date', width: 110 },
  { id: 'score', label: 'Score', type: 'number', width: 90 },
  {
    id: 'status',
    label: 'Status',
    type: 'singleSelect',
    options: STATUSES,
    width: 110
  }
];

// not shown in the view, but part of the sheet's fields
const HIDDEN = [
  { id: 'area', label: 'Area', width: 120 },
  { id: 'note', label: 'Score note', width: 160 }
];

const RECORDS = inspections().map((record) => ({
  ...record,
  note: record.id === 'ins-106' ? '=HYPERLINK("http://example.com")' : ''
}));

export default class SheetCsvOptions extends Component {
  getId = (record) => record.id;
  store = localRecords(RECORDS, {
    getRecordId: this.getId,
    fields: [...VISIBLE, ...HIDDEN]
  });

  @tracked semicolon = false;
  @tracked headers = true;
  @tracked escape = true;
  @tracked hidden = false;

  toggle = (name, event) => {
    this[name] = event.target.checked;
  };
  toggleSemicolon = (event) => this.toggle('semicolon', event);
  toggleHeaders = (event) => this.toggle('headers', event);
  toggleEscape = (event) => this.toggle('escape', event);
  toggleHidden = (event) => this.toggle('hidden', event);

  get csv() {
    const ctx = { types: builtInFieldTypes, messages: defaultMessages };
    const fields = this.hidden ? [...VISIBLE, ...HIDDEN] : VISIBLE;
    return toCsv(ctx, this.store.records, fields, {
      delimiter: this.semicolon ? ';' : ',',
      headers: this.headers,
      escapeFormulas: this.escape
    });
  }

  <template>
    <EuiSheet
      @fields={{VISIBLE}}
      @hiddenFields={{HIDDEN}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @height={{240}}
      @ariaLabel='Inspections'
    />
    <EuiSpacer @size='m' />
    <EuiFlexGroup @gutterSize='m' @responsive={{false}} @wrap={{true}}>
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch
          @label="delimiter: ';'"
          @checked={{this.semicolon}}
          @onChange={{this.toggleSemicolon}}
          @compressed={{true}}
        />
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch
          @label='headers'
          @checked={{this.headers}}
          @onChange={{this.toggleHeaders}}
          @compressed={{true}}
        />
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch
          @label='escapeFormulas'
          @checked={{this.escape}}
          @onChange={{this.toggleEscape}}
          @compressed={{true}}
        />
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch
          @label='include the hidden fields'
          @checked={{this.hidden}}
          @onChange={{this.toggleHidden}}
          @compressed={{true}}
        />
      </EuiFlexItem>
    </EuiFlexGroup>
    <EuiSpacer @size='s' />
    <EuiCodeBlock
      @language='csv'
      @paddingSize='s'
      @isCopyable={{true}}
    >{{this.csv}}</EuiCodeBlock>
  </template>
}
```
