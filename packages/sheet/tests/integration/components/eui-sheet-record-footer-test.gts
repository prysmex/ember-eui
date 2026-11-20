/**
 * A block below the expanded record's fields (v0.4 04, RFT1-RFT4):
 * `<:recordFooter as |record sheet|>`. The prefix is RFT: RF is the
 * expanded record's own tests (and the polish tests' range outline).
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import {
  click,
  fillIn,
  render,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import { el, focusCell, pressed } from '../../helpers/sheet.ts';

import type { EuiSheetField } from '#src/core/index.ts';

interface Row {
  id: string;
  name: string;
  qty: number;
}

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name', label: 'Name' },
  { id: 'qty', label: 'Qty', type: 'number' }
];
const HIDDEN: EuiSheetField<Row>[] = [{ id: 'notes', label: 'Notes' }];

const rows = (): Row[] => [
  { id: 'a', name: 'Ana', qty: 1 },
  { id: 'b', name: 'Beto', qty: 2 },
  { id: 'c', name: 'Caro', qty: 3 }
];

const getId = (row: Row) => row.id;

class State {
  @tracked shell: 'flyout' | 'modal' | undefined = undefined;
  @tracked footer = true;
  typed: string[] = [];
  onInput = (event: Event) =>
    this.typed.push((event.target as HTMLInputElement).value);
}

const shell = () =>
  document.querySelector<HTMLElement>('[data-test-subj=euiSheetRecord]');
const footer = () =>
  document.querySelector<HTMLElement>('[data-test-subj=euiSheetRecordFooter]');
const comment = () =>
  el('[data-test-comment]', document.body) as HTMLInputElement;

module('Integration | Component | EuiSheet record footer', function (hooks) {
  setupRenderingTest(hooks);

  async function renderSheet(state: State) {
    const store = localRecords<Row>(rows(), { getRecordId: getId });
    await render(
      <template>
        <div style="width:800px">
          {{#if state.footer}}
            <EuiSheet
              @records={{store.records}}
              @fields={{FIELDS}}
              @hiddenFields={{HIDDEN}}
              @getRecordId={{getId}}
              @onChange={{store.apply}}
              @expandedRecord={{state.shell}}
            >
              <:recordFooter as |record sheet|>
                <p data-test-for>Comments on
                  {{record.name}}
                  ({{sheet.fields.length}}
                  fields)</p>
                <input
                  aria-label="Comment"
                  data-test-comment
                  {{on "input" state.onInput}}
                />
                <button type="button" data-test-post>Post</button>
              </:recordFooter>
            </EuiSheet>
          {{else}}
            <EuiSheet
              @records={{store.records}}
              @fields={{FIELDS}}
              @hiddenFields={{HIDDEN}}
              @getRecordId={{getId}}
              @onChange={{store.apply}}
              @expandedRecord={{state.shell}}
            />
          {{/if}}
        </div>
      </template>
    );
    return store;
  }

  async function openOn(row: number) {
    await focusCell(row, 0);
    await pressed(' ');
    await waitUntil(() => shell());
  }

  for (const kind of ['flyout', 'modal'] as const) {
    test(`RFT1 the block renders with the record and the block API, after the fields and the hidden ones (${kind})`, async function (assert) {
      const state = new State();
      state.shell = kind;
      await renderSheet(state);
      await openOn(1);
      assert.strictEqual(shell()!.dataset['euiSheetRecord'], kind);
      assert
        .dom('[data-test-for]', document.body)
        .hasText('Comments on Beto (2 fields)');
      const fieldsEnd = shell()!.querySelector(
        '[data-test-subj=euiSheetRecordField-notes]'
      )!;
      assert.strictEqual(
        fieldsEnd.compareDocumentPosition(footer()!) &
          Node.DOCUMENT_POSITION_FOLLOWING,
        Node.DOCUMENT_POSITION_FOLLOWING,
        'after the hidden fields'
      );
      assert.true(shell()!.contains(footer()), 'inside the shell');
      assert.true(
        parseFloat(getComputedStyle(footer()!).borderTopWidth) > 0,
        'a divider'
      );
    });
  }

  test('RFT2 the next arrow re-renders it with the next record', async function (assert) {
    const state = new State();
    await renderSheet(state);
    await openOn(0);
    assert.dom('[data-test-for]', document.body).hasText(/Ana/);
    await click(el('[data-test-subj=euiSheetRecordNext]', document.body));
    assert.dom('[data-test-for]', document.body).hasText(/Beto/);
    await click(el('[data-test-subj=euiSheetRecordNext]', document.body));
    assert.dom('[data-test-for]', document.body).hasText(/Caro/);
    await click(el('[data-test-subj=euiSheetRecordPrevious]', document.body));
    assert.dom('[data-test-for]', document.body).hasText(/Beto/);
  });

  for (const kind of ['flyout', 'modal'] as const) {
    test(`RFT3 typing in the block types there: no field editor opens, Escape there keeps the record open (${kind})`, async function (assert) {
      const state = new State();
      state.shell = kind;
      const store = await renderSheet(state);
      await openOn(0);
      comment().focus();
      // a printable key on a record box would open its editor
      const prevented = await pressed('x');
      assert.false(prevented, 'the key is the input`s');
      await fillIn(comment(), 'Looks good');
      assert.deepEqual(state.typed, ['Looks good']);
      assert
        .dom('[data-test-subj=euiSheetEditor]', document.body)
        .doesNotExist('no field editor');
      assert.strictEqual(document.activeElement, comment());
      for (const k of ['Enter', 'Delete', 'Backspace', ' ']) {
        await triggerKeyEvent(comment(), 'keydown', k);
      }
      assert.strictEqual(store.log.length, 0, 'no change set');
      assert.ok(shell(), 'still open');
      await triggerKeyEvent(comment(), 'keydown', 'Escape');
      assert.ok(shell(), 'Escape in the input does not close the record');
      // Escape elsewhere in the block (its button) closes it as before
      el('[data-test-post]', document.body).focus();
      await triggerKeyEvent(
        el('[data-test-post]', document.body),
        'keydown',
        'Escape'
      );
      await waitUntil(() => !shell());
      assert.notOk(shell(), 'Escape on the button closes it');
    });
  }

  test('RFT4 without the block the record has no footer', async function (assert) {
    const state = new State();
    state.footer = false;
    await renderSheet(state);
    await openOn(0);
    assert.notOk(footer());
    assert
      .dom('.euiSheetRecord__footer', document.body)
      .doesNotExist('no empty footer box');
  });
});
