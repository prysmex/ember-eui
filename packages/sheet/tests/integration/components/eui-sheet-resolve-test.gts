/** EuiSheet's `@onResolve` (V02-DESIGN.md 8.2, V9): RV1-RV7. */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { click, fillIn, render, settled, waitUntil } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { applyChangeSet } from '#src/core/index.ts';
import {
  cell,
  clipboard,
  editor,
  focusCell,
  isInvalid,
  press,
  pressed,
  text
} from '../../helpers/sheet.ts';

import type {
  ChangeSet,
  EuiSheetField,
  ResolveRequest,
  ResolveResult,
  SheetLinkedRecord
} from '#src/core/index.ts';

interface Row {
  id: string;
  name: string;
  people: SheetLinkedRecord[];
  [key: string]: unknown;
}

const getId = (row: { id: string }) => row.id;

const PEOPLE: SheetLinkedRecord[] = [
  { id: 'p1', label: 'Ana' },
  { id: 'p2', label: 'Bo' },
  { id: 'p3', label: 'Carla' }
];

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name', label: 'Name' },
  {
    id: 'people',
    label: 'People',
    type: 'linkedRecord',
    search: (query: string) =>
      Promise.resolve(
        PEOPLE.filter((p) =>
          p.label.toLowerCase().includes(query.toLowerCase())
        )
      )
  }
];

interface Call {
  requests: ResolveRequest<Row>[];
  signal: AbortSignal;
  resolve: (result: ResolveResult) => void;
  reject: (error: unknown) => void;
}

/** An owner: tracked records, `applyChangeSet` in `@onChange`, a controllable `@onResolve`. */
class Owner {
  @tracked records: Row[] = [
    { id: 'r0', name: 'a', people: [] },
    { id: 'r1', name: 'b', people: [] }
  ];
  @tracked shown = true;
  log: ChangeSet[] = [];
  calls: Call[] = [];
  resolving = true;

  onChange = (changeSet: ChangeSet): void => {
    this.log.push(changeSet);
    this.records = applyChangeSet(this.records, changeSet, {
      getRecordId: getId,
      createRecord: (values, tempId) =>
        ({ id: tempId, name: '', people: [], ...values }) as Row
    });
  };

  onResolve = (
    requests: ResolveRequest<Row>[],
    { signal }: { signal: AbortSignal }
  ): Promise<ResolveResult> =>
    new Promise((resolve, reject) => {
      this.calls.push({ requests, signal, resolve, reject });
    });

  /** The owner's answer: every label it knows. */
  answer(call: Call, extra: Record<string, unknown> = {}): ResolveResult {
    const people: Record<string, unknown> = {};
    for (const request of call.requests) {
      for (const t of request.texts) {
        people[t] = PEOPLE.find((p) => p.label === t) ?? null;
      }
    }
    return { people: { ...people, ...extra } };
  }
}

/** A paste without waiting for the sheet to settle (the resolve keeps it busy). */
async function pasteNow(value: string): Promise<void> {
  const clipboardData = new DataTransfer();
  clipboardData.setData('text/plain', value);
  document.activeElement!.dispatchEvent(
    new ClipboardEvent('paste', {
      clipboardData,
      bubbles: true,
      cancelable: true
    })
  );
  await waitUntil(() => document.querySelector('.euiSheet__cell--pending'));
}

/** Focus without `settled()` (a pending resolve holds the test waiter). */
async function focusNow(row: number, col: number): Promise<void> {
  const target = cell(row, col);
  target.focus();
  await waitUntil(() => document.activeElement === target);
}

/** A keydown on the focused element without `settled()`. */
async function keyNow(
  key: string,
  modifiers: { ctrlKey?: boolean } = {}
): Promise<void> {
  document.activeElement!.dispatchEvent(
    new KeyboardEvent('keydown', {
      key,
      bubbles: true,
      cancelable: true,
      ...modifiers
    })
  );
  await new Promise((resolve) => setTimeout(resolve, 20));
}

function chips(row: number, col: number): string[] {
  return Array.from(
    cell(row, col).querySelectorAll('[data-test-subj=euiSheetChip]')
  ).map((chip) => chip.textContent?.trim() ?? '');
}

const isPending = (row: number, col: number) =>
  cell(row, col).classList.contains('euiSheet__cell--pending');

