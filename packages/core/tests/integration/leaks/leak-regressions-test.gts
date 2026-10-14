/**
 * Regression tests for the leaks found by the leak-mode run
 * (internal/memory-leak-audit/leak-harness.md). They demonstrate each leak and
 * are marked `todo` so the suite stays green while the leak exists; a todo
 * test turns red once its leak is fixed, which is the cue to make it a
 * regular `test`.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, settled } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import resizeObserver from '#src/modifiers/resize-observer.ts';
import EuiSearchBar from '#src/components/eui-search-bar.gts';
import type { SearchFilterConfig } from '#src/components/eui-search-bar.gts';
import { startObserverCounter, startTimerCounter } from '../../helpers/leak-counters.ts';

module('Leak | regressions', function (hooks) {
  setupRenderingTest(hooks);

  // LH-02
  test.todo(
    'resize-observer modifier: re-running modify() 50 times keeps one observer, and unmount disconnects all',
    async function (assert) {
      const counter = startObserverCounter(['ResizeObserver']);
      try {
        const state = new (class {
          @tracked show = true;
          @tracked flip = false;
          a = () => {};
        })();
        await render(
          <template>
            {{#if state.show}}
              <div style="width:100px;height:20px" {{resizeObserver (if state.flip "width" "height") onResize=state.a}}>x</div>
            {{/if}}
          </template>
        );
        for (let i = 0; i < 50; i++) {
          state.flip = !state.flip;
          await settled();
        }
        assert.strictEqual(counter.live, 1, `observers live while mounted (created ${counter.created})`);
        state.show = false;
        await settled();
        assert.strictEqual(counter.live, 0, 'no observer left after unmount');
      } finally {
        counter.restore();
      }
    }
  );

  // LH-03
  test.todo(
    'field_value_selection filter with cache: reopening 10 times leaves no cache timer behind after unmount',
    async function (assert) {
      const timers = startTimerCounter();
      try {
        const state = new (class {
          @tracked show = true;
        })();
        const filters: SearchFilterConfig[] = [
          {
            type: 'field_value_selection',
            field: 'owner',
            name: 'Owner',
            cache: 60000,
            options: () => Promise.resolve([{ value: 'ann' }, { value: 'bob' }])
          }
        ];
        await render(
          <template>
            {{#if state.show}}
              <EuiSearchBar @filters={{filters}} />
            {{/if}}
          </template>
        );
        const owner = '.euiFilterButton[aria-label="Owner Selection"]';
        for (let i = 0; i < 10; i++) {
          await click(owner); // open
          await click(owner); // close
        }
        assert.ok(timers.timers <= 1, `at most one cache timer while mounted (pending: ${timers.timers})`);
        state.show = false;
        await settled();
        assert.strictEqual(timers.timers, 0, 'no cache timer left after unmount');
      } finally {
        timers.restore();
      }
    }
  );
});
