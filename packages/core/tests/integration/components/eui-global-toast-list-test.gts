import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, settled } from '@ember/test-helpers';

import EuiGlobalToastList from '#src/components/eui-global-toast-list.gts';

import type EuiToasterService from '#src/services/eui-toaster.ts';

module('Integration | Component | eui-global-toast-list', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders an empty list without toasts', async function (assert) {
    await render(<template><EuiGlobalToastList /></template>);

    assert.dom('.euiGlobalToastList').exists();
    assert.dom('.euiToast').doesNotExist();
  });

  test('it renders toasts added to the euiToaster service', async function (assert) {
    const toaster = this.owner.lookup('service:eui-toaster') as EuiToasterService;

    await render(<template><EuiGlobalToastList /></template>);

    toaster.show({ title: 'Saved', color: 'success' });
    await settled();

    assert.dom('.euiToast').exists({ count: 1 });
    assert.dom('.euiToast').containsText('Saved');
  });
});
