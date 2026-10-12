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

    // Legacy size/mono modifier classes removed; sizes are computed (eui-utilities-test).
    assert.dom('.default').hasClass('euiLoadingChart').hasAria('label', 'Loading chart');
    assert.dom('.default .euiLoadingChart__bar').exists({ count: 4 });
    assert.strictEqual(getComputedStyle(document.querySelector('.mono')!).height, '32px');
  });

  test('EuiLoadingElastic renders the logo', async function (assert) {
    await render(<template><EuiLoadingElastic @size="xxl" /></template>);

    assert.dom('.euiLoadingElastic').hasAttribute('role', 'progressbar');
    assert.dom('.euiLoadingElastic .euiIcon').exists();
  });
});
