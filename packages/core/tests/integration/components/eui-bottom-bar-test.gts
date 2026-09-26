import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiBottomBar from '#src/components/eui-bottom-bar.gts';

module('Integration | Component | eui-bottom-bar', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders its content with position offsets as inline styles', async function (assert) {
    // position fixed (the default) always renders through a portal into <body>
    await render(
      <template>
        <EuiBottomBar @left={{10}}>
          <span class="bar-content">Save</span>
        </EuiBottomBar>
      </template>
    );

    assert.dom('.euiBottomBar .bar-content', document.body).hasText('Save');
    assert.dom('.euiBottomBar', document.body).hasStyle({ left: '10px' });
  });

  test('static position also works', async function (assert) {
    await render(
      <template>
        <EuiBottomBar @usePortal={{false}} @position="static">Save</EuiBottomBar>
      </template>
    );

    assert.dom('.euiBottomBar').hasClass('euiBottomBar--static');
  });
});
