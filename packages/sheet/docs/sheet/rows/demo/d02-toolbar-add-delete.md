---
order: 2
---

# Add and delete from your own toolbar

<EuiText>

**Add inspection** calls `api.insertRecord({ values })` and adds a record at the end, in the site of the last one. **Delete checked** calls `api.deleteRecords(ids)` and is disabled until you check a row's box. The add row at the bottom of the grid uses `@newRecordValues` instead: it copies the site from the record above.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import {
  EuiButton,
  EuiFlexGroup,
  EuiFlexItem,
  EuiSpacer,
  EuiText
} from '@ember-eui/core/components';
import { EuiSheet, localRecords } from '@ember-eui/sheet';
import { inspections, SITES } from 'site/utils/sheet-docs-data';

const FIELDS = [
  { id: 'title', label: 'Inspection', required: true, width: 230 },
  {
    id: 'site',
    label: 'Site',
    type: 'singleSelect',
    options: SITES,
    width: 170
  },
  { id: 'date', label: 'Date', type: 'date', width: 130 },
  { id: 'findings', label: 'Findings', type: 'number', min: 0, width: 110 }
];

export default class SheetToolbarAddDelete extends Component {
  getId = (record) => record.id;
  store = localRecords(inspections(), {
    getRecordId: this.getId,
    fields: FIELDS
  });

  newRecordValues = ({ above }) => ({ site: above?.site ?? 'mty' });

  add = (sheet) => {
    const records = this.store.records;
    sheet.api.insertRecord({
      values: {
        title: 'New inspection',
        site: records[records.length - 1]?.site ?? 'mty',
        findings: 0
      }
    });
  };

  deleteChecked = (sheet) => {
    sheet.api.deleteRecords(sheet.checkedRecords.map(this.getId));
  };

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @newRecordValues={{this.newRecordValues}}
      @height={{300}}
      @ariaLabel='Inspections'
    >
      <:toolbar as |sheet|>
        <EuiFlexGroup
          @gutterSize='s'
          @alignItems='center'
          @responsive={{false}}
        >
          <EuiFlexItem @grow={{false}}>
            <EuiButton
              @size='s'
              @iconType='plusInCircle'
              {{on 'click' (fn this.add sheet)}}
            >Add inspection</EuiButton>
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiButton
              @size='s'
              @color='danger'
              @iconType='trash'
              @isDisabled={{if sheet.checkedRecords.length false true}}
              {{on 'click' (fn this.deleteChecked sheet)}}
            >Delete checked ({{sheet.checkedRecords.length}})</EuiButton>
          </EuiFlexItem>
        </EuiFlexGroup>
        <EuiSpacer @size='s' />
      </:toolbar>
    </EuiSheet>
  </template>
}
```
