/**
 * The `button` type (V03-DESIGN.md 10.3.1, BT1-BT4): a press calls
 * `@onButtonPress` with the record; pending and errors; disabled, a url
 * without a handler, neither; and the column under paste, fill, clear,
 * cut and copy. Also the expanded record's real button.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { registerWarnHandler } from '@ember/debug';
import { click, focus, render, settled } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import {
  cell,
  cellTitle,
  clipboard,
  el,
  focusCell,
  isInvalid,
  pressed,
  selected,
  type
} from '../../helpers/sheet.ts';

import type { ButtonField, EuiSheetField } from '#src/core/index.ts';
import type { SheetButtonPress } from '#src/types.ts';

interface Row {
  id: string;
  name: string;
  email: string;
}

const getId = (row: Row) => row.id;

function rows(): Row[] {
  return [0, 1, 2].map((i) => ({
    id: `r${i}`,
    name: `N${i}`,
    email: `n${i}@example.com`
  }));
}

/** Warnings by id while a test collects them (BT3). */
let warnings: string[] | null = null;
registerWarnHandler((message, options, next) => {
  if (warnings && options?.id) warnings.push(options.id);
  next(message, options);
});

/** A promise and its resolve and reject. */
function deferred(): {
  promise: Promise<unknown>;
  resolve: () => void;
  reject: (reason: unknown) => void;
} {
  let resolve!: () => void;
  let reject!: (reason: unknown) => void;
  const promise = new Promise<unknown>((res, rej) => {
    resolve = () => res(undefined);
    reject = rej;
  });
  return { promise, resolve, reject };
}

/** Lets a settled promise's handlers run, then the render. */
async function flush(): Promise<void> {
  await new Promise((resolve) => setTimeout(resolve));
  await settled();
}

function button(row: number, col = 1): HTMLElement {
  return el('[data-test-subj=euiSheetButton]', cell(row, col));
}

class State {
  store = localRecords(rows(), { getRecordId: getId });
  @tracked fields: EuiSheetField<Row>[] = [
    { id: 'name', label: 'Name' },
    {
      id: 'send',
      label: 'Send',
      type: 'button',
      buttonLabel: (record: Row) => `Send to ${record.name}`,
      icon: 'email'
    } as ButtonField<Row>,
    { id: 'email', label: 'Email' }
  ];
  presses: Array<[SheetButtonPress<Row>, AbortSignal]> = [];
  result: () => void | Promise<unknown> = () => undefined;
  @tracked handler:
    | ((
        press: SheetButtonPress<Row>,
        options: { signal: AbortSignal }
      ) => void | Promise<unknown>)
    | undefined = (press, { signal }) => {
    this.presses.push([press, signal]);
    return this.result();
  };
}

