import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, settled, triggerEvent, waitUntil } from '@ember/test-helpers';

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

  test('dismissal removes only the closed toast and reports it once', async function (assert) {
    const toaster = this.owner.lookup('service:eui-toaster') as EuiToasterService;
    const dismissed: string[] = [];
    const dismiss = (toast: { id?: string }) => dismissed.push(toast.id!);

    await render(<template><EuiGlobalToastList @toastLifeTimeMs={{60000}} @dismissToast={{dismiss}} /></template>);

    toaster.show({ id: 'saved', title: 'Saved' });
    toaster.show({ id: 'other', title: 'Other' });
    await waitUntil(() => this.element.querySelectorAll('.euiToast').length === 2);
    await triggerEvent('.euiGlobalToastList', 'mouseenter');
    await click(this.element.querySelectorAll('.euiToast__closeButton')[0]!);
    await waitUntil(() => toaster.toasts.length === 1);
    await settled();

    assert.deepEqual(dismissed, ['saved']);
    assert.deepEqual(toaster.toasts.map((toast) => toast.id), ['other']);
    assert.dom('.euiToast').exists({ count: 1 }).containsText('Other');
  });
});
