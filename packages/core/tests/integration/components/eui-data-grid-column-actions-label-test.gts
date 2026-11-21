import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';

import EuiDataGrid from '#src/components/eui-data-grid.gts';

import type { EuiDataGridColumn } from '#src/components/eui-data-grid.gts';

const COLUMNS: EuiDataGridColumn[] = [
  { id: 'a', displayAsText: 'Name' },
  { id: 'b' }
];

module(
  'Integration | Component | EuiDataGrid column actions label',
  function (hooks) {
    setupRenderingTest(hooks);

    test('the column actions popover is a dialog named by its column (axe aria-dialog-name)', async function (assert) {
      await render(
        <template>
          <div style="width:600px">
            <EuiDataGrid
              aria-label="Grid"
              @columns={{COLUMNS}}
              @rowCount={{1}}
              @toolbarVisibility={{false}}
            >
              <:cell as |c|>{{c.columnId}}</:cell>
            </EuiDataGrid>
          </div>
        </template>
      );
      const dialogOf = (id: string) =>
        document
          .querySelector(
            `[data-test-subj="dataGridHeaderCellActionGroup-${id}"]`
          )
          ?.closest('[role=dialog]');

      await click('[data-test-subj="dataGridHeaderCellActionButton-a"]');
      assert
        .dom(dialogOf('a')!)
        .hasAttribute('aria-label', 'Name', 'its display text');

      await click('[data-test-subj="dataGridHeaderCellActionButton-b"]');
      assert.dom(dialogOf('b')!).hasAttribute('aria-label', 'b', 'else its id');
    });
  }
);
