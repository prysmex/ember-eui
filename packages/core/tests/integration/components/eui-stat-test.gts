import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiStat from '#src/components/eui-stat.gts';

module('Integration | Component | eui-stat', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders title and description', async function (assert) {
    await render(
      <template><EuiStat @title="1,000" @description="Total" @titleColor="success" @textAlign="center" /></template>
    );

    // Alignment and color are styles now (no modifier classes); see eui-content-blocks-test.
    assert.dom('.euiStat').doesNotHaveClass('euiStat--centerAligned').hasStyle({ textAlign: 'center' });
    assert.dom('.euiStat__title').hasText('1,000').doesNotHaveClass('euiStat__title--success');
    assert.dom('.euiStat__description').hasText('Total');
  });

  test('@isLoading hides the value and @reverse puts the title first', async function (assert) {
    await render(
      <template><EuiStat @title="42" @description="Answer" @isLoading={{true}} @reverse={{true}} /></template>
    );

    assert.dom('.euiStat__title').hasText('--').hasAttribute('aria-label', 'Statistic is loading');
    assert.dom('.euiStat > :first-child').hasClass('euiStat__title');
  });
});
