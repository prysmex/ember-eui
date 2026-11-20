/**
 * App items in the header menu (v0.4 03, FA1-FA5): `@fieldActions`.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { click, render, settled, waitUntil } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { el } from '../../helpers/sheet.ts';

import type { EuiSheetField } from '#src/core/index.ts';
import type { SheetFieldAction } from '#src/types.ts';

interface Row {
  id: string;
  name: string;
  city: string;
  qty: number;
}

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name', label: 'Name' },
  { id: 'city', label: 'City' },
  { id: 'qty', label: 'Qty', type: 'number' }
];

const ROWS: Row[] = [
  { id: 'a', name: 'Ana', city: 'Lima', qty: 1 },
  { id: 'b', name: 'Beto', city: 'Quito', qty: 2 }
];

const getId = (row: Row) => row.id;

class State {
  @tracked fieldActions: SheetFieldAction<Row>[] | undefined = undefined;
  onFieldDelete: ((id: string) => void) | undefined = undefined;
  onChange = () => {};
}

async function renderSheet(state: State): Promise<void> {
  await render(
    <template>
      <EuiSheet
        @fields={{FIELDS}}
        @records={{ROWS}}
        @getRecordId={{getId}}
        @onChange={{state.onChange}}
        @fieldActions={{state.fieldActions}}
        @onFieldDelete={{state.onFieldDelete}}
      />
    </template>
  );
}

const menuButton = (fieldId: string) =>
  el(`[data-test-subj=dataGridHeaderCellActionButton-${fieldId}]`);

async function openMenu(fieldId: string): Promise<HTMLElement[]> {
  await click(menuButton(fieldId));
  await waitUntil(() =>
    document.querySelector(
      `[data-test-subj=dataGridHeaderCellActionGroup-${fieldId}]`
    )
  );
  return Array.from(
    document.querySelectorAll<HTMLElement>(
      `[data-test-subj=dataGridHeaderCellActionGroup-${fieldId}] button`
    )
  );
}

async function frame(): Promise<void> {
  await new Promise((resolve) => requestAnimationFrame(resolve));
  await new Promise((resolve) => setTimeout(resolve));
  await settled();
}

const item = (actionId: string, fieldId: string) =>
  `[data-test-subj=euiSheetFieldAction-${actionId}-${fieldId}]`;

module('Integration | Component | EuiSheet field actions', function (hooks) {
  setupRenderingTest(hooks);

  test('FA1 an action is in every field`s menu (the first field gets one); a click calls onSelect with that field', async function (assert) {
    const state = new State();
    const got: string[] = [];
    state.fieldActions = [
      {
        id: 'history',
        label: 'Show history',
        icon: 'clock',
        onSelect: (field) => got.push(field.id)
      }
    ];
    await renderSheet(state);
    for (const field of FIELDS) {
      await openMenu(field.id);
      assert
        .dom(item('history', field.id), document.body)
        .hasText('Show history', `on ${field.id}`);
      await click(el(item('history', field.id)));
      await frame();
      assert
        .dom(`[data-test-subj=dataGridHeaderCellActionGroup-${field.id}]`)
        .doesNotExist('the menu closed');
    }
    assert.deepEqual(got, ['name', 'city', 'qty']);
  });

  test('FA2 isDisabled disables it on one field only', async function (assert) {
    const state = new State();
    const got: string[] = [];
    state.fieldActions = [
      {
        id: 'sum',
        label: 'Summarize',
        isDisabled: (field) => field.type !== 'number',
        onSelect: (field) => got.push(field.id)
      }
    ];
    await renderSheet(state);
    await openMenu('city');
    assert.dom(item('sum', 'city'), document.body).isDisabled();
    await click(menuButton('city'));
    await frame();
    await openMenu('qty');
    assert.dom(item('sum', 'qty'), document.body).isNotDisabled();
    await click(el(item('sum', 'qty')));
    await frame();
    assert.deepEqual(got, ['qty']);
  });

  test('FA3 the app items come after the sheet`s own, in order, before "Delete field"', async function (assert) {
    const state = new State();
    state.onFieldDelete = () => {};
    state.fieldActions = [
      { id: 'one', label: 'One', onSelect: () => {} },
      { id: 'two', label: 'Two', color: 'danger', onSelect: () => {} }
    ];
    await renderSheet(state);
    const labels = (await openMenu('city')).map(
      (button) => button.textContent?.trim() ?? ''
    );
    const at = (label: string) => labels.indexOf(label);
    assert.true(at('One') > at('Fit to content'), labels.join(', '));
    assert.strictEqual(at('Two'), at('One') + 1);
    assert.strictEqual(at('Delete field'), at('Two') + 1);
    assert.strictEqual(at('Delete field'), labels.length - 1, 'Delete last');
  });

  test('FA4 focus is back on the header`s menu button when onSelect runs; focus it moves stays', async function (assert) {
    const state = new State();
    let focused: Element | null = null;
    state.fieldActions = [
      {
        id: 'lock',
        label: 'Lock field',
        onSelect: () => (focused = document.activeElement)
      },
      {
        id: 'rename',
        label: 'Rename',
        // an app's own dialog takes focus
        onSelect: () => el('[data-test-outside]').focus()
      }
    ];
    await renderSheet(state);
    const outside = document.createElement('input');
    outside.dataset['testOutside'] = '';
    el('[data-test-subj=euiSheet]').after(outside);
    await openMenu('city');
    await click(el(item('lock', 'city')));
    await frame();
    assert.strictEqual(focused, menuButton('city'), 'on the menu button');
    await openMenu('city');
    await click(el(item('rename', 'city')));
    await frame();
    // past the popover's closing transition
    await new Promise((resolve) => setTimeout(resolve, 400));
    assert.strictEqual(document.activeElement, outside, 'not taken back');
    outside.remove();
  });

  test('FA5 without @fieldActions the menus are as before', async function (assert) {
    const state = new State();
    await renderSheet(state);
    assert
      .dom('[data-test-subj=dataGridHeaderCellActionButton-name]')
      .doesNotExist('the first field has no menu');
    await openMenu('city');
    assert
      .dom('[data-test-subj^=euiSheetFieldAction-]', document.body)
      .doesNotExist();
  });
});
