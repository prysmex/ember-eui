import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, waitUntil } from '@ember/test-helpers';

import EuiOverlayMask from '#src/components/eui-overlay-mask.gts';
import EuiPageHeaderContent from '#src/components/eui-page-header-content.gts';
import EuiPaginationButton from '#src/components/eui-pagination-button.gts';
import EuiStepNumber from '#src/components/eui-step-number.gts';
import EuiWrappingPopover from '#src/components/eui-wrapping-popover.gts';

module('Integration | Component | building blocks', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiOverlayMask: renders into <body> and only calls @onClick for clicks on the mask itself', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;

    await render(
      <template>
        <EuiOverlayMask @onClick={{onClick}} @headerZindexLocation="below">
          <div class="mask-content">content</div>
        </EuiOverlayMask>
      </template>
    );

    const mask = document.querySelector('.euiOverlayMask') as HTMLElement;

    assert.dom(mask).hasClass('euiOverlayMask--belowHeader');
    assert.dom(document.body).hasClass('euiBody-hasOverlayMask');

    await click(mask.querySelector('.mask-content')!);
    assert.strictEqual(clicks, 0, 'clicks inside the content are ignored');

    await click(mask);
    assert.strictEqual(clicks, 1);
  });

  test('EuiStepNumber: number, statuses and hollow', async function (assert) {
    await render(
      <template>
        <EuiStepNumber @number={{3}} @stepAriaLabel="Step 3" class="number" />
        <EuiStepNumber @number={{1}} @status="complete" class="complete" />
        <EuiStepNumber @number={{2}} @isHollow={{true}} class="hollow" />
      </template>
    );

    assert.dom('.number .euiStepNumber__number').hasText('3').hasAttribute('aria-hidden', 'true');
    assert.dom('.number').containsText('Step 3');
    assert.dom('.complete').hasClass('euiStepNumber--complete');
    assert.dom('.complete svg.euiStepNumber__icon').exists();
    assert.dom('.hollow').hasClass('euiStepNumber-isHollow');
  });

  test('EuiPaginationButton: 1-based label, active page', async function (assert) {
    await render(
      <template>
        <ul>
          <EuiPaginationButton @pageIndex={{0}} @totalPages={{5}} class="first" />
          <EuiPaginationButton @pageIndex={{2}} @totalPages={{5}} @isActive={{true}} class="active" />
        </ul>
      </template>
    );

    assert.dom('.first').hasText('1').hasAttribute('aria-label', 'Page 1 of 5');
    assert.dom('.active').hasClass('euiPaginationButton-isActive').hasAttribute('aria-current', 'true').isDisabled();
  });

  test('EuiPageHeaderContent: breadcrumbs, title and right side items', async function (assert) {
    const breadcrumbs = [{ text: 'Home', href: '#' }, { text: 'Page' }];

    await render(
      <template>
        <EuiPageHeaderContent @pageTitle="Content title" @breadcrumbs={{breadcrumbs}}>
          <:rightSideItems as |Item|><Item><span class="right">R</span></Item></:rightSideItems>
        </EuiPageHeaderContent>
      </template>
    );

    assert.dom('.euiPageHeaderContent .euiBreadcrumb').exists({ count: 2 });
    assert.dom('.euiPageHeaderContent h1').hasText('Content title');
    assert.dom('.euiPageHeaderContent__rightSideItems .right').exists();
  });

  test('EuiWrappingPopover wraps an existing element', async function (assert) {
    const button = document.createElement('button');

    button.className = 'existing-button';
    button.textContent = 'Existing';
    document.querySelector('#ember-testing')!.appendChild(button);

    const noop = () => {};

    try {
      await render(
        <template>
          <EuiWrappingPopover @button={{button}} @isOpen={{true}} @closePopover={{noop}}>
            <span class="wrapped-content">Wrapped</span>
          </EuiWrappingPopover>
        </template>
      );

      await waitUntil(() => document.querySelector('.wrapped-content'));

      assert.ok(button.closest('.euiPopover'), 'the element is moved inside the popover anchor');
      assert.dom('.euiPopover__panel .wrapped-content', document.body).hasText('Wrapped');
    } finally {
      button.remove();
    }
  });
});
