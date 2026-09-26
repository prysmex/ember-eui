import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';

import EuiDualRange from '#src/components/eui-dual-range.gts';
import EuiRange from '#src/components/eui-range.gts';

const noop = () => {};
const DUAL_VALUE = [2, 8];

const tickLabels = () =>
  [...document.querySelectorAll('.euiRangeTick')].map((el) =>
    el.textContent!.trim()
  );
const TICKS = [
  { label: 'Min', value: 0 },
  { label: 'Mid', value: 5 },
  { label: 'Max', value: 10 }
];

module('Integration | Component | eui-range', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders a range input', async function (assert) {
    await render(
      <template>
        <EuiRange @min={{0}} @max={{10}} @value={{5}} @onChange={{noop}} />
      </template>
    );

    assert.dom('input[type="range"]').hasValue('5');
  });

  test('showTicks with @ticks renders positioned ticks', async function (assert) {
    await render(
      <template>
        <EuiRange
          @min={{0}}
          @max={{10}}
          @step={{5}}
          @value={{5}}
          @showTicks={{true}}
          @ticks={{TICKS}}
          @onChange={{noop}}
        />
      </template>
    );

    assert.dom('.euiRangeTick').exists({ count: 3 });
    assert.dom('.euiRangeTick').hasAttribute('style', /left:/);
  });

  test('showTicks renders a tick for every step', async function (assert) {
    await render(
      <template>
        <EuiRange
          @min={{0}}
          @max={{10}}
          @step={{5}}
          @value={{5}}
          @showTicks={{true}}
          @onChange={{noop}}
        />
      </template>
    );

    assert.deepEqual(tickLabels(), ['0', '5', '10']);
    assert.dom('.euiRangeTick--selected').hasText('5');

    for (const tick of document.querySelectorAll('.euiRangeTick')) {
      const style = tick.getAttribute('style') ?? '';

      assert.true(/left: calc\(/.test(style), `positioned: ${style}`);
      assert.false(style.includes('NaN'), 'no NaN position');
    }
  });

  test('@tickInterval controls the tick spacing', async function (assert) {
    await render(
      <template>
        <EuiRange
          @min={{0}}
          @max={{10}}
          @step={{1}}
          @tickInterval={{2}}
          @value={{4}}
          @showTicks={{true}}
          @onChange={{noop}}
        />
      </template>
    );

    assert.deepEqual(tickLabels(), ['0', '2', '4', '6', '8', '10']);
  });

  test('clicking an interval tick calls @onChange', async function (assert) {
    const values: string[] = [];
    const onChange = (e: Event) =>
      values.push((e.currentTarget as HTMLButtonElement).value);

    await render(
      <template>
        <EuiRange
          @min={{0}}
          @max={{10}}
          @step={{5}}
          @value={{0}}
          @showTicks={{true}}
          @onChange={{onChange}}
        />
      </template>
    );

    const last = [...document.querySelectorAll('.euiRangeTick')].at(-1)!;

    await click(last);

    assert.deepEqual(values, ['10']);
  });

  test('EuiDualRange also renders interval ticks', async function (assert) {
    await render(
      <template>
        <EuiDualRange
          @min={{0}}
          @max={{10}}
          @step={{5}}
          @value={{DUAL_VALUE}}
          @showTicks={{true}}
          @onChange={{noop}}
        />
      </template>
    );

    assert.deepEqual(tickLabels(), ['0', '5', '10']);
  });
});
