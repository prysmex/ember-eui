import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, rerender, waitUntil } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiAccordion from '#src/components/eui-accordion.gts';

const wrapperHeight = () =>
  (document.querySelector('.euiAccordion__childWrapper') as HTMLElement).style
    .height;

module('Integration | Component | eui-accordion', function (hooks) {
  setupRenderingTest(hooks);

  test('it toggles open and closed', async function (assert) {
    const toggles: boolean[] = [];
    const onToggle = (isOpen: boolean) => toggles.push(isOpen);

    await render(
      <template>
        <EuiAccordion @id="acc" @buttonContent="Toggle" @onToggle={{onToggle}}>
          <:content><p>Content</p></:content>
        </EuiAccordion>
      </template>
    );

    assert.dom('.euiAccordion').doesNotHaveClass('euiAccordion-isOpen');

    await click('.euiAccordion__button');
    assert.dom('.euiAccordion').hasClass('euiAccordion-isOpen');

    await click('.euiAccordion__button');
    assert.dom('.euiAccordion').doesNotHaveClass('euiAccordion-isOpen');

    assert.deepEqual(toggles, [true, false]);
  });

  test('it recalculates the height when @forceState changes', async function (assert) {
    // relies on `didUpdate this.setChildContentHeight @forceState`
    class State {
      @tracked forceState: 'open' | 'closed' = 'closed';
    }
    const state = new State();

    await render(
      <template>
        <EuiAccordion
          @id="acc"
          @buttonContent="Toggle"
          @forceState={{state.forceState}}
        >
          <:content>
            <p style="height: 40px; margin: 0">Content</p>
          </:content>
        </EuiAccordion>
      </template>
    );

    await waitUntil(() => wrapperHeight() === '0px');
    assert.strictEqual(wrapperHeight(), '0px', 'closed');

    state.forceState = 'open';
    await rerender();

    await waitUntil(() => wrapperHeight() !== '0px', { timeout: 1000 });
    assert.notStrictEqual(wrapperHeight(), '0px', 'opened after forceState');
  });
});
