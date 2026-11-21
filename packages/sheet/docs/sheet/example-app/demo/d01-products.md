---
order: 1
---

# Products

<EuiText>

Scroll down to load more (the line under the grid counts them), turn on
"Group by category", edit a price, open a product (Space) to see its
edits, then "Import a supplier's file": the import screen maps the
supplier's columns, flags the price it can't read, and Import adds the
lines at the end (Ctrl/Cmd+Z removes them). "Export CSV" downloads every
product.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { isDestroying } from '@ember/destroyable';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import {
  EuiButtonEmpty,
  EuiFlexGroup,
  EuiFlexItem,
  EuiModal,
  EuiModalBody,
  EuiModalHeader,
  EuiModalHeaderTitle,
  EuiSwitch,
  EuiText
} from '@ember-eui/core/components';
import {
  EuiSheet,
  EuiSheetImport,
  builtInFieldTypes,
  defaultMessages,
  localRecords,
  toCsv
} from '@ember-eui/sheet';
import {
  FIELDS,
  SAMPLE_CSV,
  fetchProducts
} from 'site/utils/sheet-example-products';

const PAGE_SIZE = 50;
const BY_CATEGORY = [{ field: 'category', direction: 'asc' }];

function download(name, text) {
  // the BOM tells Excel the file is UTF-8 (accents)
  const blob = new Blob([String.fromCharCode(0xfeff) + text], {
    type: 'text/csv;charset=utf-8'
  });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = name;
  link.click();
  URL.revokeObjectURL(url);
}

// a value as the history shows it: a select's option by its label
function shown(value, field) {
  if (value === null || value === undefined || value === '') return '(empty)';
  return (
    field?.options?.find((option) => option.value === value)?.label ??
    String(value)
  );
}

export default class ProductsApp extends Component {
  getId = (product) => product.id;
  store = localRecords([], {
    getRecordId: this.getId,
    fields: FIELDS,
    summaries: { stock: 'sum' }
  });
  api = null;

  // loading more as you scroll: our own cursor, not @records.length
  @tracked fetched = 0;
  @tracked total = null;
  @tracked isLoading = false;
  loading = null;

  @tracked importSource = null; // { file } or { text, name }
  @tracked history = {}; // record id -> the edits of this session
  @tracked status = '';

  constructor(owner, args) {
    super(owner, args);
    this.loadMore();
  }

  registerApi = (api) => (this.api = api);

  get allLoaded() {
    return this.total !== null && this.fetched >= this.total;
  }

  get isGrouped() {
    return this.store.groupBy.length > 0;
  }

  loadMore() {
    this.loading ??= fetchProducts(this.fetched, PAGE_SIZE).then(
      ({ products, total }) => {
        if (isDestroying(this)) return;
        this.fetched += products.length;
        this.total = total;
        this.store.records = [...this.store.records, ...products];
        this.loading = null;
        this.isLoading = false;
      }
    );
    this.isLoading = true;
    return this.loading;
  }

  // grouping, exporting and importing need every product
  async loadAll() {
    while (!this.allLoaded && !isDestroying(this)) await this.loadMore();
  }

  onVisibleRangeChange = ({ last, count }) => {
    if (!this.allLoaded && last >= count - 20) this.loadMore();
  };

  onChange = (changeSet) => {
    this.store.apply(changeSet); // a real app also sends it to its server
    const history = { ...this.history };
    for (const { recordId, fieldId, from, to } of changeSet.patches) {
      const field = FIELDS.find((candidate) => candidate.id === fieldId);
      const line = `${field?.label ?? fieldId}: ${shown(from, field)} → ${shown(to, field)} (${changeSet.source})`;
      history[recordId] = [...(history[recordId] ?? []), line];
    }
    this.history = history;
  };

  setGroupBy = async (groupBy) => {
    if (groupBy.length) await this.loadAll();
    this.store.setGroupBy(groupBy);
  };

  toggleGrouping = (event) =>
    this.setGroupBy(event.target.checked ? BY_CATEGORY : []);

  exportCsv = async (sheet) => {
    await this.loadAll();
    const ctx = { types: builtInFieldTypes, messages: defaultMessages };
    download('products.csv', toCsv(ctx, this.store.records, sheet.fields));
    this.status = `Exported ${this.store.records.length} products.`;
  };

