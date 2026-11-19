/**
 * `@validate` (decision Q10, PACKAGE-DESIGN.md 9.4 layers 4-6): record and
 * cross-row rules, async runs, stale results and the abort signal.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { clearRender, render, settled, waitUntil } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import {
  cellTitle,
  clipboard,
  focusCell,
  isInvalid
} from '../../helpers/sheet.ts';

import type {
  CellErrors,
  EuiSheetField,
  ValidateContext
} from '#src/core/index.ts';

interface Row {
  id: string;
  email: string;
  start: string | null;
  end: string | null;
  qty: number | null;
}

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'email' },
  { id: 'start', type: 'date' },
  { id: 'end', type: 'date' },
  { id: 'qty', type: 'number', max: 10 }
];
const getId = (record: { id: string }) => record.id;

const rows = (): Row[] => [
  {
    id: 'r0',
    email: 'a@x.com',
    start: '2026-11-10',
    end: '2026-11-05',
    qty: 1
  },
  {
    id: 'r1',
    email: 'b@x.com',
    start: '2026-11-10',
    end: '2026-11-12',
    qty: 2
  },
  { id: 'r2', email: 'a@x.com', start: null, end: null, qty: 3 }
];

/** Record rule: the end date is after the start date. */
function endAfterStart(
  records: readonly Row[]
): Record<string, Record<string, string>> {
  const errors: Record<string, Record<string, string>> = {};
  for (const r of records) {
    if (r.start && r.end && r.end < r.start) {
      errors[r.id] = { end: 'Must be after the start date' };
    }
  }
  return errors;
}

/** Cross-row rule: emails are unique; the error goes on every duplicate. */
function uniqueEmail(
  records: readonly Row[]
): Record<string, Record<string, string>> {
  const byEmail = new Map<string, string[]>();
  for (const r of records) {
    byEmail.set(r.email, [...(byEmail.get(r.email) ?? []), r.id]);
  }
  const errors: Record<string, Record<string, string>> = {};
  for (const ids of byEmail.values()) {
    if (ids.length > 1)
      for (const id of ids) errors[id] = { email: 'Duplicate email' };
  }
  return errors;
}

function merge(...all: Record<string, Record<string, string>>[]): CellErrors {
  const out: Record<string, Record<string, string>> = {};
  for (const errors of all) {
    for (const [id, fields] of Object.entries(errors)) {
      out[id] = { ...out[id], ...fields };
    }
  }
  return out;
}

interface Deferred {
  promise: Promise<CellErrors>;
  resolve: (errors: CellErrors) => void;
}

function deferred(): Deferred {
  let resolve!: (errors: CellErrors) => void;
  const promise = new Promise<CellErrors>((r) => (resolve = r));
  return { promise, resolve };
}

/** A paste on the focused cell that does not wait for settled() (a pending run would keep it waiting). */
function pasteNow(value: string): void {
  const clipboardData = new DataTransfer();
  clipboardData.setData('text/plain', value);
  document.activeElement!.dispatchEvent(
    new ClipboardEvent('paste', {
      clipboardData,
      bubbles: true,
      cancelable: true
    })
  );
}

class Owner {
  @tracked cellErrors: CellErrors | undefined;
}

