import { click, render, settled } from '@ember/test-helpers';
import { hbs } from 'ember-cli-htmlbars';
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';

module('Integration | Component | accordion loading', function (hooks) {
  setupRenderingTest(hooks);

  test('stopping loading removes both spinners and restores the content and extra action', async function (assert) {
    this.setProperties({
      loading: true,
      message: true,
      stopLoading: () => this.set('loading', false)
    });

    await render(hbs`
      <button data-stop {{on "click" this.stopLoading}}>False</button>
      <EuiAccordion @initialIsOpen={{true}} @isLoading={{this.loading}}
        @isLoadingMessage={{this.message}} @extraAction={{true}}>
        <:buttonContent>Loading example</:buttonContent>
        <:content><span data-content>Ready content</span></:content>
        <:extraAction><button data-extra>Extra action</button></:extraAction>
      </EuiAccordion>
    `);

    assert.dom('.euiLoadingSpinner').exists({ count: 2 });
    assert.dom('[data-content]').doesNotExist();
    assert.dom('[data-extra]').doesNotExist();
    await click('[data-stop]');
    assert.dom('.euiLoadingSpinner').doesNotExist();
    assert.dom('[data-content]').hasText('Ready content');
    assert.dom('[data-extra]').exists();
  });

  test('hiding the loading message preserves content while the trigger keeps loading', async function (assert) {
    this.set('message', true);
    await render(hbs`
      <EuiAccordion @initialIsOpen={{true}} @isLoading={{true}} @isLoadingMessage={{this.message}}>
        <:buttonContent>Loading example</:buttonContent>
        <:content><span data-content>Ready content</span></:content>
      </EuiAccordion>
    `);

    assert.dom('.euiLoadingSpinner').exists({ count: 2 });
    this.set('message', false);
    await settled();
    assert.dom('.euiLoadingSpinner').exists({ count: 1 });
    assert.dom('[data-content]').hasText('Ready content');
  });
});
