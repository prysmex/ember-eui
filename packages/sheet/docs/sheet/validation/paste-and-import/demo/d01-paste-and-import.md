---
order: 1
---

# A file with lines that cannot be read

<EuiText>

**Append the contractor's lines** reads the CSV below with `parseCsv`,
matches its header to the fields with `importMatrix` and adds the lines
with `api.appendRows`, the path a paste on the add row takes. Each text
goes through its field's type: what it reads is stored and validated
like an edit (the score of 130% is stored and marked); what it cannot
read (`n/a` as a score, `31/02/2026`, `maybe` for a checkbox, a site
that is not an option) is not stored, is listed in the change set's
`rejected` (the table) and stays on its cell, marked, until the cell is
written again. **Undo** (`api.undo()`, or Ctrl/Cmd+Z) removes the whole
import, rejections included. A paste on the add row (tab-separated lines,
from a spreadsheet) takes the same path.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import {
  EuiBasicTable,
  EuiButton,
  EuiButtonEmpty,
  EuiCodeBlock,
  EuiFlexGroup,
  EuiFlexItem,
  EuiSpacer
} from '@ember-eui/core/components';
import {
  EuiSheet,
  importMatrix,
  localRecords,
  parseCsv
} from '@ember-eui/sheet';
import { inspections, SITES } from 'site/utils/sheet-docs-data';

const FIELDS = [
  { id: 'title', label: 'Title', required: true, width: 220 },
  {
    id: 'site',
    label: 'Site',
    type: 'singleSelect',
    options: SITES,
    width: 170
  },
  { id: 'date', label: 'Date', type: 'date' },
  { id: 'score', label: 'Score', type: 'percent', min: 0, max: 1 },
  { id: 'passed', label: 'Passed', type: 'checkbox' }
];

const CSV = `Title,Site,Date,Score,Passed
Ladders and scaffolds,Monterrey plant,24/11/2026,95%,yes
Eye wash stations,San Luis warehouse,31/02/2026,n/a,no
Electrical panels,Saltillo depot,25/11/2026,130%,maybe
First aid kits,Querétaro line,26/11/2026,88%,x`;

const COLUMNS = [
  { field: 'field', name: 'Field' },
  { field: 'text', name: 'Text' },
  { field: 'message', name: 'Why' }
];

export default class PasteAndImport extends Component {
  getId = (record) => record.id;
  store = localRecords(inspections().slice(0, 3), {
    getRecordId: this.getId,
    fields: FIELDS
  });
  csv = CSV;

  @tracked rejected = [];
  api;

  registerApi = (api) => (this.api = api);

  onChange = (changeSet) => {
    this.store.apply(changeSet);
    if (changeSet.source === 'paste') {
      this.rejected = changeSet.rejected.map(({ fieldId, text, message }) => ({
        field: FIELDS.find((field) => field.id === fieldId)?.label,
        text,
        message
      }));
    }
  };

  append = () => {
    const { rows, fieldIds } = importMatrix(parseCsv(CSV), FIELDS);
    this.api.appendRows(rows, fieldIds);
  };

  undo = () => this.api.undo();

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.onChange}}
      @registerApi={{this.registerApi}}
      @height={{260}}
      @ariaLabel='Inspections'
    />
    <EuiSpacer @size='s' />
    <EuiFlexGroup @gutterSize='s' @responsive={{false}}>
      <EuiFlexItem @grow={{false}}>
        <EuiButton @size='s' {{on 'click' this.append}}>Append the contractor's
          lines</EuiButton>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiButtonEmpty
          @size='s'
          @iconType='editorUndo'
          {{on 'click' this.undo}}
        >Undo</EuiButtonEmpty>
      </EuiFlexItem>
    </EuiFlexGroup>
    <EuiSpacer @size='s' />
    <EuiCodeBlock
      @fontSize='s'
      @paddingSize='s'
      @isCopyable={{true}}
    >{{this.csv}}</EuiCodeBlock>
    <EuiSpacer @size='s' />
    <EuiBasicTable
      @tableCaption='Rejected texts'
      @items={{this.rejected}}
      @columns={{COLUMNS}}
      @noItemsMessage='No rejected texts yet'
    />
  </template>
}
```
