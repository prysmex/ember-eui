import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiRange from '#src/components/eui-range.gts';

const noop = () => {};
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
});
