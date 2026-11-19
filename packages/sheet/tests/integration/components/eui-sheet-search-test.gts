/**
 * EuiSheetSearch (V02-DESIGN.md 7.4, SS1–SS9): the sheet as an EmberSearchUi
 * results view, on a real `SearchDriver` with `memoryBackend` over a tracked
 * store that `@onChange` writes.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { click, fillIn, render, settled, waitUntil } from '@ember/test-helpers';
import { SearchDriver, memoryBackend } from 'ember-search-ui-driver';

import { applyChangeSet } from '#src/core/index.ts';
import { EuiSheetSearch } from '#src/search-ui/index.ts';
import {
  cell,
  clipboard,
  editor,
  el,
  focusCell,
  press,
  pressed,
  selected,
  text,
  type
} from '../../helpers/sheet.ts';

import type { ChangeSet, EuiSheetField } from '#src/core/index.ts';
import type { SheetSearchBlockApi } from '#src/search-ui/index.ts';

interface Doc {
  id: string;
  name: string;
  city: string;
  qty: number;
}

const NAMES = ['Ana', 'Beto', 'Caro', 'Dani', 'Eva', 'Fito', 'Gus'];
const CITIES = ['Monterrey', 'Madrid', 'Lima', 'Bogotá'];

const makeDocs = (count: number): Doc[] =>
  Array.from({ length: count }, (_, i) => ({
    id: `d${i + 1}`,
    name: NAMES[i % NAMES.length]!,
    city: CITIES[i % CITIES.length]!,
    qty: i + 1
  }));

const FIELDS: EuiSheetField<Doc>[] = [
  { id: 'name', label: 'Name' },
  { id: 'city', label: 'City' },
  { id: 'qty', label: 'Qty', type: 'number' }
];

const SCHEMA = {
  name: { path: 'name', type: 'text', label: 'Name' },
  city: { path: 'city', type: 'keyword', label: 'City' },
  qty: { path: 'qty', type: 'number', label: 'Qty' }
};

const getId = (doc: Doc) => doc.id;

class Store {
  @tracked docs: Doc[];
  changes: ChangeSet[] = [];
  constructor(docs: Doc[]) {
    this.docs = docs;
  }
  write = (changeSet: ChangeSet): void => {
    this.changes.push(changeSet);
    this.docs = applyChangeSet(this.docs, changeSet, { getRecordId: getId });
  };
}

function setup(
  count: number,
  options: {
    perPage?: number;
    sort?: { field: string; direction: 'asc' | 'desc' }[];
    latencyMs?: number;
  } = {}
): { store: Store; driver: SearchDriver<Doc> } {
  const store = new Store(makeDocs(count));
  const driver = new SearchDriver<Doc>({
    backend: memoryBackend(() => store.docs, {
      ...(options.latencyMs ? { latencyMs: options.latencyMs } : {}),
      searchFields: ['name', 'city']
    }),
    schema: SCHEMA,
    initialState: {
      sort: options.sort ?? [],
      page: { kind: 'offset', page: 1, perPage: options.perPage ?? 50 }
    }
  });
  return { store, driver };
}

/** Opens a column's header menu and clicks an item. */
async function pickFromMenu(fieldId: string, label: string): Promise<void> {
  await click(el(`[data-test-subj=dataGridHeaderCellActionButton-${fieldId}]`));
  await waitUntil(() =>
    document.querySelector(
      `[data-test-subj=dataGridHeaderCellActionGroup-${fieldId}]`
    )
  );
  const item = Array.from(
    document.querySelectorAll<HTMLElement>(
      `[data-test-subj=dataGridHeaderCellActionGroup-${fieldId}] button`
    )
  ).find((button) => button.textContent?.trim() === label);
  if (!item) throw new Error(`No "${label}" in ${fieldId}'s menu`);
  await click(item);
}

const column = (col: number, rows: number) =>
  Array.from({ length: rows }, (_, row) => text(row, col));

const rowLabel = (row: number) =>
  document
    .querySelector(
      `[role=gridcell][data-gridcell-visible-row-index="${row}"][data-gridcell-column-index="0"] .euiSheet__rowLabel`
    )
    ?.textContent?.trim();

const reapplyButton = () =>
  document.querySelector<HTMLElement>('[data-test-subj=euiSheetSearchReapply]');

async function editName(row: number, value: string): Promise<void> {
  await focusCell(row, 0);
  await type('z');
  await fillIn(editor()!, value);
  await press('Enter');
}

