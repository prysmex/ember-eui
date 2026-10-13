import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';

import EuiStep from '#src/components/eui-step.gts';
import EuiStepHorizontal from '#src/components/eui-step-horizontal.gts';
import EuiSteps from '#src/components/eui-steps.gts';
import EuiStepsHorizontal from '#src/components/eui-steps-horizontal.gts';
import EuiSubSteps from '#src/components/eui-sub-steps.gts';

module('Integration | Component | eui-steps', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiSteps renders numbered steps with titles and content', async function (assert) {
    await render(
      <template>
        <EuiSteps>
          <EuiStep @step={{1}} @title="Install">Run the installer<EuiSubSteps>sub</EuiSubSteps></EuiStep>
          <EuiStep @step={{2}} @title="Configure" @status="complete">Done</EuiStep>
          <EuiStep @step={{3}} @title="Later" @status="disabled" @titleSize="xs">Wait</EuiStep>
        </EuiSteps>
      </template>
    );

    assert.dom('.euiSteps .euiStep').exists({ count: 3 });
    assert.dom('.euiStep:nth-child(1) .euiStep__title').hasText('Install');
    assert.dom('.euiStep:nth-child(1) .euiStepNumber__number').hasText('1');
    assert.dom('.euiStep:nth-child(1) .euiStep__content .euiSubSteps').hasText('sub');
    // Legacy status/size classes are gone: assert the icon label and measured size.
    assert.dom('.euiStep:nth-child(2) .euiStepNumber svg.euiStepNumber__icon').exists().hasAttribute('aria-label', 'Step 2 is complete');
    assert.dom('.euiStep:nth-child(3) .euiStepNumber').includesText('Step 3 is disabled');
    assert.strictEqual(getComputedStyle(document.querySelector('.euiStep:nth-child(3) .euiStepNumber')!).width, '24px', 'xs title size');
  });

  test('step number statuses', async function (assert) {
    await render(
      <template>
        <EuiSteps>
          <EuiStep @step={{1}} @title="w" @status="warning" class="warning" />
          <EuiStep @step={{2}} @title="d" @status="danger" class="danger" />
          <EuiStep @step={{3}} @title="l" @status="loading" class="loading" />
          <EuiStep @step={{4}} @title="i" @status="incomplete" class="incomplete" />
        </EuiSteps>
      </template>
    );

    assert.dom('.warning .euiStepNumber svg').hasAttribute('aria-label', 'Step 1 has warnings');
    assert.dom('.danger .euiStepNumber svg').hasAttribute('aria-label', 'Step 2 has errors');
    assert.dom('.loading .euiStepNumber__loader').exists();
    assert.strictEqual(getComputedStyle(document.querySelector('.incomplete .euiStepNumber')!).backgroundColor, 'rgba(0, 0, 0, 0)', 'incomplete is hollow');
  });

  test('EuiStepsHorizontal renders clickable steps with statuses', async function (assert) {
    const clicked: number[] = [];
    const clickStep2 = () => clicked.push(2);

    await render(
      <template>
        <EuiStepsHorizontal>
          <EuiStepHorizontal @step={{1}} @title="Done" @isComplete={{true}} />
          <EuiStepHorizontal @step={{2}} @title="Now" @isSelected={{true}} @onStepClick={{clickStep2}} />
          <EuiStepHorizontal @step={{3}} @title="Next" />
          <EuiStepHorizontal @step={{4}} @title="Locked" @disabled={{true}} />
        </EuiStepsHorizontal>
      </template>
    );

    assert.dom('ol.euiStepsHorizontal li').exists({ count: 4 });
    // Legacy state classes are replaced by upstream's `data-step-status`.
    assert.dom('li:nth-child(1) button').hasAttribute('data-step-status', 'complete');
    assert.dom('li:nth-child(2)').hasAttribute('aria-current', 'step');
    assert.dom('li:nth-child(2) button').hasAttribute('data-step-status', 'current');
    assert.dom('li:nth-child(3) button').hasAttribute('data-step-status', 'incomplete');
    assert.dom('li:nth-child(4) button').isDisabled().hasAttribute('data-step-status', 'disabled');
    assert.dom('li:nth-child(2) .euiStepHorizontal__title').hasText('Now');

    await click('li:nth-child(2) button');
    assert.deepEqual(clicked, [2]);
  });
});
