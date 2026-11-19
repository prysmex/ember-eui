---
order: 9
---

# Your own store, server ids

<EuiText>

A store that applies change sets itself, like one backed by an API. Pasted
rows get a `tempId` at once; 300 ms later the "server" answers with its own
ids, and the store tells the sheet with `api.remapIds({ [tempId]: id })`
(the API comes from `@registerApi`) before it shows the new ids. Undo still
finds those rows: paste three lines on the last row, wait for the ids to
change, then press Ctrl/Cmd+Z: the rows the server created are removed.
Ctrl/Cmd+Shift+Z puts them back (and the server gives them new ids again).
The buttons call the same API from outside the sheet.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import {
  EuiButton,
  EuiCodeBlock,
  EuiFlexGroup,
  EuiFlexItem,
  EuiSpacer,
  EuiTitle,
} from '@ember-eui/core/components';
import { EuiSheet, applyChangeSet } from '@ember-eui/sheet';

const FIELDS = [
  { id: 'id', label: 'Id', readOnly: true },
  { id: 'item', label: 'Item', required: true },
  { id: 'qty', label: 'Qty', type: 'number', min: 0 },
];

let nextServerId = 101;

export default class SheetOwnStore extends Component {
  @tracked records = [
    { id: 'srv-1', item: 'Helmet', qty: 4 },
    { id: 'srv-2', item: 'Gloves', qty: 10 },
    { id: 'srv-3', item: 'Goggles', qty: 6 },
  ];
  @tracked events = [];
  api = null;
  timers = [];

  getId = (record) => record.id;
  registerApi = (api) => (this.api = api);

  onChange = (changeSet) => {
    this.records = applyChangeSet(this.records, changeSet, {
      getRecordId: this.getId,
    });
    this.note(`${changeSet.source}: ${changeSet.patches.length} cells, ${changeSet.inserts.length} inserts, ${changeSet.deletes?.length ?? 0} deletes`);
    const created = changeSet.inserts.map((insert) => insert.tempId);
    if (created.length) {
      this.timers.push(setTimeout(() => this.saved(created), 300));
    }
  };

  // the server's answer: its own ids for the rows it created
  saved(tempIds) {
    if (this.isDestroying || this.isDestroyed) return;
    const ids = {};
    for (const tempId of tempIds) {
      // undone in the meantime: nothing to rename
      if (this.records.some((record) => record.id === tempId)) {
        ids[tempId] = `srv-${nextServerId++}`;
      }
    }
    if (!Object.keys(ids).length) return;
    // first the sheet, then the records that carry the new ids
    this.api?.remapIds(ids);
    this.records = this.records.map((record) =>
      ids[record.id] ? { ...record, id: ids[record.id] } : record,
    );
    this.note(`server ids: ${Object.entries(ids).map(([from, to]) => `${from} → ${to}`).join(', ')}`);
  }

  note(text) {
    this.events = [text, ...this.events].slice(0, 8);
  }

  undo = () => this.api?.undo();
  redo = () => this.api?.redo();
  focusLast = () => {
    const last = this.records[this.records.length - 1];
    if (last) this.api?.focusCell({ recordId: last.id, fieldId: 'item' });
  };
  clearHistory = () => {
    this.api?.clearHistory();
    this.note('history cleared');
  };

  willDestroy() {
    super.willDestroy();
    this.timers.forEach(clearTimeout);
  }

  get log() {
    return this.events.length ? this.events.join('\n') : '// paste a few lines on the last row';
  }

  <template>
    <EuiFlexGroup @gutterSize='l' @wrap={{true}}>
      <EuiFlexItem @grow={{2}}>
        <EuiFlexGroup @gutterSize='s' @responsive={{false}} @wrap={{true}}>
          <EuiFlexItem @grow={{false}}><EuiButton @size='s' {{on 'click' this.undo}}>Undo</EuiButton></EuiFlexItem>
          <EuiFlexItem @grow={{false}}><EuiButton @size='s' {{on 'click' this.redo}}>Redo</EuiButton></EuiFlexItem>
          <EuiFlexItem @grow={{false}}><EuiButton @size='s' {{on 'click' this.focusLast}}>Focus last row</EuiButton></EuiFlexItem>
          <EuiFlexItem @grow={{false}}><EuiButton @size='s' @color='text' {{on 'click' this.clearHistory}}>Clear history</EuiButton></EuiFlexItem>
        </EuiFlexGroup>
        <EuiSpacer @size='s' />
        <EuiSheet
          @fields={{FIELDS}}
          @records={{this.records}}
          @getRecordId={{this.getId}}
          @onChange={{this.onChange}}
          @registerApi={{this.registerApi}}
          @height={{300}}
          @ariaLabel='Stock'
        />
      </EuiFlexItem>
      <EuiFlexItem @grow={{1}}>
        <EuiTitle @size='xxs'><h4>Store ({{this.records.length}} records)</h4></EuiTitle>
        <EuiCodeBlock @fontSize='s' @paddingSize='s' @overflowHeight={{300}}>{{this.log}}</EuiCodeBlock>
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```
