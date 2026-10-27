import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
import Component from '@glimmer/component';

import EuiStat from '#src/components/eui-stat.gts';

class Count extends Component<{ Args: { count: number } }> {
  get count() {
    return this.args.count;
  }

  <template><EuiStat @title={{this.count}} @description="Users" /></template>
}

module('Integration | Component | eui-stat | @title', function (hooks) {
  setupRenderingTest(hooks);

  test('@title can be a number', async function (assert) {
    await render(<template><Count @count={{1234}} /></template>);

    assert.dom('.euiStat__title').hasText('1234');
  });

  test('a zero @title is shown', async function (assert) {
    await render(<template><Count @count={{0}} /></template>);

    assert.dom('.euiStat__title').hasText('0');
  });
});
