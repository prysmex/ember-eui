import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, fillIn, render } from '@ember/test-helpers';

import EuiDualRange from '#src/components/eui-dual-range.gts';
import EuiRange from '#src/components/eui-range.gts';
import EuiRangeThumb from '#src/components/eui-range-thumb.gts';

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

  test('labels, highlight, levels and value tooltip', async function (assert) {
    const levels = [
      { min: 0, max: 4, color: 'danger' },
      { min: 4, max: 10, color: 'success' }
    ];

    await render(
      <template>
        <EuiRange
          @min={{0}}
          @max={{10}}
          @value={{6}}
          @showLabels={{true}}
          @showRange={{true}}
          @showValue={{true}}
          @levels={{levels}}
          @onChange={{noop}}
        />
      </template>
    );

    assert.dom('.euiRangeLabel').exists({ count: 2 });
    assert.dom('.euiRangeLabel:first-child').hasText('0');
    assert.dom('.euiRangeHighlight .euiRangeHighlight__progress').exists();
    assert.dom('.euiRangeSlider').hasClass('euiRangeSlider--hasRange');
    assert.dom('.euiRangeLevels .euiRangeLevel').exists({ count: 2 });
    assert.dom('.euiRangeLevel:first-child').hasClass('euiRangeLevel--danger');
    assert.dom('.euiRangeTooltip .euiRangeTooltip__value').hasText('6');
  });

  test('showInput adds a number input that drives @onChange', async function (assert) {
    const values: string[] = [];
    const onChange = (e: Event) => values.push((e.currentTarget as HTMLInputElement).value);

    await render(
      <template><EuiRange @min={{0}} @max={{10}} @value={{2}} @showInput={{true}} @onChange={{onChange}} /></template>
    );

    assert.dom('.euiRangeWrapper').hasClass('euiRange--hasInput');
    assert.dom('input.euiRangeInput[type="number"]').hasValue('2');
    assert.dom('input[type="range"]').hasAttribute('aria-hidden', 'true').hasAttribute('tabindex', '-1');

    await fillIn('input.euiRangeInput', '7');
    assert.deepEqual(values, ['7']);
  });

  test('dragging the slider calls @onChange', async function (assert) {
    const values: string[] = [];
    const onChange = (e: Event) => values.push((e.currentTarget as HTMLInputElement).value);

    await render(<template><EuiRange @min={{0}} @max={{10}} @value={{1}} @onChange={{onChange}} /></template>);

    await fillIn('input[type="range"]', '9');
    assert.deepEqual(values, ['9']);
  });

  test('EuiDualRange: two inputs, range highlight and @onChange([lower, upper])', async function (assert) {
    const changes: unknown[] = [];
    const onChange = (values: unknown) => changes.push(values);

    await render(
      <template>
        <EuiDualRange
          @min={{0}}
          @max={{10}}
          @value={{DUAL_VALUE}}
          @showInput={{true}}
          @showLabels={{true}}
          @onChange={{onChange}}
        />
      </template>
    );

    assert.dom('input.euiRangeInput').exists({ count: 2 });
    assert.dom('.euiRangeHighlight').exists();
    assert.dom('.euiRangeLabel').exists({ count: 2 });

    await fillIn('input.euiRangeInput:first-of-type', '3');
    assert.deepEqual(changes.at(-1), ['3', 8]);
  });

  test('EuiDualRange without inputs renders two thumbs over one slider', async function (assert) {
    await render(<template><EuiDualRange @min={{0}} @max={{10}} @value={{DUAL_VALUE}} @onChange={{noop}} /></template>);

    assert.dom('.euiRangeThumb').exists({ count: 2 });
    assert.dom('.euiRangeThumb:first-of-type').hasAttribute('aria-valuenow', '2');
  });

  test('a disabled thumb is announced as disabled', async function (assert) {
    await render(
      <template>
        <EuiRangeThumb @min={{0}} @max={{10}} @value={{5}} @disabled={{true}} class="off" />
        <EuiRangeThumb @min={{0}} @max={{10}} @value={{5}} class="on" />
      </template>
    );

    assert.dom('button.off').hasAria('disabled', 'true');
    assert.dom('button.off [role="slider"]').hasAria('disabled', 'true');
    assert.dom('button.on').doesNotHaveAria('disabled');
  });
});
