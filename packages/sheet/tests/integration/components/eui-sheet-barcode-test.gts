/**
 * The `barcode` type in the sheet (V03-DESIGN.md 10.3.2, BC2, BC3): the
 * scan panel with a stubbed `field.scan`, Escape, a refused camera, and
 * no scanning at all (typing, as a USB scanner does). The camera path
 * itself (BarcodeDetector on a real stream) is not run here.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, fillIn, render, settled, waitUntil } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { barcodeDevice } from '#src/-private/editors/barcode-scan.gts';
import { localRecords } from '#src/local-records.ts';
import {
  cell,
  editor,
  el,
  focusCell,
  press,
  text,
  type
} from '../../helpers/sheet.ts';

import type { BarcodeField, EuiSheetField } from '#src/core/index.ts';

interface Row {
  id: string;
  name: string;
  code: string | null;
}

const getId = (row: Row) => row.id;

function rows(): Row[] {
  return [0, 1, 2].map((i) => ({ id: `r${i}`, name: `N${i}`, code: null }));
}

/** Waits for promise handlers and the render after them. */
async function flush(): Promise<void> {
  await new Promise((resolve) => setTimeout(resolve));
  await settled();
}

module('Integration | Component | EuiSheet barcode', function (hooks) {
  setupRenderingTest(hooks);

  const original = { ...barcodeDevice };
  hooks.afterEach(function () {
    barcodeDevice.detector = original.detector;
    barcodeDevice.camera = original.camera;
  });

  async function renderSheet(code: BarcodeField<Row>) {
    const store = localRecords(rows(), { getRecordId: getId });
    const fields: EuiSheetField<Row>[] = [{ id: 'name', label: 'Name' }, code];
    await render(
      <template>
        <div style="width:600px">
          <EuiSheet
            @records={{store.records}}
            @fields={{fields}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
          />
        </div>
      </template>
    );
    return store;
  }

  test('BC2 the scan panel with a stubbed field.scan commits what it reads and closes; Escape aborts the signal', async function (assert) {
    const calls: Array<{ formats?: string[]; signal: AbortSignal }> = [];
    let answer: (text: string | null) => void = () => {};
    const store = await renderSheet({
      id: 'code',
      label: 'Code',
      type: 'barcode',
      formats: ['ean_13'],
      scan: (options) => {
        calls.push(options);
        return new Promise((resolve) => (answer = resolve));
      }
    });
    await focusCell(0, 1);
    // the opener is a camera: it opens the editor already scanning
    await click(el('[data-test-subj=euiSheetOpener]', cell(0, 1)));
    await flush();
    assert.dom('[data-test-subj=euiSheetScan]').exists('the panel');
    assert.strictEqual(calls.length, 1, 'field.scan called');
    assert.deepEqual(calls[0]!.formats, ['ean_13']);
    answer('7501234567890');
    await flush();
    assert.deepEqual(store.log[0]!.patches, [
      { recordId: 'r0', fieldId: 'code', from: null, to: '7501234567890' }
    ]);
    assert.strictEqual(editor(), null, 'the editor closed');
    assert.dom('[data-test-subj=euiSheetScan]').doesNotExist();
    assert
      .dom('[data-test-subj=euiSheetBarcode]', cell(0, 1))
      .hasText('7501234567890');

    // Enter opens the text input; its camera button opens the panel
    await focusCell(1, 1);
    await press('Enter');
    assert.dom('[data-test-subj=euiSheetScan]').doesNotExist('not scanning');
    await click(el('[data-test-subj=euiSheetScanButton]'));
    await flush();
    assert.strictEqual(calls.length, 2);
    const signal = calls[1]!.signal;
    assert.false(signal.aborted);
    // Escape closes the editor and aborts the scan
    await press('Escape');
    assert.strictEqual(editor(), null);
    assert.true(signal.aborted, 'Escape aborts the signal');
    answer('late');
    await flush();
    assert.strictEqual(store.log.length, 1, 'a late answer writes nothing');

    // Cancel in the panel stops it and keeps the text input
    await focusCell(2, 1);
    await click(el('[data-test-subj=euiSheetOpener]', cell(2, 1)));
    await flush();
    const third = calls[2]!.signal;
    await click(el('[data-test-subj=euiSheetScanCancel]'));
    assert.true(third.aborted, 'Cancel aborts it');
    assert.dom('[data-test-subj=euiSheetScan]').doesNotExist();
    assert.ok(editor(), 'the input stays');
    await fillIn(editor()!, ' ABC-1 ');
    await press('Enter');
    assert.strictEqual(store.log[1]!.patches[0]!.to, 'ABC-1', 'typed, trimmed');
  });

  test('BC2b the camera path: a refused camera shows cameraDenied; no field.scan, a detector: the opener is there', async function (assert) {
    class FakeDetector {
      detect(): Promise<Array<{ rawValue: string }>> {
        return Promise.resolve([]);
      }
    }
    barcodeDevice.detector = () =>
      FakeDetector as unknown as ReturnType<typeof barcodeDevice.detector>;
    barcodeDevice.camera = () => () =>
      Promise.reject(new DOMException('denied', 'NotAllowedError'));
    await renderSheet({ id: 'code', label: 'Code', type: 'barcode' });
    await focusCell(0, 1);
    await click(el('[data-test-subj=euiSheetOpener]', cell(0, 1)));
    await waitUntil(() =>
      document.querySelector('[data-test-subj=euiSheetScanError]')
    );
    assert
      .dom('[data-test-subj=euiSheetScanError]')
      .hasText('The camera is not available or was not allowed');
    await press('Escape');
    assert.strictEqual(editor(), null);
  });

  test('BC3 no field.scan and no BarcodeDetector: no camera opener; typing then Enter commits and moves down', async function (assert) {
    barcodeDevice.detector = () => undefined;
    const store = await renderSheet({
      id: 'code',
      label: 'Code',
      type: 'barcode'
    });
    await focusCell(0, 1);
    assert
      .dom('[data-test-subj=euiSheetOpener]', cell(0, 1))
      .doesNotExist('no camera opener');
    // a USB scanner types the code and Enter
    await type('7');
    assert.strictEqual(editor()?.value, '7');
    assert.dom('[data-test-subj=euiSheetScanButton]').doesNotExist();
    await fillIn(editor()!, '7501234567890');
    await press('Enter');
    assert.deepEqual(store.log[0]!.patches, [
      { recordId: 'r0', fieldId: 'code', from: null, to: '7501234567890' }
    ]);
    await waitUntil(() => document.activeElement === cell(1, 1));
    assert.strictEqual(text(0, 1), '7501234567890');
    // the next one, in a row
    await type('4');
    await fillIn(editor()!, '4006381333931');
    await press('Enter');
    assert.strictEqual(store.log[1]!.patches[0]!.recordId, 'r1');
    await waitUntil(() => document.activeElement === cell(2, 1));
  });
});
