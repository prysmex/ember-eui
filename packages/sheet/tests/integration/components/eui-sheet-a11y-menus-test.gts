/**
 * Accessibility of the sheet's floating parts (READINESS.md item 3): the
 * row menu is a menu of menuitems, the field editor a named dialog (the
 * delete confirmation described by its question), the shortcut list a
 * focusable region (a list taller than the modal scrolls by keyboard).
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  render,
  settled,
  triggerEvent,
  waitUntil
} from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import { cell, el, focusCell, pressed } from '../../helpers/sheet.ts';

import type { SheetApi } from '#src/index.ts';
import type { EuiSheetField } from '#src/core/index.ts';

interface Item {
  id: string;
  name: string;
  code: string;
}

const FIELDS: EuiSheetField<Item>[] = [
  { id: 'name', label: 'Name' },
  { id: 'code', label: 'Code' }
];

const ITEMS = (): Item[] => [
  { id: 'a', name: 'Gloves', code: 'G1' },
  { id: 'b', name: 'Masks', code: 'M1' }
];

const getId = (item: { id: string }) => item.id;

/** A frame and a timeout: the focus trap and the popover settle. */
async function frame(): Promise<void> {
  await new Promise((resolve) => requestAnimationFrame(resolve));
  await new Promise((resolve) => setTimeout(resolve));
  await settled();
}

const byTest = (id: string) =>
  document.querySelector<HTMLElement>(`[data-test-subj="${id}"]`);

module(
  'Integration | Component | EuiSheet accessibility of menus and dialogs',
  function (hooks) {
    setupRenderingTest(hooks);

    async function renderSheet() {
      const store = localRecords<Item>(ITEMS(), {
        getRecordId: getId,
        fields: FIELDS
      });
      const state: { api: SheetApi | null } = { api: null };
      const register = (api: SheetApi) => (state.api = api);
      await render(
        <template>
          <div style="width:700px">
            <EuiSheet
              @records={{store.records}}
              @fields={{store.fields}}
              @getRecordId={{getId}}
              @onChange={{store.apply}}
              @onFieldCreate={{store.createField}}
              @onFieldUpdate={{store.updateField}}
              @onFieldDelete={{store.deleteField}}
              @registerApi={{register}}
            />
          </div>
        </template>
      );
      return state;
    }

    test('A5 the row menu is a named menu of menuitems; Escape gives focus back to the cell', async function (assert) {
      await renderSheet();
      await focusCell(1, 1);
      await pressed('F10', { shiftKey: true });
      await waitUntil(() => byTest('euiSheetRowMenu'));
      const menu = byTest('euiSheetRowMenu')!;
      assert.dom(menu).hasAttribute('role', 'menu');
      assert.dom(menu).hasAttribute('aria-label', 'Row menu');
      const items = [
        ...menu.querySelectorAll<HTMLElement>(
          '[data-test-subj^=euiSheetRowMenu-]'
        )
      ];
      assert.true(items.length > 2, `${items.length} items`);
      for (const item of items) {
        assert.strictEqual(
          item.getAttribute('role'),
          'menuitem',
          item.dataset['testSubj']
        );
      }
      for (const line of menu.querySelectorAll('hr')) {
        assert.strictEqual(
          line.getAttribute('role'),
          'separator',
          'a separator'
        );
      }
      assert.strictEqual(
        document.activeElement,
        items[0],
        'focus on the first item'
      );
      await triggerEvent(document.activeElement!, 'keydown', { key: 'Escape' });
      assert.notOk(byTest('euiSheetRowMenu'), 'closed');
      assert.strictEqual(
        document.activeElement,
        cell(1, 1),
        'focus back on the cell'
      );
    });

    test('A6 the field editor is a dialog named by what it does; the delete confirmation is described by its question', async function (assert) {
      const state = await renderSheet();
      state.api!.editField('code');
      await waitUntil(() => byTest('euiSheetFieldEditor'));
      const editor = byTest('euiSheetFieldEditor')!;
      assert.dom(editor).hasAttribute('role', 'dialog');
      assert.dom(editor).hasAttribute('aria-label', 'Edit field');
      assert.dom(editor).doesNotHaveAttribute('aria-describedby');
      await click(byTest('euiSheetFieldCancel')!);
      await frame();

      state.api!.addField();
      await waitUntil(() => byTest('euiSheetFieldEditor'));
      assert
        .dom(byTest('euiSheetFieldEditor')!)
        .hasAttribute('aria-label', 'Add field');
      await click(byTest('euiSheetFieldCancel')!);
      await frame();

      await click('[data-test-subj="dataGridHeaderCellActionButton-code"]');
      await waitUntil(() => byTest('euiSheetDeleteField-code'), {
        timeoutMessage: 'menu'
      });
      await click(byTest('euiSheetDeleteField-code')!);
      await frame();
      await waitUntil(() => byTest('euiSheetFieldDelete'), {
        timeoutMessage: 'confirm'
      });
      const confirm = byTest('euiSheetFieldEditor')!;
      assert.dom(confirm).hasAttribute('aria-label', 'Delete field');
      const describedBy = confirm.getAttribute('aria-describedby')!;
      assert.ok(describedBy, 'described');
      assert.strictEqual(
        document.getElementById(describedBy)?.textContent?.trim(),
        el('.euiSheetFieldEditor__confirm', confirm).textContent?.trim(),
        'by the question'
      );
    });

    test('A7 the shortcut list is a focusable region named by its title', async function (assert) {
      const state = await renderSheet();
      state.api!.showShortcuts();
      await waitUntil(() => byTest('euiSheetShortcutList'));
      const list = byTest('euiSheetShortcutList')!;
      assert.dom(list).hasAttribute('tabindex', '0');
      assert.dom(list).hasAttribute('role', 'region');
      const title = document.getElementById(
        list.getAttribute('aria-labelledby')!
      );
      assert.strictEqual(title?.textContent?.trim(), 'Keyboard shortcuts');
      assert.true(
        list.querySelectorAll('[data-test-subj=euiSheetShortcut]').length > 5,
        'the shortcuts are inside it'
      );
    });
  }
);
