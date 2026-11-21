/**
 * EuiSheetSearch passes on every `EuiSheet` argument and block
 * (READINESS.md item 5, SA1-SA4). SA1 reads the inner sheet's arguments
 * from Ember's debug render tree: every name in `SHEET_ARG_NAMES` (kept
 * next to `EuiSheetSignature`, which `lint:types` holds it to) must be
 * among them, so an argument added to the sheet and not to the connector
 * fails here.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { captureRenderTree } from '@ember/debug';
import { render, settled } from '@ember/test-helpers';
import { SearchDriver, memoryBackend } from 'ember-search-ui-driver';

import {
  SHEET_ARG_NAMES,
  SHEET_BLOCK_NAMES
} from '#src/-private/sheet-arg-names.ts';
import { applyChangeSet, defaultMessages } from '#src/core/index.ts';
import { EuiSheetSearch } from '#src/search-ui/index.ts';
import { text } from '../../helpers/sheet.ts';

import type { ChangeSet, EuiSheetField } from '#src/core/index.ts';
import type { SheetApi } from '#src/types.ts';

interface Doc {
  id: string;
  name: string;
  qty: number;
}

const FIELDS: EuiSheetField<Doc>[] = [
  { id: 'name', label: 'Name' },
  { id: 'qty', label: 'Qty', type: 'number' }
];

const SCHEMA = {
  name: { path: 'name', type: 'text', label: 'Name' },
  qty: { path: 'qty', type: 'number', label: 'Qty' }
};

const getId = (doc: Doc) => doc.id;

class Store {
  @tracked docs: Doc[];
  constructor(docs: Doc[]) {
    this.docs = docs;
  }
  write = (changeSet: ChangeSet): void => {
    this.docs = applyChangeSet(this.docs, changeSet, { getRecordId: getId });
  };
}

/** The arguments the search provides or the connector replaces (`SheetSearchOwnedArg` in the connector). */
const OWNED = [
  'fields',
  'records',
  'getRecordId',
  'onChange',
  'sort',
  'onSortChange',
  'highlight',
  'isLoading',
  'rowNumberOffset',
  'groups'
];

/** A value for each argument the connector passes on (a function each its own), safe to render with. */
const VALUES = {
  cellErrors: {},
  height: 300,
  fieldTypes: {},
  readOnly: false,
  messages: {},
  ariaLabel: 'Results',
  validate: () => ({}),
  hiddenFields: [],
  onHiddenFieldsChange: () => {},
  onFieldOrderChange: () => {},
  fieldDrag: true,
  headerLines: 1 as const,
  onFieldCreate: () => {},
  onFieldUpdate: () => {},
  onFieldDelete: () => {},
  creatableFieldTypes: ['text'],
  fieldWidths: {},
  onFieldWidthChange: () => {},
  rowHeight: 'short' as const,
  onRowHeightChange: () => {},
  onFilterByField: () => {},
  currentMatch: null,
  onSelectionChange: () => {},
  onVisibleRangeChange: () => {},
  fullScreen: false,
  onFullScreenChange: () => {},
  summary: {},
  frozenFields: 0,
  rowNumbers: true,
  rowLabel: (_doc: Doc, position: number) => String(position),
  groupBy: [],
  onGroupByChange: () => {},
  onGroupToggle: () => {},
  canInsert: true,
  canDelete: true,
  canMove: false,
  rowColor: () => undefined,
  cellColor: () => undefined,
  onButtonPress: () => {},
  newRecordValues: () => ({}),
  checkedRecordIds: [],
  onCheckedChange: () => {},
  expandedRecordId: null,
  onExpandedRecordChange: () => {},
  expandedRecord: 'flyout' as const,
  rowActions: [],
  fieldActions: [],
  copyWithFieldNames: true,
  onResolve: () => Promise.resolve({}),
  editIn: 'cell' as const
};

type CapturedRenderNode = ReturnType<typeof captureRenderTree>[number];

function findNode(
  nodes: CapturedRenderNode[],
  name: string
): CapturedRenderNode | undefined {
  for (const node of nodes) {
    if (node.type === 'component' && node.name === name) return node;
    const found = findNode(node.children, name);
    if (found) return found;
  }
  return undefined;
}

