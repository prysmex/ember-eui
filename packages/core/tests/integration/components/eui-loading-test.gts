import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiLoadingContent from '#src/components/eui-loading-content.gts';
import EuiLoadingLogo from '#src/components/eui-loading-logo.gts';
import EuiLoadingSpinner from '#src/components/eui-loading-spinner.gts';

module('Integration | Component | eui-loading-*', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiLoadingSpinner sizes', async function (assert) {
    await render(
      <template>
        <EuiLoadingSpinner class="default" />
        <EuiLoadingSpinner @size="xl" class="big" />
      </template>
    );

    assert.dom('.default').hasClass('euiLoadingSpinner').hasClass('euiLoadingSpinner--medium');
    assert.dom('.big').hasClass('euiLoadingSpinner--xLarge');
  });

  test('EuiLoadingContent renders @lines placeholder lines', async function (assert) {
    await render(<template><EuiLoadingContent @lines={{4}} @singleLineClasses="extra" /></template>);

    assert.dom('.euiLoadingContent .euiLoadingContent__singleLine').exists({ count: 4 });
    assert.dom('.euiLoadingContent__singleLine').hasClass('extra');
  });

  test('EuiLoadingLogo renders the logo icon at the given size', async function (assert) {
    await render(<template><EuiLoadingLogo @logo="logoElastic" @size="l" /></template>);

    assert.dom('.euiLoadingLogo').hasClass('euiLoadingLogo--large');
    assert.dom('.euiLoadingLogo__icon svg').hasAttribute('data-type', 'logoElastic');
  });
});
