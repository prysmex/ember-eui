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

    assert.dom('.euiEmptyPrompt').hasClass('euiEmptyPrompt--vertical').hasClass('euiEmptyPrompt--paddingLarge');
    assert.dom('.euiEmptyPrompt__icon svg.euiIcon').exists();
    assert.dom('.euiEmptyPrompt .euiTitle').hasText('No results');
    assert.dom('.euiEmptyPrompt__contentInner').containsText('Try another search');
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

    assert.dom('.euiEmptyPrompt').hasClass('euiEmptyPrompt--horizontal').hasClass('euiEmptyPrompt--paddingSmall');
    assert.dom('.euiEmptyPrompt__icon .custom-icon').exists();
    assert.dom('.euiEmptyPrompt__contentInner .custom-content').exists();
    assert.dom('.euiEmptyPrompt__footer .custom-footer').exists();
  });

  test('a single action gets one spacer above it', async function (assert) {
    await render(
      <template>
        <EuiEmptyPrompt @title="No results" @body="Try another search" @actions={{array (component EuiButton)}} />
      </template>
    );

    assert.dom('.euiEmptyPrompt button.euiButton').exists();
    assert.dom('.euiEmptyPrompt .euiSpacer--l').exists({ count: 1 });
  });
});