  pickFile = () => document.getElementById('sheetExampleAppFile')?.click();

  openImport = async (source) => {
    await this.loadAll();
    // imported lines go after the last record; grouped, they would take its group
    this.store.setGroupBy([]);
    this.importSource = source;
  };

  fileChosen = (event) => {
    const file = event.target.files?.[0];
    event.target.value = '';
    if (file) this.openImport({ file, name: file.name });
  };

  importSample = () =>
    this.openImport({ text: SAMPLE_CSV, name: 'supplier.csv' });

  closeImport = () => (this.importSource = null);

  import = (result) => {
    this.api?.appendRows(result.rows, result.fieldIds, {
      fields: result.fields
    });
    this.status = `${this.importSource.name}: ${result.rows.length} lines imported (Ctrl/Cmd+Z undoes them).`;
    this.closeImport();
  };

  get footerText() {
    const loaded =
      this.total === null
        ? 'Loading…'
        : `${this.fetched} of ${this.total} products loaded`;
    return this.status ? `${loaded}. ${this.status}` : `${loaded}.`;
  }

  historyOf = (record) => this.history[record.id] ?? [];

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.view.records}}
      @groups={{this.store.view.groups}}
      @groupBy={{this.store.groupBy}}
      @onGroupByChange={{this.setGroupBy}}
      @onGroupToggle={{this.store.toggleGroup}}
      @getRecordId={{this.getId}}
      @onChange={{this.onChange}}
      @onVisibleRangeChange={{this.onVisibleRangeChange}}
      @isLoading={{this.isLoading}}
      @canInsert={{this.allLoaded}}
      @registerApi={{this.registerApi}}
      @frozenFields={{1}}
      @height={{420}}
      @ariaLabel='Products'
    >
      <:toolbar as |sheet|>
        <EuiFlexGroup
          @gutterSize='m'
          @alignItems='center'
          @responsive={{false}}
          @wrap={{true}}
        >
          <EuiFlexItem @grow={{false}}>
            <EuiSwitch
              @label='Group by category'
              @checked={{this.isGrouped}}
              @onChange={{this.toggleGrouping}}
            />
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiButtonEmpty
              @size='s'
              @iconType='exportAction'
              {{on 'click' (fn this.exportCsv sheet)}}
            >Export CSV</EuiButtonEmpty>
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiButtonEmpty
              @size='s'
              @iconType='importAction'
              {{on 'click' this.pickFile}}
            >Import CSV…</EuiButtonEmpty>
            <input
              id='sheetExampleAppFile'
              type='file'
              accept='.csv,.tsv,.txt,text/csv'
              hidden
              {{on 'change' this.fileChosen}}
            />
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiButtonEmpty
              @size='s'
              @iconType='document'
              {{on 'click' this.importSample}}
            >Import a supplier's file</EuiButtonEmpty>
          </EuiFlexItem>
        </EuiFlexGroup>
      </:toolbar>
      <:footer>
        <EuiText @size='xs' @color='subdued'><p
          >{{this.footerText}}</p></EuiText>
      </:footer>
      <:recordFooter as |record|>
        <EuiText @size='s'>
          <h4>Edits in this session</h4>
          {{#each (this.historyOf record) as |line|}}
            <p>{{line}}</p>
          {{else}}
            <p>None yet: edit a field above, or a cell of this row.</p>
          {{/each}}
        </EuiText>
      </:recordFooter>
    </EuiSheet>
    {{#if this.importSource}}
      <EuiModal
        aria-labelledby='sheetExampleAppImportTitle'
        style='width: 1180px; max-width: calc(100vw - 32px)'
        @onClose={{this.closeImport}}
      >
        <EuiModalHeader>
          <EuiModalHeaderTitle id='sheetExampleAppImportTitle'>Import
            {{this.importSource.name}}</EuiModalHeaderTitle>
        </EuiModalHeader>
        <EuiModalBody>
          <EuiSheetImport
            @fields={{this.store.fields}}
            @file={{this.importSource.file}}
            @text={{this.importSource.text}}
            @onImport={{this.import}}
            @onCancel={{this.closeImport}}
          />
        </EuiModalBody>
      </EuiModal>
    {{/if}}
  </template>
}
```
