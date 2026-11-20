/**
 * Copy with field names (v0.4 05, CN1-CN4): the row menu's item with
 * `@copyWithFieldNames`, next to "Copy".
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { click, render, triggerEvent } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import { cell, el } from '../../helpers/sheet.ts';

import type { EuiSheetField } from '#src/core/index.ts';

interface Row {
  id: string;
  name: string;
  city: string;
  qty: number;
}

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name', label: 'Name' },
  { id: 'city' },
  { id: 'qty', label: 'Qty', type: 'number' }
];

const rows = (): Row[] => [
  { id: 'a', name: 'Ana', city: 'Lima', qty: 1 },
  { id: 'b', name: 'Beto', city: 'Quito', qty: 2 },
  { id: 'c', name: 'Caro', city: 'Cali', qty: 3 }
];

const getId = (row: Row) => row.id;

class State {
  @tracked fields = FIELDS;
  @tracked copyWithFieldNames: boolean | undefined = true;
}

function rowCell(row: number): HTMLElement {
  return el(
    `[role=gridcell][data-gridcell-visible-row-index="${row}"][data-gridcell-column-index="0"]`
  );
}

async function rightClick(element: HTMLElement): Promise<void> {
  const box = element.getBoundingClientRect();
  const point = { clientX: box.left + 5, clientY: box.top + 5 };
  await triggerEvent(element, 'mousedown', { button: 2, ...point });
  await triggerEvent(element, 'contextmenu', { button: 2, ...point });
}

const itemIds = () =>
  Array.from(
    document.querySelectorAll<HTMLElement>('[data-test-subj^=euiSheetRowMenu-]')
  ).map((item) => item.dataset['testSubj']!.replace('euiSheetRowMenu-', ''));

module('Integration | Component | EuiSheet copy with names', function (hooks) {
  setupRenderingTest(hooks);

  let written: string[] = [];
  let original: PropertyDescriptor | undefined;
  const clip = () =>
    navigator.clipboard as unknown as {
      writeText: (text: string) => Promise<void>;
    };
  hooks.beforeEach(function () {
    written = [];
    original = Object.getOwnPropertyDescriptor(clip(), 'writeText');
    Object.defineProperty(clip(), 'writeText', {
      configurable: true,
      value: (value: string) => {
        written.push(value);
        return Promise.resolve();
      }
    });
  });
  hooks.afterEach(function () {
    if (original) Object.defineProperty(clip(), 'writeText', original);
    else delete (clip() as { writeText?: unknown }).writeText;
  });

  async function renderSheet(state: State) {
    const store = localRecords<Row>(rows(), { getRecordId: getId });
    await render(
      <template>
        <EuiSheet
          @records={{store.records}}
          @fields={{state.fields}}
          @getRecordId={{getId}}
          @onChange={{store.apply}}
          @copyWithFieldNames={{state.copyWithFieldNames}}
        />
      </template>
    );
    return store;
  }

  test('CN1 from the menu on one row: every visible field`s label (or id), then that row', async function (assert) {
    await renderSheet(new State());
    await rightClick(cell(1, 1));
    const ids = itemIds();
    assert.strictEqual(
      ids.indexOf('copyWithNames'),
      ids.indexOf('copy') + 1,
      `next to Copy: ${ids.join(', ')}`
    );
    assert
      .dom('[data-test-subj=euiSheetRowMenu-copyWithNames]', document.body)
      .hasText('Copy with field names');
    await click(el('[data-test-subj=euiSheetRowMenu-copyWithNames]'));
    assert.deepEqual(written, ['Name\tcity\tQty\nBeto\tQuito\t2']);
    assert
      .dom('[data-test-subj=euiSheetRowMenu]', document.body)
      .doesNotExist('the menu closed');
    assert.strictEqual(document.activeElement, cell(1, 1), 'focus back');
  });

  test('CN2 with two checked rows: the labels, then those rows in order', async function (assert) {
    await renderSheet(new State());
    await click(el('[data-eui-sheet-row-check]', rowCell(2)));
    await click(el('[data-eui-sheet-row-check]', rowCell(0)));
    await rightClick(rowCell(2));
    await click(el('[data-test-subj=euiSheetRowMenu-copyWithNames]'));
    assert.deepEqual(written, ['Name\tcity\tQty\nAna\tLima\t1\nCaro\tCali\t3']);
  });

  test('CN3 a label with a tab or a line break is quoted, like any cell', async function (assert) {
    const state = new State();
    state.fields = [
      { id: 'name', label: 'Full\tname' },
      { id: 'city', label: 'City\n(home)' },
      { id: 'qty', label: '"Qty"', type: 'number' }
    ];
    await renderSheet(state);
    await rightClick(rowCell(0));
    await click(el('[data-test-subj=euiSheetRowMenu-copyWithNames]'));
    assert.deepEqual(written, [
      '"Full\tname"\t"City\n(home)"\t"""Qty"""\nAna\tLima\t1'
    ]);
  });

  test('CN4 without @copyWithFieldNames the menu is as before', async function (assert) {
    const state = new State();
    state.copyWithFieldNames = undefined;
    await renderSheet(state);
    await rightClick(cell(0, 0));
    assert.false(itemIds().includes('copyWithNames'));
    assert.true(itemIds().includes('copy'));
  });
});
