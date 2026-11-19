/**
 * EuiSheet dead keys and IMEs (V02-DESIGN.md 8.6, IM1 to IM5). Synthetic
 * events: they prove the wiring, not what a browser does with real input.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, settled } from '@ember/test-helpers';
import { htmlSafe } from '@ember/template';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import {
  cell,
  editor,
  editorFrame,
  el,
  focusCell,
  press,
  text
} from '../../helpers/sheet.ts';

import type { EuiSheetField } from '#src/core/index.ts';

interface Row {
  id: string;
  name: string;
  code: string;
}

const getId = (row: Row) => row.id;

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name', label: 'Name' },
  { id: 'code', label: 'Code', readOnly: true }
];

function catcher(): HTMLInputElement {
  return el('[data-test-subj=euiSheetImeCatcher]') as HTMLInputElement;
}

/** A keydown on the focused element; whether it was prevented. */
async function keydown(init: KeyboardEventInit): Promise<boolean> {
  const event = new KeyboardEvent('keydown', {
    bubbles: true,
    cancelable: true,
    ...init
  });
  document.activeElement!.dispatchEvent(event);
  await settled();
  return event.defaultPrevented;
}

async function fire(target: Element, event: Event): Promise<void> {
  target.dispatchEvent(event);
  await settled();
}

