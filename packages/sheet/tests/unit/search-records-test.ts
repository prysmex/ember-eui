/**
 * The EmberSearchUi connector's state (V02-DESIGN.md 7.4, SR1–SR10) on a
 * hand-written fake driver that implements `SheetSearchDriver`.
 */
import QUnit, { module, test } from 'qunit';
import { destroy } from '@ember/destroyable';
import { settled } from '@ember/test-helpers';

import { changeSet } from '../helpers/sheet.ts';
import {
  SearchRecords,
  fieldsFromSchema,
  searchRecords
} from '#src/search-ui/index.ts';

import type { ChangeSet } from '#src/core/index.ts';
import type {
  SearchRecordsOptions,
  SheetSearchDriver,
  SheetSearchPage,
  SheetSearchSnapshot
} from '#src/search-ui/index.ts';
import type { SheetSort } from '#src/types.ts';

interface Doc {
  id: string;
  name: string;
  qty?: number;
}

type Result = SheetSearchSnapshot<Doc>['result'];

const IDLE: Result = {
  status: 'idle',
  results: [],
  total: 0,
  pageCount: 0,
  aggregations: {}
};

/** A driver whose snapshots the test emits by hand. */
class FakeDriver implements SheetSearchDriver<Doc> {
  snapshot: SheetSearchSnapshot<Doc>;
  listeners = new Set<(snapshot: SheetSearchSnapshot<Doc>) => void>();
  calls: Array<[string, unknown]> = [];
  refreshes = 0;
  destroyed = false;

  constructor(page: SheetSearchPage = { kind: 'offset', page: 1, perPage: 2 }) {
    this.snapshot = {
      state: { query: { term: '' }, sort: [], page },
      result: IDLE
    };
  }

  subscribe(listener: (snapshot: SheetSearchSnapshot<Doc>) => void) {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  }

  emit(snapshot: SheetSearchSnapshot<Doc>): void {
    this.snapshot = snapshot;
    for (const listener of [...this.listeners]) listener(snapshot);
  }

  /** A state change: the same result object, as the driver's commands emit. */
  state(patch: Partial<SheetSearchSnapshot<Doc>['state']>): void {
    this.emit({
      state: { ...this.snapshot.state, ...patch },
      result: this.snapshot.result
    });
  }

  succeed(results: Doc[], total = results.length, pageCount = 1): void {
    this.emit({
      state: this.snapshot.state,
      result: { status: 'success', results, total, pageCount, aggregations: {} }
    });
  }

  loading(): void {
    this.emit({
      state: this.snapshot.state,
      result: { ...this.snapshot.result, status: 'loading' }
    });
  }

  fail(error: unknown): void {
    this.emit({
      state: this.snapshot.state,
      result: { ...this.snapshot.result, status: 'error', error }
    });
  }

  setSort(sort: readonly SheetSort[]): void {
    this.calls.push(['setSort', sort]);
  }

  setPage(page: number): void {
    if (this.snapshot.state.page.kind !== 'offset') {
      throw new TypeError('setPage needs offset pagination');
    }
    this.calls.push(['setPage', page]);
  }

  setPerPage(perPage: number): void {
    this.calls.push(['setPerPage', perPage]);
  }

  refresh(): Promise<void> {
    this.refreshes++;
    return Promise.resolve();
  }

  destroy(): void {
    this.destroyed = true;
  }
}

const getRecordId = (doc: Doc) => doc.id;
const DOCS: Doc[] = [
  { id: 'a', name: 'Ana', qty: 1 },
  { id: 'b', name: 'Beto', qty: 2 }
];

function edit(recordId: string, to: string, from = ''): ChangeSet {
  return changeSet({
    source: 'edit',
    patches: [{ recordId, fieldId: 'name', from, to }]
  });
}

function deferred(): {
  promise: Promise<void>;
  resolve: () => void;
  reject: (error: unknown) => void;
} {
  let resolve!: () => void;
  let reject!: (error: unknown) => void;
  const promise = new Promise<void>((res, rej) => {
    resolve = res;
    reject = rej;
  });
  return { promise, resolve, reject };
}

const tick = () => new Promise<void>((resolve) => setTimeout(resolve, 0));

