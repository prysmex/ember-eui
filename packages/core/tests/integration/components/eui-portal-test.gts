import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, rerender } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiPortal from '#src/components/eui-portal.gts';

module('Integration | Component | eui-portal', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders its content outside the component tree and cleans up', async function (assert) {
    class State {
      @tracked show = true;
    }
    const state = new State();

    await render(
      <template>
        <div class="host">{{#if state.show}}<EuiPortal><span class="portalled">Hi</span></EuiPortal>{{/if}}</div>
      </template>
    );

    assert.dom('.host .portalled').doesNotExist('not rendered in place');
    assert.dom('.portalled', document.body).hasText('Hi');

    state.show = false;
    await rerender();
    assert.dom('.portalled', document.body).doesNotExist('removed on teardown');
  });

  test('@insert renders next to a sibling', async function (assert) {
    const sibling = document.createElement('div');

    sibling.className = 'anchor-sibling';
    document.querySelector('#ember-testing')!.appendChild(sibling);

    const insert = { sibling, position: 'after' };

    await render(<template><EuiPortal @insert={{insert}}><span class="after-sibling">x</span></EuiPortal></template>);

    assert.ok(sibling.nextElementSibling?.querySelector('.after-sibling'), 'inserted after the sibling');
    sibling.remove();
  });
});
