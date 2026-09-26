import { module, test } from 'qunit';
import { tracked } from '@glimmer/tracking';
import { setupRenderingTest } from 'ember-qunit';
import { render, triggerEvent, waitUntil } from '@ember/test-helpers';

import EuiIconTip from '#src/components/eui-icon-tip.gts';
import EuiToolTip from '#src/components/eui-tool-tip.gts';

const tooltip = () => document.querySelector('.euiToolTip');

module('Integration | Component | eui-tool-tip', function (hooks) {
  setupRenderingTest(hooks);

  test('it shows the tooltip on hover and hides it on mouseout', async function (assert) {
    await render(
      <template>
        <EuiToolTip @content="Helpful text" @title="Tip" @position="bottom">
          <button type="button" class="anchor">Hover me</button>
        </EuiToolTip>
      </template>
    );

    assert.dom('.euiToolTipAnchor .anchor').exists();
    assert.strictEqual(tooltip(), null, 'hidden initially');

    await triggerEvent('.euiToolTipAnchor', 'mouseover');
    await waitUntil(tooltip);

    assert.dom('.euiToolTip', document.body).containsText('Helpful text').containsText('Tip');
    assert.dom('.euiToolTip', document.body).hasAttribute('role', 'tooltip');

    await triggerEvent('.euiToolTipAnchor', 'mouseout');
    await waitUntil(() => !tooltip());
    assert.strictEqual(tooltip(), null, 'hidden after mouseout');
  });

  test('@isShown shows it without hovering', async function (assert) {
    await render(
      <template>
        <EuiToolTip @content="Always" @isShown={{true}}>
          <span>anchor</span>
        </EuiToolTip>
      </template>
    );

    await waitUntil(tooltip);
    assert.dom('.euiToolTip', document.body).containsText('Always');
  });

  test('changing @isShown shows and hides it', async function (assert) {
    class State {
      @tracked shown = false;
    }
    const state = new State();

    await render(
      <template>
        <EuiToolTip @content="Toggled" @isShown={{state.shown}}>
          <span>anchor</span>
        </EuiToolTip>
      </template>
    );

    assert.strictEqual(tooltip(), null, 'hidden initially');

    state.shown = true;
    await waitUntil(tooltip);
    assert.dom('.euiToolTip', document.body).containsText('Toggled');

    state.shown = false;
    await waitUntil(() => !tooltip());
    assert.strictEqual(tooltip(), null, 'hidden again');
  });

  test('EuiIconTip renders an icon anchor with a tooltip', async function (assert) {
    await render(<template><EuiIconTip @content="Info text" @type="alert" @ariaLabel="More info" /></template>);

    assert.dom('.euiToolTipAnchor svg.euiIcon').hasAttribute('aria-label', 'More info');
    assert.dom('.euiToolTipAnchor svg.euiIcon').doesNotHaveAttribute('aria-hidden');

    await triggerEvent('.euiToolTipAnchor', 'mouseover');
    await waitUntil(tooltip);
    assert.dom('.euiToolTip', document.body).containsText('Info text');
  });
});