module('Unit | Sheet | search-ui | SearchRecords', function (hooks) {
  let owners: object[] = [];
  hooks.afterEach(async function () {
    for (const owner of owners) destroy(owner);
    owners = [];
    await settled();
  });

  function connect(
    driver: FakeDriver,
    options: Partial<SearchRecordsOptions<Doc>> = {}
  ): { search: SearchRecords<Doc>; changes: ChangeSet[]; owner: object } {
    const owner = {};
    owners.push(owner);
    const changes: ChangeSet[] = [];
    const search = searchRecords(owner, driver, {
      getRecordId,
      onChange: (set) => {
        changes.push(set);
      },
      ...options
    });
    return { search, changes, owner };
  }

  test('SR1 records, sort, term, isLoading, total, page and rowNumberOffset come from snapshots', function (assert) {
    const driver = new FakeDriver();
    const { search } = connect(driver);
    assert.deepEqual(search.records, [], 'idle: no records');
    assert.false(search.isLoading);
    assert.deepEqual(search.page, { page: 1, perPage: 2, pageCount: 0 });
    assert.strictEqual(search.rowNumberOffset, 0);

    driver.succeed(DOCS, 7, 4);
    assert.strictEqual(search.rowNumberOffset, 0, 'page 1');
    driver.state({
      query: { term: 'an' },
      sort: [{ field: 'name', direction: 'desc' }],
      page: { kind: 'offset', page: 2, perPage: 2 }
    });
    assert.strictEqual(search.term, 'an');
    assert.deepEqual(search.sort, [{ field: 'name', direction: 'desc' }]);
    const sort = search.sort;
    assert.strictEqual(search.sort, sort, 'the same sort keeps its identity');
    assert.deepEqual(
      search.page,
      { page: 2, perPage: 2, pageCount: 4 },
      'the requested page at once'
    );
    assert.strictEqual(
      search.rowNumberOffset,
      0,
      'the offset waits for the results of that page'
    );

    driver.loading();
    assert.true(search.isLoading);
    driver.succeed(DOCS, 7, 4);
    assert.false(search.isLoading);
    assert.deepEqual(search.records, DOCS);
    assert.notStrictEqual(
      search.records,
      driver.snapshot.result.results,
      'a copy of the results'
    );
    assert.strictEqual(search.total, 7);
    assert.deepEqual(search.page, { page: 2, perPage: 2, pageCount: 4 });
    assert.strictEqual(search.rowNumberOffset, 2, '(2 - 1) * 2');
    assert.strictEqual(search.error, undefined);
  });

  test('SR1b state-only, loading and error snapshots keep the rows and the overlay', function (assert) {
    const driver = new FakeDriver();
    const { search } = connect(driver);
    driver.succeed(DOCS);
    search.apply(edit('a', 'Zoe', 'Ana'));
    const shown = search.records;

    driver.state({ page: { kind: 'offset', page: 2, perPage: 2 } });
    assert.strictEqual(search.records, shown, 'a state change keeps the rows');
    assert.true(search.isStale, 'and the overlay');
    driver.loading();
    assert.strictEqual(search.records, shown, 'loading keeps them');
    assert.true(search.isStale);
    const error = new Error('down');
    driver.fail(error);
    assert.strictEqual(search.records, shown, 'an error keeps them');
    assert.true(search.isStale);
    assert.strictEqual(search.error, error);
    assert.strictEqual(search.records[0]?.name, 'Zoe');
  });

  test('SR2 apply shows the edit over the results; isStale; onChange once; no refresh', function (assert) {
    const driver = new FakeDriver();
    const { search, changes } = connect(driver);
    driver.succeed(DOCS);
    const before = search.records;
    const set = edit('a', 'Zoe', 'Ana');
    search.apply(set);
    assert.deepEqual(search.records, [
      { id: 'a', name: 'Zoe', qty: 1 },
      { id: 'b', name: 'Beto', qty: 2 }
    ]);
    assert.notStrictEqual(search.records, before, 'a new array');
    assert.strictEqual(
      search.records[1],
      before[1],
      'unchanged records keep their identity'
    );
    assert.true(search.isStale);
    assert.deepEqual(changes, [set], 'onChange once, with the change set');
    assert.strictEqual(driver.refreshes, 0, 'no re-query');
    assert.deepEqual(driver.calls, [], 'no driver command');

    search.apply(edit('b', 'Bea', 'Beto'));
    assert.deepEqual(
      search.records.map((doc) => doc.name),
      ['Zoe', 'Bea'],
      'one change set over the previous overlay'
    );
  });

  test('SR3 a new successful result empties the overlay', function (assert) {
    const driver = new FakeDriver();
    const { search } = connect(driver);
    driver.succeed(DOCS);
    search.apply(edit('a', 'Zoe', 'Ana'));
    assert.true(search.isStale);
    const fresh: Doc[] = [{ id: 'c', name: 'Caro' }];
    driver.succeed(fresh);
    assert.false(search.isStale);
    assert.deepEqual(search.records, fresh, 'the backend is the truth again');
  });

  test('SR4 reapply waits for a pending onChange promise before refresh', async function (assert) {
    const driver = new FakeDriver();
    const save = deferred();
    const { search } = connect(driver, { onChange: () => save.promise });
    driver.succeed(DOCS);
    search.apply(edit('a', 'Zoe', 'Ana'));
    const done = search.reapply();
    await tick();
    assert.strictEqual(driver.refreshes, 0, 'not while the save runs');
    save.resolve();
    await done;
    assert.strictEqual(driver.refreshes, 1, 'once it is saved');
  });

  test('SR5 a search that completes while onChange runs is followed by one refresh', async function (assert) {
    const driver = new FakeDriver();
    const save = deferred();
    const { search } = connect(driver, { onChange: () => save.promise });
    driver.succeed(DOCS);
    search.apply(edit('a', 'Zoe', 'Ana'));
    driver.succeed([{ id: 'a', name: 'Ana', qty: 1 }]);
    assert.false(search.isStale, 'the result replaced the rows');
    await tick();
    assert.strictEqual(driver.refreshes, 0);
    save.resolve();
    await tick();
    assert.strictEqual(driver.refreshes, 1, 'one refresh after the save');
    await tick();
    assert.strictEqual(driver.refreshes, 1, 'and only one');

    // without a search during the save: no refresh
    const second = deferred();
    const other = new FakeDriver();
    const { search: quiet } = connect(other, {
      onChange: () => second.promise
    });
    other.succeed(DOCS);
    quiet.apply(edit('a', 'Zoe', 'Ana'));
    second.resolve();
    await tick();
    assert.strictEqual(other.refreshes, 0, 'no search ran meanwhile');
  });

  test('SR6 refreshOnChange re-queries after each change set', async function (assert) {
    const driver = new FakeDriver();
    const save = deferred();
    const { search } = connect(driver, {
      onChange: () => save.promise,
      refreshOnChange: true
    });
    driver.succeed(DOCS);
    search.apply(edit('a', 'Zoe', 'Ana'));
    assert.strictEqual(search.records[0]?.name, 'Zoe', 'shown at once');
    await tick();
    assert.strictEqual(driver.refreshes, 0, 'after the save');
    driver.succeed(DOCS); // a search finishing during the save
    save.resolve();
    await settled();
    assert.strictEqual(
      driver.refreshes,
      1,
      'one refresh: reapply, not also the search-during-save refresh'
    );
  });

  test('SR7 cursor paging: no page, offset 0, setPage does not call the driver', function (assert) {
    const driver = new FakeDriver({ kind: 'cursor', cursor: null, size: 2 });
    const { search } = connect(driver);
    driver.succeed(DOCS, 10, 0);
    assert.strictEqual(search.page, undefined);
    assert.strictEqual(search.rowNumberOffset, 0);
    search.setPage(2);
    assert.deepEqual(
      driver.calls,
      [],
      'setPage is a no-op (the driver would throw)'
    );
    search.setPerPage(5);
    search.setSort([{ field: 'name', direction: 'asc' }]);
    assert.deepEqual(driver.calls, [
      ['setPerPage', 5],
      ['setSort', [{ field: 'name', direction: 'asc' }]]
    ]);

    const offset = new FakeDriver();
    const { search: paged } = connect(offset);
    paged.setPage(3);
    assert.deepEqual(offset.calls, [['setPage', 3]], '1-based, as given');
  });

  test('SR8 inserts and deletes in the overlay: index, anchor, createRecord', function (assert) {
    const driver = new FakeDriver();
    const created: Array<[Record<string, unknown>, string]> = [];
    const { search } = connect(driver, {
      createRecord: (values, tempId) => {
        created.push([values, tempId]);
        const name = values['name'];
        return {
          id: `new-${tempId}`,
          name: typeof name === 'string' ? name : ''
        };
      }
    });
    driver.succeed([
      { id: 'a', name: 'Ana' },
      { id: 'b', name: 'Beto' },
      { id: 'c', name: 'Caro' }
    ]);

    search.apply(
      changeSet({
        source: 'insert',
        inserts: [
          {
            tempId: 't1',
            index: 1,
            values: { name: 'Dani' },
            anchor: { recordId: 'a', position: 'after' }
          }
        ]
      })
    );
    assert.deepEqual(
      search.records.map((doc) => doc.id),
      ['a', 'new-t1', 'b', 'c'],
      'after its anchor'
    );
    assert.deepEqual(created, [[{ name: 'Dani' }, 't1']], 'createRecord');

    search.apply(
      changeSet({
        source: 'insert',
        inserts: [{ tempId: 't2', index: 0, values: { name: 'Eva' } }]
      })
    );
    assert.strictEqual(search.records[0]?.id, 'new-t2', 'no anchor: at index');

    search.apply(
      changeSet({
        source: 'delete',
        deletes: ['b'],
        removed: [
          {
            recordId: 'b',
            index: 2,
            after: 'new-t1',
            record: { id: 'b', name: 'Beto' }
          }
        ]
      })
    );
    assert.deepEqual(
      search.records.map((doc) => doc.id),
      ['new-t2', 'a', 'new-t1', 'c'],
      'the delete removes it'
    );
    assert.true(search.isStale);

    const plain = new FakeDriver();
    const { search: defaults } = connect(plain);
    plain.succeed([{ id: 'a', name: 'Ana' }]);
    defaults.apply(
      changeSet({
        source: 'insert',
        inserts: [{ tempId: 'tmp', index: 5, values: { name: 'Zed' } }]
      })
    );
    assert.deepEqual(
      defaults.records,
      [
        { id: 'a', name: 'Ana' },
        { id: 'tmp', name: 'Zed' }
      ],
      'default createRecord: { id: tempId, ...values }, past the end appends'
    );
  });

  test('SR9 fieldsFromSchema per type', function (assert) {
    const fields = fieldsFromSchema({
      name: { path: 'name', type: 'text', label: 'Name' },
      code: { path: 'code', type: 'keyword' },
      state: {
        path: 'state',
        type: 'keyword',
        label: 'State',
        options: [
          { value: 'open', label: 'Open' },
          { value: 2, label: 'Two' },
          { value: true, label: 'Yes' },
          { value: null, label: 'None' }
        ]
      },
      flags: {
        path: 'flags',
        type: 'keyword',
        options: [{ value: false, label: 'No' }]
      },
      qty: { path: 'qty', type: 'number' },
      due: { path: 'due', type: 'date' },
      done: { path: 'done', type: 'boolean' },
      weird: { path: 'weird', type: 'ip' },
      where: { path: 'where', type: 'geo' },
      items: { path: 'items', type: 'keyword', nested: true },
      deep: { path: 'deep', type: 'nested' },
      'custom.due': { path: 'custom.due', type: 'date' }
    });
    assert.deepEqual(fields, [
      { id: 'name', label: 'Name', type: 'text' },
      { id: 'code', label: 'code', type: 'text' },
      {
        id: 'state',
        label: 'State',
        type: 'singleSelect',
        options: [
          { value: 'open', label: 'Open' },
          { value: 2, label: 'Two' }
        ]
      },
      { id: 'flags', label: 'flags', type: 'text' },
      { id: 'qty', label: 'qty', type: 'number' },
      { id: 'due', label: 'due', type: 'date' },
      { id: 'done', label: 'done', type: 'checkbox' },
      { id: 'weird', label: 'weird', type: 'text' }
    ]);
    assert.deepEqual(fieldsFromSchema(undefined), [], 'no schema: no fields');
  });

  test('SR10 unsubscribes on destroy and does not destroy the driver', async function (assert) {
    const driver = new FakeDriver();
    const { search, owner } = connect(driver);
    driver.succeed(DOCS);
    assert.strictEqual(driver.listeners.size, 1, 'subscribed');
    destroy(owner);
    await settled();
    assert.strictEqual(driver.listeners.size, 0, 'unsubscribed');
    assert.false(driver.destroyed, 'the driver is not destroyed');
    driver.succeed([{ id: 'z', name: 'Zed' }]);
    assert.deepEqual(search.records, DOCS, 'later snapshots are not read');
  });

  test('SR11 a rejected onChange keeps the change set in the overlay and reaches the app', async function (assert) {
    const driver = new FakeDriver();
    const save = deferred();
    const { search } = connect(driver, { onChange: () => save.promise });
    driver.succeed(DOCS);
    const reasons: unknown[] = [];
    const listener = (event: PromiseRejectionEvent) => {
      reasons.push(event.reason);
      event.preventDefault();
    };
    const config = QUnit.config as unknown as {
      ignoreUnhandledRejections?: boolean;
    };
    const ignored = config.ignoreUnhandledRejections;
    config.ignoreUnhandledRejections = true;
    window.addEventListener('unhandledrejection', listener);
    try {
      search.apply(edit('a', 'Zoe', 'Ana'));
      const error = new Error('save failed');
      save.reject(error);
      await new Promise((resolve) => setTimeout(resolve, 20));
      assert.deepEqual(
        reasons,
        [error],
        're-thrown, unhandled: the app’s error handling'
      );
      assert.strictEqual(search.records[0]?.name, 'Zoe', 'still shown');
      assert.true(search.isStale, 'still pending');
      assert.strictEqual(driver.refreshes, 0, 'nothing re-queried or undone');
    } finally {
      window.removeEventListener('unhandledrejection', listener);
      config.ignoreUnhandledRejections = ignored;
    }
  });

  test('SR12 a SearchRecords without searchRecords can disconnect', function (assert) {
    const driver = new FakeDriver();
    const search = new SearchRecords(driver, {
      getRecordId,
      onChange: () => undefined
    });
    driver.succeed(DOCS);
    assert.deepEqual(search.records, DOCS);
    search.disconnect();
    assert.strictEqual(driver.listeners.size, 0);
  });
});
