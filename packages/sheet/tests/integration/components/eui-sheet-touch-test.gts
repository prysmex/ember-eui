/**
 * EuiSheet on touch screens (V02-DESIGN.md 8.5, TC1 to TC3): pointer events
 * with `pointerType: 'touch'` in headless Chromium, not a real device.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, fillIn, render, settled } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import { cell, el, press, selected } from '../../helpers/sheet.ts';

import type { EuiSheetField } from '#src/core/index.ts';

interface Row {
  id: string;
  name: string;
  site: string;
}

const getId = (row: Row) => row.id;

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name', label: 'Name' },
  { id: 'site', label: 'Site', type: 'url' }
];

function rows(): Row[] {
  return [
    { id: 'r0', name: 'Ana', site: 'example.com' },
    { id: 'r1', name: 'Bo', site: '' }
  ];
}

/** A touch pointer event at the middle of `target` (plus an offset). */
function touch(type: string, target: Element, dx = 0, dy = 0): PointerEvent {
  const box = target.getBoundingClientRect();
  return new PointerEvent(type, {
    bubbles: true,
    cancelable: true,
    pointerType: 'touch',
    isPrimary: true,
    pointerId: 7,
    clientX: box.left + box.width / 2 + dx,
    clientY: box.top + box.height / 2 + dy
  });
}

const menu = () => document.querySelector('[data-test-subj=euiSheetRowMenu]');

module('Integration | Component | EuiSheet touch', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet(editIn?: 'cell' | 'record' | 'auto') {
    const store = localRecords<Row>(rows(), {
      getRecordId: getId,
      fields: FIELDS
    });
    await render(
      <template>
        <EuiSheet
          @records={{store.records}}
          @fields={{store.fields}}
          @getRecordId={{getId}}
          @onChange={{store.apply}}
          @editIn={{editIn}}
        />
      </template>
    );
    return store;
  }

  test('TC1 a long press opens the row menu and swallows the click', async function (assert) {
    const opened: unknown[] = [];
    const original = window.open;
    window.open = ((...args: unknown[]) => {
      opened.push(args);
      return null;
    }) as typeof window.open;
    try {
      await renderSheet();
      const link = el('[data-eui-sheet-link]', cell(0, 1));
      link.dispatchEvent(touch('pointerdown', link));
      assert.strictEqual(menu(), null, 'not yet');
      // the 500 ms timer is a run loop timer: settled() waits for it
      await settled();
      assert.ok(menu(), 'the menu opened');
      assert.deepEqual(selected(), ['0:1'], 'on the pressed cell');
      // Android also fires contextmenu on a long press: no second menu, no
      // browser menu
      const event = new MouseEvent('contextmenu', {
        bubbles: true,
        cancelable: true
      });
      link.dispatchEvent(event);
      await settled();
      assert.true(event.defaultPrevented);
      assert
        .dom('[data-test-subj=euiSheetRowMenu]', document.body)
        .exists({ count: 1 });
      link.dispatchEvent(touch('pointerup', link));
      // the compatibility mouse events and the click the browser may send
      await click(link);
      assert.ok(menu(), 'still open');
      assert.strictEqual(opened.length, 0, 'the link did not open');
      // the next tap is a tap again
      link.dispatchEvent(touch('pointerdown', link));
      link.dispatchEvent(touch('pointerup', link));
      await click(link);
      assert.strictEqual(opened.length, 1, 'a later tap opens the link');
    } finally {
      window.open = original;
    }
  });

  test('TC2 a touch that moves (a scroll) or is cancelled opens nothing', async function (assert) {
    await renderSheet();
    const target = cell(1, 0);
    target.dispatchEvent(touch('pointerdown', target));
    target.dispatchEvent(touch('pointermove', target, 0, 20));
    await settled();
    assert.strictEqual(menu(), null, 'moved 20 px');
    target.dispatchEvent(touch('pointerdown', target));
    target.dispatchEvent(touch('pointermove', target, 0, 4));
    target.dispatchEvent(touch('pointercancel', target));
    await settled();
    assert.strictEqual(menu(), null, 'a native pan cancels it');
    // a mouse press never starts one
    target.dispatchEvent(
      new PointerEvent('pointerdown', {
        bubbles: true,
        pointerType: 'mouse',
        isPrimary: true
      })
    );
    await settled();
    assert.strictEqual(menu(), null);
  });

  test('TC3 @editIn="record": the second tap opens the expanded record with the editor mounted', async function (assert) {
    const store = await renderSheet('record');
    await click(cell(1, 0));
    assert
      .dom('[data-test-subj=euiSheetRecord]', document.body)
      .doesNotExist('the first tap selects');
    await click(cell(1, 0));
    assert
      .dom('[data-test-subj=euiSheetRecord]', document.body)
      .exists('the record opened');
    const input = el(
      '[data-test-subj=euiSheetRecord] .euiSheet__editor--inline input'
    ) as HTMLInputElement;
    assert.strictEqual(input.value, 'Bo', 'the Name editor is mounted');
    assert.strictEqual(document.activeElement, input, 'and focused');
    assert.strictEqual(
      el('.euiSheet').querySelector('.euiSheet__editor'),
      null,
      'no editor in the grid'
    );
    await fillIn(input, 'Bea');
    await press('Enter');
    assert.deepEqual(store.log[0]?.patches, [
      { recordId: 'r1', fieldId: 'name', from: 'Bo', to: 'Bea' }
    ]);
    // Enter on a cell opens it the same way
    await click(el('[data-test-subj=euiFlyoutCloseButton]', document.body));
    await click(cell(0, 0));
    await press('Enter');
    assert
      .dom(
        '[data-test-subj=euiSheetRecord] .euiSheet__editor--inline input',
        document.body
      )
      .exists();
  });

  test('TC3b @editIn="auto" edits in the cell with a fine pointer', async function (assert) {
    await renderSheet('auto');
    await click(cell(0, 0));
    await click(cell(0, 0));
    assert.dom('[data-test-subj=euiSheetRecord]', document.body).doesNotExist();
    assert.dom('.euiSheet .euiSheet__editor').exists();
  });
});
