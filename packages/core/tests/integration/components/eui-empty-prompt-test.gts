import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { array } from '@ember/helper';
import { render } from '@ember/test-helpers';

import EuiButton from '#src/components/eui-button.gts';
import EuiEmptyPrompt from '#src/components/eui-empty-prompt.gts';

module('Integration | Component | eui-empty-prompt', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders icon, title and body', async function (assert) {
    await render(
      <template><EuiEmptyPrompt @iconType="search" @title="No results" @body="Try another search" /></template>
    );

    // Layout and padding are styles now (no modifier classes); see eui-content-blocks-test.
    assert.dom('.euiEmptyPrompt').doesNotHaveClass('euiEmptyPrompt--vertical');
    assert.dom('.euiEmptyPrompt__main').exists();
    assert.dom('.euiEmptyPrompt__icon svg.euiIcon').exists();
    assert.dom('.euiEmptyPrompt .euiTitle').hasText('No results');
    assert.dom('.euiEmptyPrompt__content').containsText('Try another search');
  });

  test('layout, padding and blocks', async function (assert) {
    await render(
      <template>
        <EuiEmptyPrompt @layout="horizontal" @paddingSize="s">
          <:icon><span class="custom-icon">!</span></:icon>
          <:content><p class="custom-content">Custom</p></:content>
          <:footer><span class="custom-footer">Footer</span></:footer>
        </EuiEmptyPrompt>
      </template>
    );

    assert.dom('.euiEmptyPrompt').doesNotHaveClass('euiEmptyPrompt--horizontal');
    assert.dom('.euiEmptyPrompt__icon .custom-icon').exists();
    assert.dom('.euiEmptyPrompt__content > .custom-content').exists('upstream has no contentInner wrapper');
    assert.dom('.euiEmptyPrompt__footer .custom-footer').exists();
  });

  test('a single action gets one spacer above it', async function (assert) {
    await render(
      <template>
        <EuiEmptyPrompt @title="No results" @body="Try another search" @actions={{array (component EuiButton)}} />
      </template>
    );

    assert.dom('.euiEmptyPrompt .euiEmptyPrompt__actions button.euiButton').exists('an actions array is always a flex group, as upstream');
    assert.dom('.euiEmptyPrompt .euiBorealisSpacer').exists({ count: 2 });
    // Upstream 123 puts an `s` spacer between title and body (was `m`).
    assert.deepEqual([...this.element.querySelectorAll('.euiEmptyPrompt .euiBorealisSpacer')].map((element) => getComputedStyle(element).blockSize), ['8px', '24px'], 'body and action spacing use native sizes');
  });
});
