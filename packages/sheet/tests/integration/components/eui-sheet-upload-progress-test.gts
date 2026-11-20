/**
 * Upload progress (V03 11.4; UP1, UP3, UP4): `onProgress` in `upload`'s
 * options. UP2 (an uploader that never calls it is pending as before) is
 * the v0.2 attachment tests A1-A3, unchanged. While an upload is pending
 * `settled()` waits for it (the resolve waiter), so these tests use
 * `waitUntil`.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import {
  clearRender,
  focus,
  render,
  settled,
  triggerEvent,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import { cell, el } from '../../helpers/sheet.ts';

import type { EuiSheetField, SheetAttachment } from '#src/core/index.ts';
import type { SheetApi } from '#src/types.ts';

interface Row {
  id: string;
  name: string;
  files: SheetAttachment[];
}

const getId = (row: Row) => row.id;

/** An uploader the test drives: each call's progress callback, signal and promise. */
class Uploads {
  calls: Array<{
    files: File[];
    onProgress: (fraction: number) => void;
    signal: AbortSignal;
    resolve: (files: SheetAttachment[]) => void;
    reject: (error: Error) => void;
  }> = [];

  upload = (
    files: File[],
    context: { signal: AbortSignal; onProgress: (fraction: number) => void }
  ): Promise<SheetAttachment[]> =>
    new Promise((resolve, reject) => {
      this.calls.push({
        files,
        onProgress: context.onProgress,
        signal: context.signal,
        resolve,
        reject
      });
    });

  get last() {
    return this.calls[this.calls.length - 1]!;
  }
}

class State {
  @tracked shown = true;
  api: SheetApi | null = null;
  register = (api: SheetApi) => (this.api = api);
}

const PROGRESS = 'euiSheet__cellProgress';

/** Pastes files on the focused cell (they are uploaded to it). */
function pasteFiles(target: Element, ...names: string[]): void {
  const data = new DataTransfer();
  for (const name of names) data.items.add(new File(['x'], name));
  target.dispatchEvent(
    new ClipboardEvent('paste', {
      clipboardData: data,
      bubbles: true,
      cancelable: true
    })
  );
}

const hasBar = () => cell(0, 1).classList.contains(PROGRESS);