module('Integration | Component | EuiSheetSearch', function (hooks) {
  setupRenderingTest(hooks);

  let drivers: SearchDriver<Doc>[] = [];
  hooks.afterEach(function () {
    drivers.forEach((driver) => driver.destroy());
    drivers = [];
  });

  async function renderSearch(
    store: Store,
    driver: SearchDriver<Doc>,
    fields: EuiSheetField<Doc>[] | undefined = FIELDS
  ): Promise<void> {
    drivers.push(driver);
    await render(
      <template>
        <div style="width:700px">
          <EuiSheetSearch
            @driver={{driver}}
            @getRecordId={{getId}}
            @onChange={{store.write}}
            @fields={{fields}}
            @height={{400}}
          />
        </div>
      </template>
    );
  }

  test('SS1 renders the results (and default fields from the schema)', async function (assert) {
    const { store, driver } = setup(5);
    await renderSearch(store, driver, undefined);
    assert.deepEqual(column(0, 5), ['Ana', 'Beto', 'Caro', 'Dani', 'Eva']);
    assert.deepEqual(column(1, 2), ['Monterrey', 'Madrid']);
    assert.strictEqual(text(0, 2), '1');
    assert.deepEqual(
      Array.from(document.querySelectorAll<HTMLElement>('[role=columnheader]'))
        .map((header) => header.dataset['gridcellColumnId'])
        .filter((id) => id !== 'euiSheetRow'),
      ['name', 'city', 'qty'],
      'fieldsFromSchema(driver.schema)'
    );
    assert.dom('[data-test-subj=euiSheetSearchReapply]').doesNotExist();
    assert.dom('[data-test-subj=euiSheetSearchPagination]').exists();
  });

  test('SS2 the header\'s "Sort A-Z" calls setSort; new results render; the arrow shows', async function (assert) {
    const { store, driver } = setup(5);
    await renderSearch(store, driver);
    assert
      .dom('[data-test-subj=dataGridHeaderCellSortingIcon-city]')
      .doesNotExist();
    await pickFromMenu('city', 'Sort A-Z');
    await settled();
    assert.deepEqual(driver.state.sort, [{ field: 'city', direction: 'asc' }]);
    assert.deepEqual(column(1, 5), [
      'Bogotá',
      'Lima',
      'Madrid',
      'Monterrey',
      'Monterrey'
    ]);
    assert.dom('[data-test-subj=dataGridHeaderCellSortingIcon-city]').exists();
  });

  test('SS3 an edit stays in place under a sort on its field; "Re-apply" re-queries; focus follows the record', async function (assert) {
    const { store, driver } = setup(5, {
      sort: [{ field: 'name', direction: 'asc' }]
    });
    await renderSearch(store, driver);
    assert.deepEqual(column(0, 5), ['Ana', 'Beto', 'Caro', 'Dani', 'Eva']);

    await editName(0, 'Zed');
    assert.strictEqual(text(0, 0), 'Zed', 'the row stays where it was');
    assert.strictEqual(store.changes.length, 1, 'onChange once');
    assert.strictEqual(
      store.docs.find((doc) => doc.id === 'd1')?.name,
      'Zed',
      'saved'
    );
    assert.dom('[data-test-subj=euiSheetSearchReapply]').hasText('Re-apply');
    // V03 batch 2: a small primary button, not a subdued link
    assert
      .dom('[data-test-subj=euiSheetSearchReapply]')
      .hasClass('euiButton', 'a button with a background');

    await focusCell(0, 0); // Enter moved down: back on the edited record
    await click(reapplyButton()!);
    assert.dom('[data-test-subj=euiSheetSearchReapply]').doesNotExist();
    assert.deepEqual(
      column(0, 5),
      ['Beto', 'Caro', 'Dani', 'Eva', 'Zed'],
      'the row moved'
    );
    assert.deepEqual(selected(), ['4:0'], 'the selection follows the record');
    assert.strictEqual(
      document.activeElement,
      cell(4, 0),
      'DOM focus follows the record'
    );
  });

  test('SS3b a re-query while a data cell has focus moves focus with its record (3.2)', async function (assert) {
    const { store, driver } = setup(5, {
      sort: [{ field: 'name', direction: 'asc' }]
    });
    await renderSearch(store, driver);
    await focusCell(1, 1); // Beto, City
    driver.setSort([{ field: 'name', direction: 'desc' }]);
    await settled();
    assert.deepEqual(column(0, 5), ['Eva', 'Dani', 'Caro', 'Beto', 'Ana']);
    assert.strictEqual(document.activeElement, cell(3, 1));
    assert.deepEqual(selected(), ['3:1']);
  });

  test('SS4 pagination: page 2 shows row numbers from perPage + 1', async function (assert) {
    const { store, driver } = setup(7, { perPage: 3 });
    await renderSearch(store, driver);
    assert.deepEqual([rowLabel(0), rowLabel(2)], ['1', '3']);
    await click('[data-test-subj=pagination-button-1]');
    assert.strictEqual(
      driver.state.page.kind === 'offset' && driver.state.page.page,
      2,
      '1-based'
    );
    assert.deepEqual(column(0, 3), ['Dani', 'Eva', 'Fito']);
    assert.deepEqual([rowLabel(0), rowLabel(1), rowLabel(2)], ['4', '5', '6']);
    assert
      .dom('[data-test-subj=pagination-button-1]')
      .hasAttribute('aria-current', 'page', 'EuiTablePagination is 0-based');
  });

  test('SS5 the query term is highlighted', async function (assert) {
    const { store, driver } = setup(5);
    await renderSearch(store, driver);
    driver.setQuery('an');
    await settled();
    assert.deepEqual(column(0, 2), ['Ana', 'Dani'], 'the backend searched');
    assert.strictEqual(
      cell(0, 0).querySelector('mark')?.textContent,
      'An',
      'the match is marked'
    );
    assert.strictEqual(cell(1, 0).querySelector('mark')?.textContent, 'an');
  });

  test("SS6 the app's <:toolbar> and <:footer> render after the default controls and get search", async function (assert) {
    const { store, driver } = setup(5, { perPage: 2 });
    drivers.push(driver);
    const seen: SheetSearchBlockApi<Doc>[] = [];
    const keep = (block: SheetSearchBlockApi<Doc>) => {
      seen.push(block);
      return '';
    };
    await render(
      <template>
        <EuiSheetSearch
          @driver={{driver}}
          @getRecordId={{getId}}
          @onChange={{store.write}}
          @fields={{FIELDS}}
        >
          <:toolbar as |sheet|>
            <span data-test-app-toolbar>{{sheet.search.total}}
              of
              {{sheet.fields.length}}
              fields{{keep sheet}}</span>
          </:toolbar>
          <:footer as |sheet|>
            <span data-test-app-footer>page
              {{sheet.search.page.page}}</span>
          </:footer>
        </EuiSheetSearch>
      </template>
    );
    assert.dom('[data-test-app-toolbar]').hasText('5 of 3 fields');
    assert.dom('[data-test-app-footer]').hasText('page 1');
    assert.strictEqual(
      typeof seen[0]?.hideField,
      'function',
      "the sheet's block API"
    );
    assert.strictEqual(typeof seen[0]?.api.undo, 'function');

    await editName(0, 'Zed');
    const button = reapplyButton()!;
    const toolbar = el('[data-test-app-toolbar]');
    assert.true(
      Boolean(
        button.compareDocumentPosition(toolbar) &
        Node.DOCUMENT_POSITION_FOLLOWING
      ),
      'the app\'s toolbar comes after "Re-apply"'
    );
    assert.true(
      seen[seen.length - 1]!.search.isStale,
      'search.isStale is yielded'
    );
    const pager = el('[data-test-subj=euiSheetSearchPagination]');
    assert.true(
      Boolean(
        pager.compareDocumentPosition(el('[data-test-app-footer]')) &
        Node.DOCUMENT_POSITION_FOLLOWING
      ),
      "the app's footer comes after the pagination"
    );
  });

  test('SS7 @paging={{false}}: no pagination; empty bars take no room', async function (assert) {
    const { store, driver } = setup(5, { perPage: 2 });
    drivers.push(driver);
    await render(
      <template>
        <EuiSheetSearch
          @driver={{driver}}
          @getRecordId={{getId}}
          @onChange={{store.write}}
          @fields={{FIELDS}}
          @paging={{false}}
        />
      </template>
    );
    assert.dom('[data-test-subj=euiSheetSearchPagination]').doesNotExist();
    assert.dom('[data-test-subj=euiSheetSearchFooter]').doesNotExist();
    assert.strictEqual(
      getComputedStyle(el('[data-test-subj=euiSheetFooter]')).display,
      'none',
      'the empty footer is hidden'
    );
    assert.strictEqual(
      getComputedStyle(el('[data-test-subj=euiSheetToolbar]')).display,
      'none',
      'the empty toolbar is hidden'
    );
    await editName(0, 'Zed');
    assert.notStrictEqual(
      getComputedStyle(el('[data-test-subj=euiSheetToolbar]')).display,
      'none',
      'with "Re-apply" it shows'
    );
  });

  test('SS8 an edit, a page change and Ctrl+Z: skipped; back on page 1 Ctrl+Z works', async function (assert) {
    const { store, driver } = setup(5, { perPage: 2 });
    await renderSearch(store, driver);
    await editName(0, 'Zed');
    assert.strictEqual(store.changes.length, 1);

    await click('[data-test-subj=pagination-button-1]');
    assert.deepEqual(column(0, 2), ['Caro', 'Dani'], 'page 2');
    await focusCell(0, 1);
    await pressed('z', { ctrlKey: true });
    assert.strictEqual(store.changes.length, 1, 'skipped: nothing emitted');
    assert.deepEqual(column(0, 2), ['Caro', 'Dani']);

    await click('[data-test-subj=pagination-button-0]');
    assert.strictEqual(text(0, 0), 'Zed', 'page 1 has the saved edit');
    await focusCell(1, 1);
    await pressed('z', { ctrlKey: true });
    assert.strictEqual(store.changes.length, 2, 'the undo is emitted');
    assert.deepEqual(store.changes[1]?.source, 'undo');
    assert.deepEqual(store.changes[1]?.patches, [
      { recordId: 'd1', fieldId: 'name', from: 'Zed', to: 'Ana' }
    ]);
    assert.strictEqual(text(0, 0), 'Ana');
  });

  test('SS9 results arrive while an editor is open: it stays on its record; gone: it closes without a change set', async function (assert) {
    const { store, driver } = setup(5, {
      sort: [{ field: 'name', direction: 'asc' }],
      latencyMs: 30
    });
    await renderSearch(store, driver);
    await focusCell(1, 1); // Beto, City
    await type('z');
    await fillIn(editor()!, 'Quito');
    driver.setSort([{ field: 'name', direction: 'desc' }]);
    await settled();
    assert.deepEqual(column(0, 5), ['Eva', 'Dani', 'Caro', 'Beto', 'Ana']);
    assert.ok(editor(), 'the editor is still open');
    assert.strictEqual(editor()?.value, 'Quito', 'with its draft');
    await press('Enter');
    assert.deepEqual(
      store.changes[0]?.patches,
      [{ recordId: 'd2', fieldId: 'city', from: 'Madrid', to: 'Quito' }],
      'Enter saves to its record'
    );
    assert.strictEqual(text(3, 1), 'Quito');

    await focusCell(0, 1); // Eva
    await type('z');
    await fillIn(editor()!, 'Lisboa');
    driver.setQuery('ana');
    await settled();
    assert.deepEqual(column(0, 1), ['Ana'], 'Eva is not in the results');
    assert.strictEqual(editor(), null, 'the editor closed');
    assert.strictEqual(store.changes.length, 1, 'without a change set');
  });

  test('SS10 @onResolve is forwarded: a paste resolves through the owner and goes through search.apply', async function (assert) {
    const { store, driver } = setup(3);
    drivers.push(driver);
    const placeType = {
      parse: (t: string) =>
        t.trim() === '' ? { value: '' } : { unresolved: t.trim() },
      format: (value: unknown) => (typeof value === 'string' ? value : '')
    };
    const fieldTypes = { place: placeType };
    const fields: EuiSheetField<Doc>[] = [
      { id: 'name', label: 'Name' },
      { id: 'city', label: 'City', type: 'place' }
    ];
    const asked: string[][] = [];
    const onResolve = (requests: { texts: string[] }[]) => {
      asked.push(requests.flatMap((request) => request.texts));
      return Promise.resolve({ city: { Paris: 'Paris (FR)' } });
    };
    await render(
      <template>
        <div style="width:700px">
          <EuiSheetSearch
            @driver={{driver}}
            @getRecordId={{getId}}
            @onChange={{store.write}}
            @fields={{fields}}
            @fieldTypes={{fieldTypes}}
            @onResolve={{onResolve}}
            @height={{300}}
          />
        </div>
      </template>
    );
    await focusCell(0, 1);
    await clipboard('paste', 'Paris');
    assert.deepEqual(asked, [['Paris']]);
    assert.deepEqual(
      store.changes.map((change) => change.source),
      ['resolve']
    );
    assert.strictEqual(text(0, 1), 'Paris (FR)', 'shown over the results');
    assert.strictEqual(store.docs[0]!.city, 'Paris (FR)');
  });
});
