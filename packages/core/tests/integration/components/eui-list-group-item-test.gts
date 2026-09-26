import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiListGroupItem from '#src/components/eui-list-group-item.gts';

const ExtraAction = <template>
  <button type="button" class="my-extra-action">Extra</button>
</template>;

module('Integration | Component | eui-list-group-item', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders the label and an @extraAction component', async function (assert) {
    await render(
      <template>
        <EuiListGroupItem @label="Item" @extraAction={{ExtraAction}} />
      </template>
    );

    assert.dom('.euiListGroupItem').exists();
    assert.dom('.euiListGroupItem__label').hasText('Item');
    assert.dom('button.my-extra-action').exists();
  });
});