module('Integration | Component | EuiSheet upload progress', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet(uploads: Uploads, state = new State()) {
    const fields: EuiSheetField<Row>[] = [
      { id: 'name', label: 'Name' },
      {
        id: 'files',
        label: 'Files',
        type: 'attachment',
        upload: uploads.upload,
        width: 240
      } as EuiSheetField<Row>
    ];
    const store = localRecords<Row>(
      [
        { id: 'r0', name: 'a', files: [] },
        { id: 'r1', name: 'b', files: [] }
      ],
      { getRecordId: getId, fields }
    );
    await render(
      <template>
        {{#if state.shown}}
          <EuiSheet
            @records={{store.records}}
            @fields={{store.fields}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
            @registerApi={{state.register}}
          />
        {{/if}}
      </template>
    );
    return store;
  }

  test('UP1 onProgress(0.4): a bar at 40 % and the title; at resolve the bar is gone and the files are saved', async function (assert) {
    const uploads = new Uploads();
    const store = await renderSheet(uploads);
    await focus(cell(0, 1));
    pasteFiles(cell(0, 1), 'photo.png');
    await waitUntil(() => uploads.calls.length === 1);
    await waitUntil(() =>
      cell(0, 1).classList.contains('euiSheet__cell--pending')
    );
    assert.false(hasBar(), 'pending, no bar before any progress');
    uploads.last.onProgress(0.4);
    await waitUntil(hasBar);
    const target = cell(0, 1);
    assert.strictEqual(target.getAttribute('title'), 'Uploading… 40%');
    assert.strictEqual(target.getAttribute('aria-busy'), 'true');
    const bar = getComputedStyle(target, '::before');
    assert.strictEqual(bar.position, 'absolute');
    assert.strictEqual(bar.bottom, '0px', 'along the bottom edge');
    assert.strictEqual(bar.height, '2px');
    const width = parseFloat(bar.width);
    assert.ok(
      Math.abs(width - target.offsetWidth * 0.4) < 1,
      `40 % of the cell (${width} of ${target.offsetWidth})`
    );
    // clamped, in whole percents
    uploads.last.onProgress(1.7);
    await waitUntil(() => target.getAttribute('title') === 'Uploading… 100%');
    uploads.last.onProgress(0.123);
    await waitUntil(() => target.getAttribute('title') === 'Uploading… 12%');
    assert.ok(true, 'clamped to 100 %, rounded to 12 %');
    uploads.last.resolve([
      { id: 'u1', name: 'photo.png', url: 'https://example.com/photo.png' }
    ]);
    await settled();
    assert.false(hasBar(), 'no bar');
    assert.dom(cell(0, 1)).doesNotHaveClass('euiSheet__cell--pending');
    assert.strictEqual(cell(0, 1).getAttribute('title'), null);
    assert.deepEqual(
      store.records[0]!.files.map((file) => file.name),
      ['photo.png'],
      'saved'
    );
  });

  test('UP3 calls after the promise settled or after an abort are ignored', async function (assert) {
    const uploads = new Uploads();
    const state = new State();
    const store = await renderSheet(uploads, state);
    await focus(cell(0, 1));
    pasteFiles(cell(0, 1), 'a.txt');
    await waitUntil(() => uploads.calls.length === 1);
    const first = uploads.last;
    first.onProgress(0.5);
    await waitUntil(hasBar);
    first.resolve([{ id: 'u1', name: 'a.txt', url: 'https://example.com/a' }]);
    await settled();
    first.onProgress(0.9);
    await settled();
    assert.false(hasBar(), 'no bar after the promise settled');
    assert.strictEqual(cell(0, 1).getAttribute('title'), null);
    // a second upload, then the sheet goes away: its signal is aborted
    pasteFiles(cell(0, 1), 'b.txt');
    await waitUntil(() => uploads.calls.length === 2);
    const second = uploads.last;
    second.onProgress(0.3);
    await waitUntil(hasBar);
    state.shown = false;
    await waitUntil(() => !document.querySelector('[data-test-subj=euiSheet]'));
    assert.true(second.signal.aborted, 'aborted');
    second.onProgress(0.6);
    second.onProgress(Number.NaN);
    second.resolve([]);
    await settled();
    assert.strictEqual(store.log.length, 1, 'nothing written after the abort');
    await clearRender();
  });

  test('UP4 the attachment editor and the expanded record show the progress', async function (assert) {
    const uploads = new Uploads();
    const state = new State();
    await renderSheet(uploads, state);
    await focus(cell(0, 1));
    await triggerKeyEvent(cell(0, 1), 'keydown', 'Enter');
    const picker = el('[data-test-subj=euiSheetFilePicker]');
    assert
      .dom('[data-test-subj=euiSheetUploadProgress]', document.body)
      .doesNotExist('nothing before an upload');
    void triggerEvent(picker, 'change', {
      files: [new File(['x'], 'c.txt')]
    });
    await waitUntil(() => uploads.calls.length === 1);
    uploads.last.onProgress(0.25);
    await waitUntil(() =>
      document.querySelector('[data-test-subj=euiSheetUploadProgress]')
    );
    const bar = el('[data-test-subj=euiSheetUploadProgress]');
    assert.strictEqual(
      (bar.matches('progress') ? bar : el('progress', bar)).getAttribute(
        'value'
      ),
      '25'
    );
    assert.strictEqual(bar.getAttribute('title'), 'Uploading… 25%');
    uploads.last.resolve([
      { id: 'u1', name: 'c.txt', url: 'https://example.com/c' }
    ]);
    await settled();
    assert
      .dom('[data-test-subj=euiSheetUploadProgress]', document.body)
      .doesNotExist('gone at resolve');
    await triggerKeyEvent(document.activeElement!, 'keydown', 'Escape');
    // the expanded record: an upload started in the grid shows under its box
    await focus(cell(1, 1));
    pasteFiles(cell(1, 1), 'd.txt');
    await waitUntil(() => uploads.calls.length === 2);
    uploads.last.onProgress(0.6);
    state.api!.expandRecord('r1');
    await waitUntil(() =>
      document.querySelector('[data-test-subj=euiSheetRecordUploadProgress]')
    );
    const recordBar = el('[data-test-subj=euiSheetRecordUploadProgress]');
    assert.strictEqual(
      (recordBar.matches('progress')
        ? recordBar
        : el('progress', recordBar)
      ).getAttribute('value'),
      '60'
    );
    assert.true(
      el('[data-test-subj=euiSheetRecordField-files]').contains(recordBar),
      'in the Files field'
    );
    uploads.last.resolve([]);
    await settled();
    assert
      .dom('[data-test-subj=euiSheetRecordUploadProgress]', document.body)
      .doesNotExist();
  });
});
