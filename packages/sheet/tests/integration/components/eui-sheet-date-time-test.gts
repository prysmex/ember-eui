/**
 * The `dateTime` type in the sheet (V03-DESIGN.md 10.3, DT5, DT6): typed,
 * shown, copied and pasted in a 'utc' field and a named zone, the native
 * picker in the field's zone, and a `date` field next to it unchanged.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { fillIn, render, waitUntil } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import {
  cell,
  cellTitle,
  clipboard,
  editor,
  focusCell,
  isInvalid,
  press,
  text,
  type
} from '../../helpers/sheet.ts';

import type { EuiSheetField } from '#src/core/index.ts';

interface Row {
  id: string;
  at: string | null;
  local: string | null;
  due: string | null;
}

const getId = (row: Row) => row.id;

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'at', label: 'At (UTC)', type: 'dateTime', timeZone: 'utc' },
  {
    id: 'local',
    label: 'In Mexico City',
    type: 'dateTime',
    timeZone: 'America/Mexico_City',
    hour12: true
  },
  { id: 'due', label: 'Due', type: 'date' }
];

function rows(): Row[] {
  return [0, 1, 2].map((i) => ({
    id: `r${i}`,
    at: null,
    local: null,
    due: null
  }));
}

module('Integration | Component | EuiSheet dateTime', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet() {
    const store = localRecords(rows(), { getRecordId: getId });
    await render(
      <template>
        <div style="width:700px">
          <EuiSheet
            @records={{store.records}}
            @fields={{FIELDS}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
          />
        </div>
      </template>
    );
    return store;
  }

  test('DT5 typed in a utc field: the patch is the UTC instant, the cell shows it, copy and paste keep it', async function (assert) {
    const store = await renderSheet();
    await focusCell(0, 0);
    await type('1');
    assert
      .dom(editor())
      .hasAttribute('type', 'text', 'typing opens the text input');
    await fillIn(editor()!, '19/11/2026 15:30');
    await press('Enter');
    assert.deepEqual(store.log[0]!.patches, [
      {
        recordId: 'r0',
        fieldId: 'at',
        from: null,
        to: '2026-11-19T15:30:00.000Z'
      }
    ]);
    assert.strictEqual(text(0, 0), '19/11/2026 15:30', 'shown in the zone');
    await focusCell(0, 0);
    const copied = await clipboard('copy');
    assert.strictEqual(copied.text, '2026-11-19T15:30:00.000Z', 'copy: ISO');
    // the same instant pasted into the Mexico City field and another row
    await focusCell(1, 1);
    await clipboard('paste', copied.text);
    await focusCell(2, 0);
    await clipboard('paste', copied.text);
    assert.deepEqual(
      store.log.slice(1).map((set) => set.patches[0]?.to),
      ['2026-11-19T15:30:00.000Z', '2026-11-19T15:30:00.000Z'],
      'the same value'
    );
    assert.strictEqual(
      text(1, 1),
      '19/11/2026 9:30 am',
      'shown in its zone, 12-hour'
    );
    assert.strictEqual(text(2, 0), '19/11/2026 15:30');
    // a text that is not one
    await focusCell(1, 0);
    await clipboard('paste', '19/11/2026 25:00');
    assert.true(isInvalid(1, 0));
    assert.strictEqual(
      cellTitle(1, 0),
      '"19/11/2026 25:00" is not a date and time'
    );
  });

  test('DT5b the picker: the zone’s wall clock in, the instant out', async function (assert) {
    const store = await renderSheet();
    await focusCell(1, 1);
    await clipboard('paste', '2026-11-19T15:30:00.000Z');
    await focusCell(1, 1);
    await press('Enter');
    assert.dom(editor()).hasAttribute('type', 'datetime-local');
    assert.strictEqual(editor()?.value, '2026-11-19T09:30', 'Mexico City');
    await fillIn(editor()!, '2026-11-20T08:15');
    await press('Enter');
    assert.deepEqual(store.log[1]!.patches, [
      {
        recordId: 'r1',
        fieldId: 'local',
        from: '2026-11-19T15:30:00.000Z',
        to: '2026-11-20T14:15:00.000Z'
      }
    ]);
    await waitUntil(() => document.activeElement === cell(2, 1));
    await type('a');
    assert.strictEqual(editor(), null, 'a letter opens no editor');
  });

  test('DT6 a date field next to it behaves as before', async function (assert) {
    const store = await renderSheet();
    await focusCell(0, 2);
    await type('1');
    await fillIn(editor()!, '19/11/2026');
    await press('Enter');
    assert.deepEqual(store.log[0]!.patches, [
      { recordId: 'r0', fieldId: 'due', from: null, to: '2026-11-19' }
    ]);
    assert.strictEqual(text(0, 2), '19/11/2026');
    await focusCell(0, 2);
    await press('Enter');
    assert.dom(editor()).hasAttribute('type', 'date', 'its own picker');
    await press('Escape');
    // a dateTime pasted into the date field keeps only the date
    await focusCell(1, 2);
    await clipboard('paste', '2026-11-19T15:30:00.000Z');
    assert.strictEqual(store.log[1]!.patches[0]!.to, '2026-11-19');
  });
});