module('Integration | Component | EuiSheetSearch arguments', function (hooks) {
  setupRenderingTest(hooks);

  let drivers: SearchDriver<Doc>[] = [];
  hooks.afterEach(function () {
    drivers.forEach((driver) => driver.destroy());
    drivers = [];
  });

  function setup(count: number) {
    const store = new Store(
      Array.from({ length: count }, (_, i) => ({
        id: `d${i + 1}`,
        name: `name${i + 1}`,
        qty: i + 1
      }))
    );
    const driver = new SearchDriver<Doc>({
      backend: memoryBackend(() => store.docs, { searchFields: ['name'] }),
      schema: SCHEMA,
      initialState: {
        sort: [],
        page: { kind: 'offset', page: 1, perPage: 50 }
      }
    });
    drivers.push(driver);
    return { store, driver };
  }

  test('SA1 every EuiSheet argument reaches the sheet; the passed-on ones as they are', async function (assert) {
    const { store, driver } = setup(3);
    let api: SheetApi | null = null;
    const registerApi = (given: SheetApi) => (api = given);
    const v = VALUES;
    await render(
      <template>
        <EuiSheetSearch
          @driver={{driver}}
          @getRecordId={{getId}}
          @onChange={{store.write}}
          @fields={{FIELDS}}
          @registerApi={{registerApi}}
          @cellErrors={{v.cellErrors}}
          @height={{v.height}}
          @fieldTypes={{v.fieldTypes}}
          @readOnly={{v.readOnly}}
          @messages={{v.messages}}
          @ariaLabel={{v.ariaLabel}}
          @validate={{v.validate}}
          @hiddenFields={{v.hiddenFields}}
          @onHiddenFieldsChange={{v.onHiddenFieldsChange}}
          @onFieldOrderChange={{v.onFieldOrderChange}}
          @fieldDrag={{v.fieldDrag}}
          @headerLines={{v.headerLines}}
          @onFieldCreate={{v.onFieldCreate}}
          @onFieldUpdate={{v.onFieldUpdate}}
          @onFieldDelete={{v.onFieldDelete}}
          @creatableFieldTypes={{v.creatableFieldTypes}}
          @fieldWidths={{v.fieldWidths}}
          @onFieldWidthChange={{v.onFieldWidthChange}}
          @rowHeight={{v.rowHeight}}
          @onRowHeightChange={{v.onRowHeightChange}}
          @onFilterByField={{v.onFilterByField}}
          @currentMatch={{v.currentMatch}}
          @onSelectionChange={{v.onSelectionChange}}
          @onVisibleRangeChange={{v.onVisibleRangeChange}}
          @fullScreen={{v.fullScreen}}
          @onFullScreenChange={{v.onFullScreenChange}}
          @summary={{v.summary}}
          @frozenFields={{v.frozenFields}}
          @rowNumbers={{v.rowNumbers}}
          @rowLabel={{v.rowLabel}}
          @groupBy={{v.groupBy}}
          @onGroupByChange={{v.onGroupByChange}}
          @onGroupToggle={{v.onGroupToggle}}
          @canInsert={{v.canInsert}}
          @canDelete={{v.canDelete}}
          @canMove={{v.canMove}}
          @rowColor={{v.rowColor}}
          @cellColor={{v.cellColor}}
          @onButtonPress={{v.onButtonPress}}
          @newRecordValues={{v.newRecordValues}}
          @checkedRecordIds={{v.checkedRecordIds}}
          @onCheckedChange={{v.onCheckedChange}}
          @expandedRecordId={{v.expandedRecordId}}
          @onExpandedRecordChange={{v.onExpandedRecordChange}}
          @expandedRecord={{v.expandedRecord}}
          @rowActions={{v.rowActions}}
          @fieldActions={{v.fieldActions}}
          @copyWithFieldNames={{v.copyWithFieldNames}}
          @onResolve={{v.onResolve}}
          @editIn={{v.editIn}}
        />
      </template>
    );
    assert.strictEqual(text(0, 0), 'name1', 'it renders');
    const sheet = findNode(captureRenderTree(this.owner), 'EuiSheet');
    assert.ok(sheet, 'the inner EuiSheet is in the render tree');
    const named = sheet!.args.named;
    const missing = SHEET_ARG_NAMES.filter((name) => !(name in named));
    assert.deepEqual(missing, [], 'every EuiSheet argument is passed');
    const passed = SHEET_ARG_NAMES.filter((name) => !OWNED.includes(name));
    const values: Record<string, unknown> = { ...VALUES, registerApi };
    assert.deepEqual(
      passed.filter((name) => !(name in values)),
      ['fieldEditor'],
      'the test gives every passed-on argument a value but the editor component'
    );
    for (const name of passed) {
      if (!(name in values)) continue;
      assert.strictEqual(named[name], values[name], `@${name} as it is`);
    }
    assert.ok(api, '@registerApi was called');
  });

  test('SA2 the blocks: every named block of EuiSheet is one the connector has', function (assert) {
    // the connector's blocks: toolbar and footer (after its own controls),
    // empty and recordFooter (SA3, SA4)
    assert.deepEqual(
      [...SHEET_BLOCK_NAMES].sort(),
      ['empty', 'footer', 'recordFooter', 'toolbar'],
      'a new EuiSheet block must be passed on (and added here)'
    );
  });

  test('SA3 <:empty>: passed on; without it the sheet’s own "No records"', async function (assert) {
    const { store, driver } = setup(0);
    await render(
      <template>
        <EuiSheetSearch
          @driver={{driver}}
          @getRecordId={{getId}}
          @onChange={{store.write}}
          @fields={{FIELDS}}
        />
      </template>
    );
    assert
      .dom('[data-test-subj=euiSheetEmpty] [role=status]')
      .hasText(defaultMessages.noRecords());
    await render(
      <template>
        <EuiSheetSearch
          @driver={{driver}}
          @getRecordId={{getId}}
          @onChange={{store.write}}
          @fields={{FIELDS}}
        >
          <:empty as |sheet|>
            <span data-test-app-empty>Nothing for "{{sheet.search.term}}" ({{sheet.fields.length}}
              fields)</span>
          </:empty>
        </EuiSheetSearch>
      </template>
    );
    assert
      .dom('[data-test-subj=euiSheetEmpty] [data-test-app-empty]')
      .hasText('Nothing for "" (2 fields)', 'the block, with the search');
    assert.dom('[data-test-subj=euiSheetEmpty] [role=status]').doesNotExist();
  });

  test('SA4 <:recordFooter>: passed on with the record; without it no footer', async function (assert) {
    const { store, driver } = setup(2);
    let api: SheetApi | null = null;
    const registerApi = (given: SheetApi) => (api = given);
    await render(
      <template>
        <EuiSheetSearch
          @driver={{driver}}
          @getRecordId={{getId}}
          @onChange={{store.write}}
          @fields={{FIELDS}}
          @registerApi={{registerApi}}
        />
      </template>
    );
    api!.expandRecord('d1');
    await settled();
    assert
      .dom('[data-test-subj=euiSheetRecord]', document.body)
      .exists('the record is open');
    assert
      .dom('[data-test-subj=euiSheetRecordFooter]', document.body)
      .doesNotExist('no footer without the block');
    api = null;
    await render(
      <template>
        <EuiSheetSearch
          @driver={{driver}}
          @getRecordId={{getId}}
          @onChange={{store.write}}
          @fields={{FIELDS}}
          @registerApi={{registerApi}}
        >
          <:recordFooter as |doc sheet|>
            <span data-test-app-footer>{{doc.name}}
              of
              {{sheet.search.total}}</span>
          </:recordFooter>
        </EuiSheetSearch>
      </template>
    );
    api!.expandRecord('d2');
    await settled();
    assert
      .dom(
        '[data-test-subj=euiSheetRecordFooter] [data-test-app-footer]',
        document.body
      )
      .hasText('name2 of 2', 'the record and the search');
  });
});
