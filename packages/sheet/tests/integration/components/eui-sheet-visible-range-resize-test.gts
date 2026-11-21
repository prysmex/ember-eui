/**
 * `@onVisibleRangeChange` when the grid's height changes (v0.4 batch D's
 * "not verified: the resize path", READINESS.md item 5's "any other open
 * item"), VR6: a taller grid shows more records and reports them; a
 * shorter one reports fewer.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { render, settled, waitUntil } from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';

import type { EuiSheetField } from '#src/core/index.ts';
import type { SheetVisibleRange } from '#src/types.ts';

type Row = Record<string, string | number>;

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'f0', label: 'Field 0', width: 150 },
  { id: 'f1', label: 'Field 1', width: 150 }
];

const ROWS: Row[] = Array.from({ length: 200 }, (_, r) => ({
  id: r,
  f0: `r${r}c0`,
  f1: `r${r}c1`
}));

const getId = (row: Row) => row['id']!;

class State {
  @tracked height = 300;
  calls: SheetVisibleRange[] = [];
  onChange = () => {};
  onVisibleRangeChange = (range: SheetVisibleRange) => {
    this.calls.push(range);
  };
  get last(): SheetVisibleRange | undefined {
    return this.calls[this.calls.length - 1];
  }
}

module(
  'Integration | Component | EuiSheet visible range on resize',
  function (hooks) {
    setupRenderingTest(hooks);

    test('VR6 a change of @height reports the records now on screen', async function (assert) {
      const state = new State();
      await render(
        <template>
          <div style="width:600px">
            <EuiSheet
              @fields={{FIELDS}}
              @records={{ROWS}}
              @getRecordId={{getId}}
              @onChange={{state.onChange}}
              @onVisibleRangeChange={{state.onVisibleRangeChange}}
              @height={{state.height}}
            />
          </div>
        </template>
      );
      await waitUntil(() => state.calls.length > 0);
      const short = state.last!;
      assert.strictEqual(short.first, 0);
      state.height = 600;
      await settled();
      try {
        await waitUntil(() => state.last!.last > short.last, { timeout: 1000 });
      } catch {
        // asserted below
      }
      const tall = state.last!;
      assert.true(
        tall.last > short.last + 5,
        `taller: more records (${short.last} -> ${tall.last})`
      );
      assert.deepEqual([tall.first, tall.count], [0, 200]);
      state.height = 300;
      await settled();
      try {
        await waitUntil(() => state.last!.last < tall.last, { timeout: 1000 });
      } catch {
        // asserted below
      }
      assert.strictEqual(
        state.last!.last,
        short.last,
        'shorter again: as at first'
      );
    });
  }
);