module('Integration | Component | EuiSheet button', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet(state: State): Promise<void> {
    await render(
      <template>
        <div style="width:700px">
          <EuiSheet
            @records={{state.store.records}}
            @fields={{state.fields}}
            @getRecordId={{getId}}
            @onChange={{state.store.apply}}
            @onButtonPress={{state.handler}}
          />
        </div>
      </template>
    );
  }

  test('BT1 a click on the button calls @onButtonPress once (selected or not); a click on the padding only selects; Enter and Space press it', async function (assert) {
    const state = new State();
    await renderSheet(state);
    assert.dom(button(0)).hasText('Send to N0');
    assert.dom(button(0)).hasAttribute('role', 'button');
    assert.dom(button(0)).doesNotHaveAttribute('tabindex');
    await click(button(0));
    assert.strictEqual(state.presses.length, 1, 'one call, not selected');
    const [press] = state.presses[0]!;
    assert.strictEqual(press.recordId, 'r0');
    assert.strictEqual(press.fieldId, 'send');
    assert.strictEqual(press.record, state.store.records[0]);
    // selected, then a click on the button: one more call
    await focusCell(1, 1);
    await click(button(1));
    assert.strictEqual(state.presses.length, 2);
    assert.strictEqual(state.presses[1]![0].recordId, 'r1');
    // the cell's padding: selects only
    await click(cell(2, 1));
    assert.deepEqual(selected(), ['2:1'], 'selected');
    assert.strictEqual(state.presses.length, 2, 'no call');
    await click(cell(2, 1));
    assert.strictEqual(state.presses.length, 2, 'a second click: still none');
    // keys on the selected cell
    assert.true(await pressed('Enter'), 'Enter is taken');
    assert.strictEqual(state.presses.length, 3);
    assert.strictEqual(state.presses[2]![0].recordId, 'r2');
    assert.true(await pressed(' '), 'Space is taken');
    assert.strictEqual(state.presses.length, 4);
    assert.dom('[data-test-subj=euiSheetEditor]').doesNotExist('no editor');
    assert.strictEqual(
      document.querySelector('[data-test-subj=euiSheetRecord]'),
      null,
      'Space does not expand the record'
    );
    assert.deepEqual(state.store.log, [], 'not a change set');
  });

  test('BT2 a promise makes the cell pending, a second press is ignored; a rejection is the cell’s error; the next resolve clears it', async function (assert) {
    const state = new State();
    let pending = deferred();
    state.result = () => pending.promise;
    await renderSheet(state);
    await focusCell(0, 1);
    await pressed('Enter');
    assert.strictEqual(state.presses.length, 1);
    assert.dom(cell(0, 1)).hasAttribute('aria-busy', 'true');
    assert.dom('[data-test-subj=euiSheetButtonPending]', cell(0, 1)).exists();
    await click(button(0));
    await pressed('Enter');
    assert.strictEqual(state.presses.length, 1, 'ignored while pending');
    // another row's button is not blocked
    await click(button(1));
    assert.strictEqual(state.presses.length, 2);
    pending.reject(new Error('No email address'));
    await flush();
    assert.dom(cell(0, 1)).doesNotHaveAttribute('aria-busy');
    assert.true(isInvalid(0, 1), 'the rejection is the cell’s error');
    assert.strictEqual(cellTitle(0, 1), 'No email address');
    assert
      .dom('[data-test-subj=euiSheetCellError]')
      .hasText('No email address', 'in the focused cell’s message box');
    // the next press clears it; its resolve leaves none
    pending = deferred();
    await click(button(0));
    assert.false(isInvalid(0, 1), 'cleared on the next press');
    assert.dom(cell(0, 1)).hasAttribute('aria-busy', 'true');
    pending.resolve();
    await flush();
    assert.false(isInvalid(0, 1));
    assert.dom(cell(0, 1)).doesNotHaveAttribute('aria-busy');
    // leaving the page aborts the signal
    pending = deferred();
    await click(button(2));
    const signal = state.presses[state.presses.length - 1]![1];
    assert.false(signal.aborted);
    await render(<template>gone</template>);
    assert.true(signal.aborted, 'aborted on destroy');
  });

  test('BT3 disabled(record): no call, aria-disabled; url without a handler opens it; neither: disabled and one dev warning', async function (assert) {
    const state = new State();
    state.fields = [
      { id: 'name', label: 'Name' },
      {
        id: 'send',
        label: 'Send',
        type: 'button',
        disabled: (record: Row) => record.id === 'r1',
        url: (record: Row) =>
          record.id === 'r2'
            ? 'javascript:alert(1)'
            : `https://example.com/${record.id}`
      } as ButtonField<Row>
    ];
    await renderSheet(state);
    assert.dom(button(1)).hasAttribute('aria-disabled', 'true');
    assert
      .dom(button(1))
      .hasText('Send', 'the field label without buttonLabel');
    assert.dom(button(0)).doesNotHaveAttribute('aria-disabled');
    await click(button(1));
    await focusCell(1, 1);
    await pressed('Enter');
    assert.strictEqual(state.presses.length, 0, 'disabled: no call');
    await click(button(0));
    assert.strictEqual(state.presses.length, 1, 'the handler wins over url');

    // url without the handler
    const opened: unknown[][] = [];
    const original = window.open;
    window.open = ((...args: unknown[]) => {
      opened.push(args);
      return null;
    }) as typeof window.open;
    try {
      state.handler = undefined;
      await settled();
      await click(button(0));
      assert.deepEqual(opened, [
        ['https://example.com/r0', '_blank', 'noopener']
      ]);
      assert
        .dom(button(2))
        .hasAttribute('aria-disabled', 'true', 'a javascript: url is no url');
      await click(button(2));
      assert.strictEqual(opened.length, 1, 'not opened');
    } finally {
      window.open = original;
    }

    // neither: disabled, one warning for the sheet
    warnings = [];
    try {
      state.fields = [
        { id: 'name', label: 'Name' },
        { id: 'send', label: 'Send', type: 'button' } as ButtonField<Row>
      ];
      await renderSheet(state);
      assert.dom(button(0)).hasAttribute('aria-disabled', 'true');
      assert.dom(button(2)).hasAttribute('aria-disabled', 'true');
      await click(button(0));
      assert.strictEqual(
        warnings.filter((id) => id === 'ember-eui.sheet.button-no-action')
          .length,
        1,
        `one warning (${warnings.join(', ')})`
      );
    } finally {
      warnings = null;
    }
  });

  test('BT4 paste, fill, clear and cut over a button column change nothing in it; copy gives the button texts', async function (assert) {
    const state = new State();
    await renderSheet(state);
    // copy a range over the three columns
    await focusCell(0, 0);
    await pressed('ArrowRight', { shiftKey: true });
    await pressed('ArrowRight', { shiftKey: true });
    await pressed('ArrowDown', { shiftKey: true });
    const copied = await clipboard('copy');
    assert.strictEqual(
      copied.text,
      'N0\tSend to N0\tn0@example.com\nN1\tSend to N1\tn1@example.com',
      'the button texts line up'
    );
    // paste it one row down: the text columns change, the button column not
    await click(cell(1, 0));
    await clipboard('paste', 'A\tB\tC\nD\tE\tF');
    const paste = state.store.log[0]!;
    assert.deepEqual(
      paste.patches.map((patch) => `${patch.recordId}.${patch.fieldId}`),
      ['r1.name', 'r1.email', 'r2.name', 'r2.email']
    );
    assert.deepEqual(paste.rejected, [], 'no rejection for the button cells');
    assert.false(isInvalid(1, 1));
    assert.dom(button(1)).hasText('Send to A', 'the button follows its record');
    // fill down over the three columns
    await click(cell(0, 0));
    await pressed('ArrowRight', { shiftKey: true });
    await pressed('ArrowRight', { shiftKey: true });
    await pressed('ArrowDown', { shiftKey: true });
    await pressed('d', { ctrlKey: true });
    const fill = state.store.log[1]!;
    assert.true(
      fill.patches.every((patch) => patch.fieldId !== 'send'),
      'fill skips the button column'
    );
    // clear (Delete) and cut
    await pressed('Delete');
    const clear = state.store.log[2]!;
    assert.strictEqual(clear.source, 'clear');
    assert.true(clear.patches.every((patch) => patch.fieldId !== 'send'));
    await click(cell(2, 0));
    await pressed('ArrowRight', { shiftKey: true });
    const cutEvent = new ClipboardEvent('cut', {
      clipboardData: new DataTransfer(),
      bubbles: true,
      cancelable: true
    });
    document.activeElement!.dispatchEvent(cutEvent);
    await settled();
    assert.strictEqual(
      cutEvent.clipboardData!.getData('text/plain'),
      'D\tSend to D',
      'cut copies the button text'
    );
    const cut = state.store.log[3]!;
    assert.strictEqual(cut.source, 'cut');
    assert.deepEqual(
      cut.patches.map((patch) => patch.fieldId),
      ['name'],
      'and clears only the other cell'
    );
    // one button cell: a paste writes nothing; a typed key says "Read only"
    const before = state.store.log.length;
    await click(cell(0, 1));
    await clipboard('paste', 'hello');
    assert.strictEqual(state.store.log.length, before, 'nothing emitted');
    assert.false(isInvalid(0, 1));
    await type('x');
    assert
      .dom('[data-test-subj=euiSheetCellError]')
      .hasText('Read only', 'the read-only cue');
    assert.dom('[data-test-subj=euiSheetEditor]').doesNotExist();
  });

  test('BT5 the expanded record draws a real button that presses the same way', async function (assert) {
    const state = new State();
    let pending = deferred();
    state.result = () => pending.promise;
    await renderSheet(state);
    await focus(cell(1, 0));
    await pressed(' ');
    const flyoutButton = el('[data-test-subj=euiSheetRecordButton]');
    assert.strictEqual(flyoutButton.tagName, 'BUTTON');
    assert.dom(flyoutButton).hasText('Send to N1');
    await click(flyoutButton);
    assert.strictEqual(state.presses.length, 1);
    assert.strictEqual(state.presses[0]![0].recordId, 'r1');
    pending.reject(new Error('Offline'));
    await flush();
    assert
      .dom(el('[data-test-subj=euiSheetRecordErrors]'))
      .hasText('Offline', 'the error under it');
    assert.true(isInvalid(1, 1), 'and on the cell');
    pending = deferred();
    await click(el('[data-test-subj=euiSheetRecordButton]'));
    assert.strictEqual(state.presses.length, 2);
    pending.resolve();
    await flush();
  });
});
