import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiComboBox from '#src/components/eui-combo-box.gts';

import type { TOC } from '@ember/component/template-only';

const options = ['Apple', 'Banana', 'Cherry'];
const selected = ['Apple', 'Cherry'];
const noop = () => {};

const MySelectedItem: TOC<{ Args: { option: string } }> = <template>
  <span class="my-selected-item">{{@option}}</span>
</template>;

module('Integration | Component | eui-combo-box', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders selected options as pills by default', async function (assert) {
    await render(
      <template>
        <EuiComboBox
          @options={{options}}
          @selectedOptions={{selected}}
          @onChange={{noop}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    assert.dom('.euiComboBoxPill').exists({ count: 2 });
  });

  test('it renders a custom @selectedItemComponent', async function (assert) {
    await render(
      <template>
        <EuiComboBox
          @options={{options}}
          @selectedOptions={{selected}}
          @onChange={{noop}}
          @selectedItemComponent={{MySelectedItem}}
          as |option|
        >
          {{option}}
        </EuiComboBox>
      </template>
    );

    assert.dom('.euiComboBoxPill').doesNotExist();
    assert.dom('.my-selected-item').exists({ count: 2 });
    assert.dom('.my-selected-item').hasText('Apple');
  });
});
