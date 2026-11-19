/**
 * The connector against the real `SearchDriver` (V02-DESIGN.md 7.4): it is
 * assignable to `SheetSearchDriver` (checked by `ember-tsc -p
 * tsconfig.eslint.json`, which includes the tests), and SR1–SR3 again with
 * `memoryBackend`. `ember-search-ui-driver` is a devDependency only.
 */
import { module, test } from 'qunit';
import { destroy } from '@ember/destroyable';
import { settled } from '@ember/test-helpers';
import { SearchDriver, memoryBackend } from 'ember-search-ui-driver';

import { changeSet } from '../helpers/sheet.ts';
import { fieldsFromSchema, searchRecords } from '#src/search-ui/index.ts';

import type { ChangeSet } from '#src/core/index.ts';
import type { SheetSearchDriver } from '#src/search-ui/index.ts';

interface Doc {
  id: string;
  name: string;
  city: string;
}

/** Compile-time: takes only a `SheetSearchDriver`. */
const asSheetDriver = (driver: SheetSearchDriver<Doc>) => driver;

const DOCS: Doc[] = [
  { id: 'a', name: 'Ana', city: 'Monterrey' },
  { id: 'b', name: 'Beto', city: 'Madrid' },
  { id: 'c', name: 'Caro', city: 'Lima' },
  { id: 'd', name: 'Dani', city: 'Bogotá' },
  { id: 'e', name: 'Eva', city: 'Madrid' }
];

const SCHEMA = {
  name: { path: 'name', type: 'text' as const, label: 'Name' },
  city: {
    path: 'city',
    type: 'keyword' as const,
    label: 'City',
    options: [
      { value: 'Madrid', label: 'Madrid' },
      { value: 'Lima', label: 'Lima' }
    ]
  }
};

module('Unit | Sheet | search-ui | the real SearchDriver', function (hooks) {
  let owner: object;
  let driver: SearchDriver<Doc>;
  hooks.beforeEach(function () {
    owner = {};
    driver = new SearchDriver<Doc>({
      backend: memoryBackend(() => DOCS),
      schema: SCHEMA,
      initialState: { page: { kind: 'offset', page: 1, perPage: 2 } },
      searchOnInit: false
    });
  });
  hooks.afterEach(async function () {
    destroy(owner);
    driver.destroy();
    await settled();
  });

  test('SR1 against memoryBackend: records, sort, term, page, offset', async function (assert) {
    const search = searchRecords(owner, driver, {
      getRecordId: (doc) => doc.id,
      onChange: () => undefined
    });
    // a real driver is a SheetSearchDriver ...
    assert.strictEqual(asSheetDriver(driver), driver);
    // ... and the check is not vacuous: a driver without setSort is not
    const partial: Omit<SearchDriver<Doc>, 'setSort'> = driver;
    // @ts-expect-error setSort is missing
    assert.ok(asSheetDriver(partial));

    await driver.refresh();
    assert.deepEqual(
      search.records.map((doc) => doc.id),
      ['a', 'b']
    );
    assert.strictEqual(search.total, 5);
    assert.deepEqual(search.page, { page: 1, perPage: 2, pageCount: 3 });

    search.setSort([{ field: 'name', direction: 'desc' }]);
    assert.deepEqual(search.sort, [{ field: 'name', direction: 'desc' }]);
    await settled();
    assert.deepEqual(
      search.records.map((doc) => doc.id),
      ['e', 'd'],
      'sorted by the backend; settled() waited for the search'
    );

    search.setPage(2);
    await settled();
    assert.deepEqual(
      search.records.map((doc) => doc.id),
      ['c', 'b']
    );
    assert.strictEqual(search.rowNumberOffset, 2);

    driver.setQuery('madrid');
    await settled();
    assert.strictEqual(search.term, 'madrid');
    assert.deepEqual(
      search.records.map((doc) => doc.id),
      ['e', 'b'],
      'a query goes back to page 1'
    );
    assert.strictEqual(search.rowNumberOffset, 0);
  });

  test('SR2 and SR3 against memoryBackend: the overlay until the next search', async function (assert) {
    const docs = DOCS.map((doc) => ({ ...doc }));
    const store = memoryBackend(() => docs);
    const own = new SearchDriver<Doc>({
      backend: store,
      initialState: {
        sort: [{ field: 'name', direction: 'asc' }],
        page: { kind: 'offset', page: 1, perPage: 5 }
      },
      searchOnInit: false
    });
    const changes: ChangeSet[] = [];
    const search = searchRecords(owner, own, {
      getRecordId: (doc) => doc.id,
      onChange: (set) => {
        changes.push(set);
        for (const patch of set.patches) {
          const doc = docs.find((d) => d.id === patch.recordId);
          if (doc) doc.name = String(patch.to);
        }
      }
    });
    await own.refresh();
    search.apply(
      changeSet({
        source: 'edit',
        patches: [{ recordId: 'a', fieldId: 'name', from: 'Ana', to: 'Zoe' }]
      })
    );
    assert.deepEqual(
      search.records.map((doc) => doc.name),
      ['Zoe', 'Beto', 'Caro', 'Dani', 'Eva'],
      'stays in place'
    );
    assert.true(search.isStale);
    assert.strictEqual(changes.length, 1);

    await search.reapply();
    assert.false(search.isStale);
    assert.deepEqual(
      search.records.map((doc) => doc.name),
      ['Beto', 'Caro', 'Dani', 'Eva', 'Zoe'],
      'the backend sorts the saved value'
    );
    own.destroy();
  });

  test('SR9 fieldsFromSchema reads a real FieldSchema', function (assert) {
    assert.deepEqual(fieldsFromSchema(driver.schema), [
      { id: 'name', label: 'Name', type: 'text' },
      {
        id: 'city',
        label: 'City',
        type: 'singleSelect',
        options: [
          { value: 'Madrid', label: 'Madrid' },
          { value: 'Lima', label: 'Lima' }
        ]
      }
    ]);
  });
});