module('Integration | Component | EuiSheet resolve', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet(owner: Owner) {
    const onResolve = owner.resolving ? owner.onResolve : undefined;
    await render(
      <template>
        <div style="width:800px">
          {{#if owner.shown}}
            <EuiSheet
              @records={{owner.records}}
              @fields={{FIELDS}}
              @getRecordId={{getId}}
              @onChange={{owner.onChange}}
              @onResolve={{onResolve}}
            />
          {{/if}}
        </div>
      </template>
    );
  }

  test('RV1 a paste: names at once, people pending, then resolved; one undo reverts both', async function (assert) {
    const owner = new Owner();
    await renderSheet(owner);
    await focusCell(0, 0);
    await pasteNow('x\tAna, Bo\ny\tCarla\nz\tBo');
    assert.deepEqual(
      owner.log.map((set) => set.source),
      ['paste'],
      'the synchronous part'
    );
    assert.deepEqual(owner.log[0]!.patches, [
      { recordId: 'r0', fieldId: 'name', from: 'a', to: 'x' },
      { recordId: 'r1', fieldId: 'name', from: 'b', to: 'y' }
    ]);
    assert.strictEqual(
      owner.log[0]!.inserts.length,
      1,
      'the third line inserts'
    );
    const tempId = owner.log[0]!.inserts[0]!.tempId;
    assert.true(isPending(0, 1));
    assert.true(isPending(1, 1));
    assert.strictEqual(text(0, 1), 'Ana, Bo', 'the text shows while pending');
    assert.false(isInvalid(0, 1), 'no error while pending');
    assert.strictEqual(text(0, 0), 'x');
    assert.strictEqual(owner.calls.length, 1, 'one call per paste');
    const [call] = owner.calls;
    assert.deepEqual(call!.requests.length, 1, 'one request per field');
    assert.deepEqual(call!.requests[0]!.texts, ['Ana', 'Bo', 'Carla']);
    assert.deepEqual(
      call!.requests[0]!.cells.map((c) => [c.text, c.recordId ?? c.tempId]),
      [
        ['Ana, Bo', 'r0'],
        ['Carla', 'r1'],
        ['Bo', tempId]
      ]
    );
    call!.resolve(owner.answer(call!));
    await settled();
    assert.deepEqual(
      owner.log.map((set) => set.source),
      ['paste', 'resolve']
    );
    assert.deepEqual(owner.log[1]!.patches, [
      {
        recordId: 'r0',
        fieldId: 'people',
        from: [],
        to: [PEOPLE[0], PEOPLE[1]]
      },
      { recordId: 'r1', fieldId: 'people', from: [], to: [PEOPLE[2]] },
      { recordId: tempId, fieldId: 'people', from: [], to: [PEOPLE[1]] }
    ]);
    assert.false(isPending(0, 1));
    assert.deepEqual(chips(0, 1), ['Ana', 'Bo']);
    assert.deepEqual(chips(2, 1), ['Bo'], 'the inserted row too');
    // one undo: both change sets
    await focusCell(0, 0);
    await pressed('z', { ctrlKey: true });
    assert.deepEqual(
      owner.records.map((r) => [r.id, r.name, r.people.length]),
      [
        ['r0', 'a', 0],
        ['r1', 'b', 0]
      ]
    );
    assert.strictEqual(owner.log[owner.log.length - 1]!.source, 'undo');
    assert.strictEqual(owner.log.length, 3, 'one undo change set');
    await pressed('z', { ctrlKey: true, shiftKey: true });
    assert.deepEqual(
      owner.records.map((r) => [
        r.name,
        r.people.map((p) => p.label).join(',')
      ]),
      [
        ['x', 'Ana,Bo'],
        ['y', 'Carla'],
        ['z', 'Bo']
      ],
      'redo writes both again'
    );
  });

  test('RV2 a text the owner answers null for is a rejection', async function (assert) {
    const owner = new Owner();
    await renderSheet(owner);
    await focusCell(0, 1);
    await pasteNow('Ana, Zed');
    const [call] = owner.calls;
    call!.resolve(owner.answer(call!));
    await settled();
    assert.deepEqual(
      owner.log.map((set) => set.source),
      ['resolve']
    );
    assert.deepEqual(owner.log[0]!.rejected, [
      {
        recordId: 'r0',
        fieldId: 'people',
        text: 'Ana, Zed',
        message: '"Zed" could not be resolved'
      }
    ]);
    assert.true(isInvalid(0, 1));
    assert.strictEqual(text(0, 1), 'Ana, Zed');
    // a failed call: every cell is a rejection
    await focusNow(1, 1);
    await pasteNow('Bo');
    owner.calls[1]!.reject(new Error('down'));
    await settled();
    assert.deepEqual(owner.log[1]!.rejected, [
      {
        recordId: 'r1',
        fieldId: 'people',
        text: 'Bo',
        message: '"Bo" could not be resolved'
      }
    ]);
    // undo clears the rejected text
    await pressed('z', { ctrlKey: true });
    assert.false(isInvalid(1, 1));
  });

  test('RV3 a newer edit of a pending cell discards its result', async function (assert) {
    const owner = new Owner();
    await renderSheet(owner);
    await focusCell(0, 1);
    await pasteNow('Ana');
    await focusNow(1, 1);
    await pasteNow('Bo');
    assert.strictEqual(owner.calls.length, 2);
    // Delete on the first: it is written (cleared) again
    await focusNow(0, 1);
    await keyNow('Delete');
    assert.false(isPending(0, 1), 'no longer pending');
    assert.true(owner.calls[0]!.signal.aborted, 'its call has no cell left');
    assert.false(owner.calls[1]!.signal.aborted);
    owner.calls[0]!.resolve(owner.answer(owner.calls[0]!));
    owner.calls[1]!.resolve(owner.answer(owner.calls[1]!));
    await settled();
    assert.deepEqual(
      owner.records.map((r) => r.people.map((p) => p.label)),
      [[], ['Bo']],
      'only the untouched cell was resolved'
    );
    // a paste over a pending cell replaces it
    await focusNow(0, 1);
    await pasteNow('Ana');
    await pasteNow('Carla');
    owner.calls[2]!.resolve(owner.answer(owner.calls[2]!));
    owner.calls[3]!.resolve(owner.answer(owner.calls[3]!));
    await settled();
    assert.true(owner.calls[2]!.signal.aborted);
    assert.deepEqual(
      owner.records[0]!.people.map((p) => p.label),
      ['Carla']
    );
  });

  test('RV4 destroying the sheet aborts the signal', async function (assert) {
    const owner = new Owner();
    await renderSheet(owner);
    await focusCell(0, 1);
    await pasteNow('Ana');
    const [call] = owner.calls;
    owner.shown = false;
    await settled();
    assert.true(call!.signal.aborted);
    call!.resolve(owner.answer(call!));
    await settled();
    assert.deepEqual(owner.log, [], 'nothing emitted after the teardown');
  });

  test('RV5 without @onResolve: unresolved texts are rejections (v0.1)', async function (assert) {
    const owner = new Owner();
    owner.resolving = false;
    await renderSheet(owner);
    await focusCell(0, 0);
    await clipboard('paste', 'x\tAna');
    assert.deepEqual(owner.log.length, 1);
    assert.deepEqual(owner.log[0]!.patches, [
      { recordId: 'r0', fieldId: 'name', from: 'a', to: 'x' }
    ]);
    assert.deepEqual(owner.log[0]!.rejected, [
      {
        recordId: 'r0',
        fieldId: 'people',
        text: 'Ana',
        message: '"Ana" could not be resolved'
      }
    ]);
    assert.dom('.euiSheet__cell--pending').doesNotExist();
    assert.true(isInvalid(0, 1));
  });

  test('RV6 a text typed in a linked-record cell resolves too', async function (assert) {
    const owner = new Owner();
    await renderSheet(owner);
    await focusCell(0, 1);
    await press('Enter');
    await fillIn(editor()!, 'Carla');
    // focus leaves the picker without a pick: the typed text is resolved
    // (the click settles only once the resolve is answered)
    const leaving = click(cell(1, 0));
    await waitUntil(() => owner.calls.length === 1);
    const [call] = owner.calls;
    assert.deepEqual(call!.requests, [
      {
        fieldId: 'people',
        texts: ['Carla'],
        cells: [{ text: 'Carla', recordId: 'r0', record: owner.records[0] }]
      }
    ]);
    assert.true(isPending(0, 1));
    call!.resolve(owner.answer(call!));
    await leaving;
    await settled();
    assert.deepEqual(
      owner.log.map((set) => set.source),
      ['resolve']
    );
    assert.deepEqual(owner.records[0]!.people, [PEOPLE[2]]);
    await focusCell(0, 0);
    await pressed('z', { ctrlKey: true });
    assert.deepEqual(
      owner.records[0]!.people,
      [],
      'the resolve is its own undo entry'
    );
  });

  test('RV7 a pending cell whose record leaves @records is dropped', async function (assert) {
    const owner = new Owner();
    await renderSheet(owner);
    await focusCell(0, 1);
    await pasteNow('Ana\nBo');
    const [call] = owner.calls;
    // the owner re-queries: r1 is gone
    owner.records = [owner.records[0]!];
    await waitUntil(
      () => document.querySelectorAll('.euiSheet__cell--pending').length === 1
    );
    assert.false(call!.signal.aborted, 'r0 is still pending');
    owner.records = [{ id: 'r9', name: 'n', people: [] }];
    await waitUntil(() => call!.signal.aborted);
    assert.true(call!.signal.aborted, 'no cell left: aborted');
    call!.resolve(owner.answer(call!));
    await settled();
    assert.deepEqual(owner.log, [], 'nothing resolved');
  });

  test('RV8 an undo of the paste before the answer drops its pending cells and aborts', async function (assert) {
    const owner = new Owner();
    await renderSheet(owner);
    await focusCell(0, 0);
    await pasteNow('x\tAna');
    const [call] = owner.calls;
    await keyNow('z', { ctrlKey: true });
    assert.true(call!.signal.aborted, 'aborted');
    assert.dom('.euiSheet__cell--pending').doesNotExist();
    assert.strictEqual(owner.records[0]!.name, 'a', 'the name is back');
    call!.resolve(owner.answer(call!));
    await settled();
    assert.deepEqual(
      owner.log.map((set) => set.source),
      ['paste', 'undo'],
      'the late answer is not written'
    );
    assert.deepEqual(owner.records[0]!.people, []);
  });
});