module('Integration | Component | EuiSheet validate', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet(
    validate: (
      context: ValidateContext<Row>
    ) => CellErrors | Promise<CellErrors>,
    owner = new Owner()
  ) {
    const store = localRecords<Row>(rows(), { getRecordId: getId });
    await render(
      <template>
        <div style="width:800px">
          <EuiSheet
            @records={{store.records}}
            @fields={{FIELDS}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
            @validate={{validate}}
            @cellErrors={{owner.cellErrors}}
          />
        </div>
      </template>
    );
    return store;
  }

  test('VA1 a record rule puts the error on the end date', async function (assert) {
    const runs: ValidateContext<Row>[] = [];
    await renderSheet((context) => {
      runs.push(context);
      return endAfterStart(context.records);
    });
    assert.strictEqual(runs.length, 1, 'one run on first render');
    assert.deepEqual(runs[0]!.changed, [], 'nothing changed on load');
    assert.true(isInvalid(0, 2), 'end is invalid');
    assert.strictEqual(cellTitle(0, 2), 'Must be after the start date');
    assert.false(isInvalid(0, 1), 'start is not');

    await focusCell(0, 2);
    await clipboard('paste', '2026-11-20');
    assert.strictEqual(
      runs.length,
      2,
      'one run after the change set (debounced with the new @records)'
    );
    assert.deepEqual(runs[1]!.changed, [{ recordId: 'r0', fieldId: 'end' }]);
    assert.false(isInvalid(0, 2), 'fixed');
  });

  test('VA2 a cross-row rule: unique emails', async function (assert) {
    await renderSheet(({ records }) => uniqueEmail(records));
    assert.true(isInvalid(0, 0));
    assert.true(isInvalid(2, 0));
    assert.false(isInvalid(1, 0));
    assert.strictEqual(cellTitle(2, 0), 'Duplicate email');

    await focusCell(2, 0);
    await clipboard('paste', 'b@x.com');
    assert.false(isInvalid(0, 0), 'r0 is unique now');
    assert.true(isInvalid(1, 0), 'r1 is now a duplicate');
    assert.true(isInvalid(2, 0), 'r2 is a duplicate of r1');

    await clipboard('paste', 'c@x.com');
    assert.deepEqual(
      [0, 1, 2].map((row) => isInvalid(row, 0)),
      [false, false, false],
      'cleared'
    );
  });

  test('VA3 merge order: type rules, then @validate, then @cellErrors', async function (assert) {
    const owner = new Owner();
    owner.cellErrors = { r0: { qty: 'Owner note' } };
    const store = await renderSheet(
      ({ records }) =>
        merge(
          endAfterStart(records),
          Object.fromEntries(records.map((r) => [r.id, { qty: 'Over budget' }]))
        ),
      owner
    );
    store.apply({
      source: 'edit',
      patches: [{ recordId: 'r0', fieldId: 'qty', from: 1, to: 11 }],
      inserts: [],
      rejected: [],
      newOptions: []
    });
    await settled();
    assert.strictEqual(
      cellTitle(0, 3),
      'Must be 10 or less\nOver budget\nOwner note'
    );
    await focusCell(0, 3);
    await clipboard('paste', 'abc');
    assert.strictEqual(
      cellTitle(0, 3),
      '"abc" is not a number\nOwner note',
      'a rejected cell shows only its rejection and the owner errors'
    );
  });

  test('VA4 async: a stale slow response is discarded, the older run is aborted', async function (assert) {
    const calls: Array<{ context: ValidateContext<Row>; reply: Deferred }> = [];
    await renderSheet((context) => {
      if (calls.length === 0) {
        calls.push({ context, reply: deferred() });
        return {};
      }
      const reply = deferred();
      calls.push({ context, reply });
      return reply.promise;
    });
    assert.strictEqual(calls.length, 1);

    await focusCell(0, 0);
    pasteNow('slow@x.com');
    await waitUntil(() => calls.length === 2);
    const slow = calls[1]!;
    assert.false(slow.context.signal.aborted, 'the slow run is running');

    pasteNow('fast@x.com');
    await waitUntil(() => calls.length === 3);
    const fast = calls[2]!;
    assert.true(
      slow.context.signal.aborted,
      'the newer run aborted the older one'
    );
    assert.false(fast.context.signal.aborted);
    assert.deepEqual(fast.context.changed, [
      { recordId: 'r0', fieldId: 'email' }
    ]);

    fast.reply.resolve({ r1: { email: 'From the fast run' } });
    await waitUntil(() => isInvalid(1, 0));
    slow.reply.resolve({
      r1: { email: 'From the slow run' },
      r2: { email: 'Stale' }
    });
    await settled();
    assert.strictEqual(
      cellTitle(1, 0),
      'From the fast run',
      'the late, older result is discarded'
    );
    assert.false(isInvalid(2, 0), 'nothing from the stale run');
  });

  test('VA5 async: an error of a record changed since its run started is dropped', async function (assert) {
    const replies: Deferred[] = [];
    const store = await renderSheet(() => {
      if (!replies.length) {
        replies.push(deferred());
        return {};
      }
      const reply = deferred();
      replies.push(reply);
      return reply.promise;
    });

    await focusCell(1, 0);
    pasteNow('z@x.com');
    await waitUntil(() => replies.length === 2);
    // the owner changes r2 while the run is out (no change set from the sheet)
    store.records = store.records.map((r) =>
      r.id === 'r2' ? { ...r, qty: 9 } : r
    );
    replies[1]!.resolve({
      r0: { email: 'Checked' },
      r2: { email: 'About the old r2' }
    });
    await waitUntil(() => isInvalid(0, 0));
    assert.strictEqual(
      cellTitle(0, 0),
      'Checked',
      'an unchanged record keeps its error'
    );
    assert.false(isInvalid(2, 0), 'r2 changed after the run started: dropped');
    // the new @records start another run
    await waitUntil(() => replies.length === 3);
    replies[2]!.resolve({ r2: { email: 'About the new r2' } });
    await settled();
    assert.strictEqual(cellTitle(2, 0), 'About the new r2');
    assert.false(isInvalid(0, 0), 'the newer result replaces the older one');
  });

  test('VA6 destroying the sheet aborts a pending run', async function (assert) {
    const signals: AbortSignal[] = [];
    await renderSheet(({ signal }) => {
      signals.push(signal);
      return signals.length === 1 ? {} : new Promise<CellErrors>(() => {});
    });
    await focusCell(0, 0);
    pasteNow('q@x.com');
    await waitUntil(() => signals.length === 2);
    assert.false(signals[1]!.aborted);
    await clearRender();
    assert.true(signals[1]!.aborted, 'aborted on destroy');
    assert.strictEqual(
      document.querySelector('[data-test-subj=euiSheet]'),
      null
    );
  });
});
