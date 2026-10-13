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
    assert.dom('.euiTourStepIndicator [aria-current="step"]', document.body).exists({ count: 1 });
    assert.dom('.euiTourStepIndicator', document.body).hasAria('label', 'Step 1 active');

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

    // legacy `--{status}` classes removed: status is in the aria labels
    assert.dom('.done').hasAria('label', 'Step 1 complete').hasStyle({ display: 'inline-block' });
    assert.dom('.done .euiIcon').hasAria('label', 'complete').doesNotHaveAttribute('aria-current');
    assert.dom('.now .euiIcon').hasAttribute('aria-current', 'step').hasAria('label', 'active');
    assert.dom('.later').hasAria('label', 'Step 3 incomplete');
  });

  test('@anchor attaches the step to an element already in the page (selector or element)', async function (assert) {
    const host = document.createElement('div');
    host.innerHTML = '<button type="button" id="outside-anchor">Outside</button>';
    document.body.appendChild(host);
    const onFinish = () => {};

    try {
      await render(
        <template>
          <EuiTourStep @anchor="#outside-anchor" @isStepOpen={{true}} @title="Anchored" @content="Found it" @stepsTotal={{2}} @onFinish={{onFinish}} />
        </template>
      );

      await waitUntil(panel);
      assert.dom('.euiTourHeader__title', document.body).hasText('Anchored');
      assert.dom('.euiTour__content', document.body).hasText('Found it');
      assert.dom('#outside-anchor', document.body).exists('the anchor element is kept');
      assert.dom('.euiTour__beacon', document.body).exists();
    } finally {
      host.remove();
    }
  });

  test('@anchor accepts an element', async function (assert) {
    const target = document.createElement('button');
    target.textContent = 'Target';
    document.body.appendChild(target);
    const onFinish = () => {};

    try {
      await render(
        <template>
          <EuiTourStep @anchor={{target}} @isStepOpen={{true}} @title="By element" @content="Yes" @onFinish={{onFinish}} />
        </template>
      );
      await waitUntil(panel);
      assert.dom('.euiTourHeader__title', document.body).hasText('By element');
    } finally {
      target.remove();
    }
  });

  test('@anchor accepts a function returning the element', async function (assert) {
    const target = document.createElement('button');
    document.body.appendChild(target);
    const getAnchor = () => target;
    const onFinish = () => {};

    try {
      await render(
        <template>
          <EuiTourStep @anchor={{getAnchor}} @isStepOpen={{true}} @title="By function" @content="Yes" @onFinish={{onFinish}} />
        </template>
      );
      await waitUntil(panel);
      assert.dom('.euiTourHeader__title', document.body).hasText('By function');
    } finally {
      target.remove();
    }
  });

  test('@zIndex sets the popover layer', async function (assert) {
    const onFinish = () => {};
    await render(
      <template>
        <EuiTourStep @isStepOpen={{true}} @zIndex={{4321}} @title="Z" @content="z" @onFinish={{onFinish}}>
          <button type="button">anchor</button>
        </EuiTourStep>
      </template>
    );
    await waitUntil(panel);
    const popover = (panel() as HTMLElement).closest('.euiPopover__panel') ?? (panel() as HTMLElement);
    assert.strictEqual(getComputedStyle(popover).zIndex, '4321');
  });

  test('@footerAction replaces the skip button: one component, or a list', async function (assert) {
    const Next = <template><button type="button" class="next-action">Next</button></template>;
    const Back = <template><button type="button" class="back-action">Back</button></template>;
    const list = [Back, Next];
    const onFinish = () => {};

    await render(
      <template>
        <EuiTourStep @isStepOpen={{true}} @footerAction={{Next}} @title="One" @content="x" @stepsTotal={{2}} @onFinish={{onFinish}}>
          <button type="button">anchor</button>
        </EuiTourStep>
      </template>
    );
    await waitUntil(panel);
    assert.dom('.euiTourFooter .next-action', document.body).exists({ count: 1 });
    assert.dom('.euiTourFooter .euiButtonEmpty', document.body).doesNotExist('no default skip button');

    await render(
      <template>
        <EuiTourStep @isStepOpen={{true}} @footerAction={{list}} @title="Two" @content="x" @stepsTotal={{2}} @onFinish={{onFinish}}>
          <button type="button">anchor</button>
        </EuiTourStep>
      </template>
    );
    await waitUntil(() => document.querySelector('.back-action'));
    assert.dom('.euiTourFooter .back-action', document.body).exists();
    assert.dom('.euiTourFooter .next-action', document.body).exists();
  });

  test('the <:footerAction> block wins over @footerAction', async function (assert) {
    const Arg = <template><button type="button" class="arg-action">Arg</button></template>;
    const onFinish = () => {};
    await render(
      <template>
        <EuiTourStep @isStepOpen={{true}} @footerAction={{Arg}} @title="B" @content="x" @onFinish={{onFinish}}>
          <:default><button type="button">anchor</button></:default>
          <:footerAction><button type="button" class="block-action">Block</button></:footerAction>
        </EuiTourStep>
      </template>
    );
    await waitUntil(panel);
    assert.dom('.block-action', document.body).exists();
    assert.dom('.arg-action', document.body).doesNotExist();
  });
});
