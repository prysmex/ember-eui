import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, rerender, waitUntil } from '@ember/test-helpers';
import { on } from '@ember/modifier';

import EuiTour from '#src/components/eui-tour.gts';
import EuiTourStep from '#src/components/eui-tour-step.gts';
import EuiTourStepIndicator from '#src/components/eui-tour-step-indicator.gts';

const panel = () => document.querySelector('.euiTour');

module('Integration | Component | eui-tour', function (hooks) {
  setupRenderingTest(hooks);

  test('a step on its own', async function (assert) {
    let finished = 0;
    const onFinish = () => finished++;

    await render(
      <template>
        <EuiTourStep @isStepOpen={{true}} @title="Welcome" @subtitle="Tour" @content="This is the search." @onFinish={{onFinish}}>
          <button type="button" class="anchor">Search</button>
        </EuiTourStep>
      </template>
    );

    await waitUntil(panel);
    assert.dom('.anchor').exists();
    assert.dom('.euiTourHeader__subtitle', document.body).hasText('Tour');
    assert.dom('.euiTourHeader__title', document.body).hasText('Welcome');
    assert.dom('.euiTour__content', document.body).hasText('This is the search.');
    assert.dom('.euiTour__beacon', document.body).exists();
    assert.dom('.euiTourFooter__stepList', document.body).doesNotExist('one step has no progress');
    assert.dom('.euiTourFooter .euiButtonEmpty', document.body).hasText('Close tour');

    await click(document.querySelector('.euiTourFooter .euiButtonEmpty') as Element);
    assert.strictEqual(finished, 1);
  });

  test('EuiTour opens the current step and moves between steps', async function (assert) {
    const initialState = { currentTourStep: 1, isTourActive: true, tourSubtitle: 'Demo tour' };
    const steps = [
      { step: 1, title: 'First', content: 'Step one' },
      { step: 2, title: 'Second', content: 'Step two' },
    ];

    await render(
      <template>
        <EuiTour @initialState={{initialState}} @steps={{steps}} as |tour|>
          <tour.Step @step={{1}}>
            <:default><span class="one">One</span></:default>
            <:footerAction>
              <button type="button" class="next" {{on "click" tour.actions.incrementStep}}>Next</button>
            </:footerAction>
          </tour.Step>
          <tour.Step @step={{2}}><span class="two">Two</span></tour.Step>
          <span class="current">{{tour.state.currentTourStep}}</span>
        </EuiTour>
      </template>
    );

    await waitUntil(panel);
    assert.dom('.euiTourHeader__title', document.body).hasText('First');
    assert.dom('.euiTourHeader__subtitle', document.body).hasText('Demo tour');
    assert.dom('.euiTourStepIndicator', document.body).exists({ count: 2 });
    assert.dom('.euiTourStepIndicator--active', document.body).exists({ count: 1 });

    await click(document.querySelector('.next') as Element);
    await rerender();
    assert.dom('.current').hasText('2');
    assert.dom('.euiTourHeader__title', document.body).hasText('Second');
    assert.dom('.euiTourFooter .euiButtonEmpty', document.body).hasText('End tour', 'the last step ends the tour');

    await click(document.querySelector('.euiTourFooter .euiButtonEmpty') as Element);
    await rerender();
    assert.dom('.euiTour', document.body).doesNotExist('finished');
    assert.dom('.current').hasText('1', 'finishing resets to the first step');
  });

  test('EuiTourStepIndicator', async function (assert) {
    await render(
      <template>
        <ul>
          <EuiTourStepIndicator class="done" @number={{1}} @status="complete" />
          <EuiTourStepIndicator class="now" @number={{2}} @status="active" />
          <EuiTourStepIndicator class="later" @number={{3}} @status="incomplete" />
        </ul>
      </template>
    );

    assert.dom('.done').hasClass('euiTourStepIndicator--complete').hasAria('label', 'Step 1 complete');
    assert.dom('.now .euiIcon').hasAttribute('aria-current', 'step');
    assert.dom('.later').hasClass('euiTourStepIndicator--incomplete');
  });
});
