import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiLoadingChart from '#src/components/eui-loading-chart.gts';
import EuiLoadingElastic from '#src/components/eui-loading-elastic.gts';

module('Integration | Component | eui-loading-chart and eui-loading-elastic', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiLoadingChart renders four bars', async function (assert) {
    await render(
      <template>
        <EuiLoadingChart aria-label="Loading chart" class="default" />
        <EuiLoadingChart @size="xl" @mono={{true}} class="mono" />
      </template>
    );

    assert.dom('.default').hasClass('euiLoadingChart--medium').hasAria('label', 'Loading chart');
    assert.dom('.default .euiLoadingChart__bar').exists({ count: 4 });
    assert.dom('.mono').hasClass('euiLoadingChart--xLarge').hasClass('euiLoadingChart--mono');
  });

  test('EuiLoadingElastic renders the logo', async function (assert) {
    await render(<template><EuiLoadingElastic @size="xxl" /></template>);

    assert.dom('.euiLoadingElastic').hasClass('euiLoadingElastic--xxLarge');
    assert.dom('.euiLoadingElastic .euiIcon').exists();
  });
});
