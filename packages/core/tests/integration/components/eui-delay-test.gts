import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, rerender, settled } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiDelayHide from '#src/components/eui-delay-hide.gts';
import EuiDelayRender from '#src/components/eui-delay-render.gts';

module('Integration | Component | eui-delay-render and eui-delay-hide', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiDelayRender renders its content after the delay', async function (assert) {
    const promise = render(<template><EuiDelayRender @delay={{50}}><p class="late">Loading…</p></EuiDelayRender></template>);

    await new Promise((resolve) => setTimeout(resolve, 10));
    assert.dom('.late').doesNotExist('not rendered yet');

    await promise;
    assert.dom('.late').exists('rendered once the delay passed');
  });

  test('EuiDelayHide keeps its content for the minimum time', async function (assert) {
    class State {
      @tracked hide = false;
    }
    const state = new State();

    await render(
      <template>
        <EuiDelayHide @hide={{state.hide}} @minimumDuration={{50}}><p class="shown">Saving…</p></EuiDelayHide>
      </template>
    );

    // render() waited for the countdown: hiding now is immediate
    state.hide = true;
    await settled();
    assert.dom('.shown').doesNotExist('hidden once the minimum time has passed');

    state.hide = false;
    await rerender();
    assert.dom('.shown').exists('shown again');

    state.hide = true;
    await rerender();
    assert.dom('.shown').exists('still shown while the new countdown runs');

    await settled();
    assert.dom('.shown').doesNotExist('hidden when it ends');
  });

  test('EuiDelayHide hidden from the start shows nothing', async function (assert) {
    await render(<template><EuiDelayHide @hide={{true}}><p class="shown">x</p></EuiDelayHide></template>);

    assert.dom('.shown').doesNotExist();
  });
});