module(
  'Integration | Component | EuiSheet IME and dead keys',
  function (hooks) {
    setupRenderingTest(hooks);

    async function renderSheet() {
      const store = localRecords<Row>(
        [
          { id: 'r0', name: 'Ana', code: 'A1' },
          { id: 'r1', name: 'Bo', code: 'B2' }
        ],
        { getRecordId: getId, fields: FIELDS }
      );
      await render(
        <template>
          <EuiSheet
            @records={{store.records}}
            @fields={{store.fields}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
          />
        </template>
      );
      return store;
    }

    test('IM1 a dead key focuses the catcher over the cell; the composed é opens the editor with it', async function (assert) {
      const store = await renderSheet();
      await focusCell(0, 0);
      assert.false(await keydown({ key: 'Dead' }), 'not prevented');
      assert.strictEqual(document.activeElement, catcher(), 'the catcher');
      const box = cell(0, 0).getBoundingClientRect();
      const input = catcher().getBoundingClientRect();
      assert.true(
        Math.abs(box.left - input.left) < 2 &&
          Math.abs(box.top - input.top) < 2,
        'over the cell'
      );
      assert.strictEqual(editorFrame(), null, 'no editor yet');
      // a dead key with no composition events: one input event
      catcher().value = 'é';
      await fire(
        catcher(),
        new InputEvent('input', {
          bubbles: true,
          data: 'é',
          isComposing: false
        })
      );
      assert.strictEqual(editor()?.value, 'é', 'the editor has é');
      assert.strictEqual(document.activeElement, editor());
      assert.strictEqual(catcher().value, '', 'the catcher is cleared');
      assert.dom(catcher()).doesNotHaveClass('euiSheet__ime--active');
      await press('Enter');
      assert.deepEqual(store.log[0]?.patches, [
        { recordId: 'r0', fieldId: 'name', from: 'Ana', to: 'é' }
      ]);
      assert.strictEqual(text(0, 0), 'é');
    });

    test('IM2 an IME composition (日本) opens the editor with the composed text', async function (assert) {
      await renderSheet();
      await focusCell(1, 0);
      assert.false(await keydown({ key: 'Process', keyCode: 229 }));
      assert.strictEqual(document.activeElement, catcher());
      await fire(
        catcher(),
        new CompositionEvent('compositionstart', { bubbles: true, data: '' })
      );
      catcher().value = 'にほん';
      await fire(
        catcher(),
        new InputEvent('input', {
          bubbles: true,
          data: 'にほん',
          isComposing: true
        })
      );
      assert.strictEqual(editorFrame(), null, 'nothing opens while composing');
      // Enter confirms the conversion: the IME's, not the sheet's
      assert.false(
        await keydown({ key: 'Enter', isComposing: true, keyCode: 229 })
      );
      catcher().value = '日本';
      await fire(
        catcher(),
        new CompositionEvent('compositionend', { bubbles: true, data: '日本' })
      );
      assert.strictEqual(editor()?.value, '日本');
      // a later input event of the same composition opens nothing more
      await fire(
        catcher(),
        new InputEvent('input', {
          bubbles: true,
          data: '日本',
          isComposing: false
        })
      );
      assert.strictEqual(editor()?.value, '日本');
    });

    test('IM3 Escape, or an empty composition, returns focus to the cell', async function (assert) {
      const store = await renderSheet();
      await focusCell(0, 0);
      await keydown({ key: 'Dead' });
      assert.strictEqual(document.activeElement, catcher());
      assert.true(await keydown({ key: 'Escape' }));
      assert.strictEqual(document.activeElement, cell(0, 0));
      assert.strictEqual(editorFrame(), null);
      await keydown({ key: 'Process', keyCode: 229 });
      await fire(
        catcher(),
        new CompositionEvent('compositionstart', { bubbles: true })
      );
      await fire(
        catcher(),
        new CompositionEvent('compositionend', { bubbles: true, data: '' })
      );
      assert.strictEqual(document.activeElement, cell(0, 0), 'empty: back');
      assert.strictEqual(store.log.length, 0);
    });

    test('IM4 a read-only cell ignores it', async function (assert) {
      await renderSheet();
      await focusCell(0, 1);
      assert.false(await keydown({ key: 'Dead' }));
      assert.strictEqual(document.activeElement, cell(0, 1), 'focus stays');
    });

    test('IM5 the catcher is not tabbable and is outside the grid', async function (assert) {
      await renderSheet();
      assert.dom(catcher()).hasAttribute('tabindex', '-1');
      assert.dom(catcher()).hasAttribute('aria-hidden', 'true');
      assert.false(el('.euiDataGrid').contains(catcher()));
      assert.true(el('.euiSheet').contains(catcher()));
    });

    test('IM7 a dead key on a far column survives the late scroll of its focus', async function (assert) {
      const fields: EuiSheetField<Row>[] = Array.from(
        { length: 14 },
        (_, i) => ({
          id: i === 0 ? 'name' : `f${i}`,
          label: `F${i}`,
          width: 150
        })
      );
      const store = localRecords<Row>([{ id: 'r0', name: 'Ana', code: '' }], {
        getRecordId: getId,
        fields
      });
      const style = htmlSafe('width:600px');
      await render(
        <template>
          <div style={{style}}>
            <EuiSheet
              @records={{store.records}}
              @fields={{store.fields}}
              @getRecordId={{getId}}
              @onChange={{store.apply}}
            />
          </div>
        </template>
      );
      const outer = el('.euiDataGrid__virtualized');
      await focusCell(0, 12);
      assert.true(outer.scrollLeft > 0, 'scrolled to the column');
      await keydown({ key: 'Dead' });
      assert.strictEqual(document.activeElement, catcher());
      // the focus's scroll event, late
      await fire(outer, new Event('scroll'));
      assert.strictEqual(
        document.activeElement,
        catcher(),
        'still composing there'
      );
      catcher().value = 'é';
      await fire(
        catcher(),
        new InputEvent('input', {
          bubbles: true,
          data: 'é',
          isComposing: false
        })
      );
      assert.strictEqual(editor()?.value, 'é', 'the editor opened with é');
    });

    test('IM6 a composing Enter in an open editor does not save', async function (assert) {
      const store = await renderSheet();
      await focusCell(0, 0);
      await press('Enter');
      assert.false(
        await keydown({ key: 'Enter', isComposing: true, keyCode: 229 }),
        'left to the IME'
      );
      assert.dom(editorFrame()).exists('still editing');
      assert.strictEqual(store.log.length, 0);
    });
  }
);
