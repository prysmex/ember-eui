import { module, test } from 'qunit';
import { tracked } from '@glimmer/tracking';
import { setupRenderingTest } from 'ember-qunit';
import { render, settled, triggerEvent, waitUntil } from '@ember/test-helpers';

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

  module('@repositionOnScroll', function () {
    const scrollAndMeasure = async (
      reposition: boolean | undefined
    ): Promise<[string, string]> => {
      await render(
        <template>
          <div
            id="scroller"
            style="height: 200px; overflow: auto; margin-top: 150px;"
          >
            <div style="height: 600px; padding-top: 60px;">
              <EuiToolTip @content="Scrolled" @repositionOnScroll={{reposition}}>
                <button type="button" class="anchor">Anchor</button>
              </EuiToolTip>
            </div>
          </div>
        </template>
      );

      await triggerEvent('.euiToolTipAnchor', 'mouseover');
      await waitUntil(tooltip);
      const el = tooltip() as HTMLElement;
      await waitUntil(() => el.style.top !== '' && el.style.top !== '-999px');
      await new Promise((resolve) => setTimeout(resolve, 150));
      const before = el.style.top;

      const scroller = document.querySelector('#scroller') as HTMLElement;
      scroller.scrollTop = 30;
      scroller.dispatchEvent(new Event('scroll'));
      await new Promise((resolve) => setTimeout(resolve, 100));

      return [before, (tooltip() as HTMLElement).style.top];
    };

    test('repositions on scroll when true', async function (assert) {
      const [before, after] = await scrollAndMeasure(true);
      assert.notStrictEqual(after, before, 'the tooltip followed the anchor');
    });

    test('does not reposition on scroll by default or when false', async function (assert) {
      const [before, after] = await scrollAndMeasure(undefined);
      assert.strictEqual(after, before, 'default: not repositioned');
    });

    test('toggling the arg adds and removes the listener', async function (assert) {
      class State {
        @tracked reposition = false;
      }
      const state = new State();
      await render(
        <template>
          <div id="scroller" style="height: 200px; overflow: auto; margin-top: 150px;">
            <div style="height: 600px; padding-top: 60px;">
              <EuiToolTip @content="Toggle" @repositionOnScroll={{state.reposition}}>
                <button type="button">Anchor</button>
              </EuiToolTip>
            </div>
          </div>
        </template>
      );
      await triggerEvent('.euiToolTipAnchor', 'mouseover');
      await waitUntil(tooltip);
      const el = tooltip() as HTMLElement;
      await waitUntil(() => el.style.top !== '' && el.style.top !== '-999px');
      await new Promise((resolve) => setTimeout(resolve, 150));
      const scroller = document.querySelector('#scroller') as HTMLElement;

      state.reposition = true;
      await settled();
      const start = el.style.top;
      scroller.scrollTop = 30;
      scroller.dispatchEvent(new Event('scroll'));
      await new Promise((resolve) => setTimeout(resolve, 100));
      const moved = el.style.top;
      assert.notStrictEqual(moved, start, 'repositions once enabled');

      state.reposition = false;
      await settled();
      scroller.scrollTop = 60;
      scroller.dispatchEvent(new Event('scroll'));
      await new Promise((resolve) => setTimeout(resolve, 100));
      assert.strictEqual(el.style.top, moved, 'stops once disabled');
    });
  });

  test('@attachTo renders no element of its own and describes the target', async function (assert) {
    class State {
      @tracked shown = false;
    }
    const state = new State();
    const target = document.createElement('button');
    target.setAttribute('aria-describedby', 'existing');
    document.body.append(target);

    try {
      await render(
        <template>
          <div class="host"><EuiToolTip @content="Attached" @attachTo={{target}} @isShown={{state.shown}} /></div>
        </template>
      );

      assert.strictEqual(document.querySelector('.host')!.children.length, 0, 'no empty span');

      state.shown = true;
      await waitUntil(tooltip);
      await settled();
      const id = tooltip()!.id;
      assert.strictEqual(target.getAttribute('aria-describedby'), `${id} existing`, 'described while shown');

      state.shown = false;
      await waitUntil(() => !tooltip());
      await settled();
      assert.strictEqual(target.getAttribute('aria-describedby'), 'existing', 'only its id is removed');

      await triggerEvent(target, 'mousemove');
      await waitUntil(tooltip);
      assert.dom('.euiToolTip', document.body).containsText('Attached', 'hovering the target shows it');
    } finally {
      target.remove();
    }
  });
});
