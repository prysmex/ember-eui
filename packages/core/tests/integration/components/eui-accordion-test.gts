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
    assert.dom('.euiAccordion__button').hasAttribute('aria-expanded', 'false');

    await click('.euiAccordion__button');
    assert.dom('.euiAccordion').hasClass('euiAccordion-isOpen');
    assert.dom('.euiAccordion__button').hasAttribute('aria-expanded', 'true');

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

  test('the trigger controls the content region, which it labels', async function (assert) {
    await render(
      <template>
        <EuiAccordion class="with-id" @id="details">
          <:buttonContent>Details</:buttonContent>
          <:content><p>Content</p></:content>
        </EuiAccordion>
        <EuiAccordion class="generated">
          <:buttonContent>More</:buttonContent>
          <:content><p>More content</p></:content>
        </EuiAccordion>
      </template>
    );

    for (const selector of ['.with-id', '.generated']) {
      const button = document.querySelector(`${selector} .euiAccordion__button`) as HTMLElement;
      const region = document.querySelector(`${selector} [role="region"]`) as HTMLElement;

      assert.ok(region.id, `${selector}: the region has an id`);
      assert.strictEqual(button.getAttribute('aria-controls'), region.id);
      assert.ok(button.id, `${selector}: the trigger has an id`);
      assert.strictEqual(region.getAttribute('aria-labelledby'), button.id);
      assert.dom(button).doesNotHaveAttribute('aria-labelledby');
    }

    assert.dom('.with-id [role="region"]').hasAttribute('id', 'details');
  });

  test('@isLoading shows spinners in place of the content and extra action', async function (assert) {
    const state = new (class {
      @tracked isLoading = true;
    })();

    await render(
      <template>
        <EuiAccordion
          @id="acc"
          @buttonContent="Toggle"
          @initialIsOpen={{true}}
          @isLoading={{state.isLoading}}
          @isLoadingMessage={{true}}
          @extraAction={{true}}
        >
          <:content><span data-test-content>Ready</span></:content>
          <:extraAction><button data-test-extra>Extra</button></:extraAction>
        </EuiAccordion>
      </template>
    );

    assert.dom('.euiLoadingSpinner').exists({ count: 2 });
    assert.dom('[data-test-content]').doesNotExist();
    assert.dom('[data-test-extra]').doesNotExist();

    state.isLoading = false;
    await rerender();

    assert.dom('.euiLoadingSpinner').doesNotExist();
    assert.dom('[data-test-content]').hasText('Ready');
    assert.dom('[data-test-extra]').exists();
  });

  test('@isLoadingMessage={{false}} keeps the content while the trigger loads', async function (assert) {
    const state = new (class {
      @tracked isLoadingMessage = true;
    })();

    await render(
      <template>
        <EuiAccordion
          @id="acc"
          @buttonContent="Toggle"
          @initialIsOpen={{true}}
          @isLoading={{true}}
          @isLoadingMessage={{state.isLoadingMessage}}
        >
          <:content><span data-test-content>Ready</span></:content>
        </EuiAccordion>
      </template>
    );

    assert.dom('.euiLoadingSpinner').exists({ count: 2 });

    state.isLoadingMessage = false;
    await rerender();

    assert.dom('.euiLoadingSpinner').exists({ count: 1 });
    assert.dom('[data-test-content]').hasText('Ready');
  });
});
