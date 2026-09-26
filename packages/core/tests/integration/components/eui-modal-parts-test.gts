import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';

import EuiConfirmModal from '#src/components/eui-confirm-modal.gts';
import EuiModal from '#src/components/eui-modal.gts';
import EuiModalBody from '#src/components/eui-modal-body.gts';
import EuiModalFooter from '#src/components/eui-modal-footer.gts';
import EuiModalHeader from '#src/components/eui-modal-header.gts';
import EuiModalHeaderTitle from '#src/components/eui-modal-header-title.gts';

module('Integration | Component | eui-modal parts / confirm modal', function (hooks) {
  setupRenderingTest(hooks);

  test('header, title, body and footer inside a modal', async function (assert) {
    await render(
      <template>
        <EuiModal>
          <EuiModalHeader><EuiModalHeaderTitle>Title</EuiModalHeaderTitle></EuiModalHeader>
          <EuiModalBody>Body</EuiModalBody>
          <EuiModalFooter>Footer</EuiModalFooter>
        </EuiModal>
      </template>
    );

    assert.dom('.euiModal .euiModalHeader .euiModalHeader__title', document.body).hasText('Title');
    assert.dom('.euiModal .euiModalBody .euiModalBody__overflow', document.body).hasText('Body');
    assert.dom('.euiModal .euiModalFooter', document.body).hasText('Footer');
  });

  test('EuiConfirmModal confirms and cancels', async function (assert) {
    const calls: string[] = [];
    const onConfirm = () => calls.push('confirm');
    const onCancel = () => calls.push('cancel');

    await render(
      <template>
        <EuiConfirmModal @title="Delete?" @message="This cannot be undone" @confirmButtonText="Delete" @cancelButtonText="Keep" @buttonColor="danger" @onConfirm={{onConfirm}} @onCancel={{onCancel}} />
      </template>
    );

    const modal = document.querySelector('.euiModal--confirmation') as HTMLElement;

    assert.dom('.euiModalHeader__title', modal).hasText('Delete?');
    assert.dom('.euiModalBody', modal).hasText('This cannot be undone');
    assert.dom('.euiModalFooter .euiButton', modal).hasText('Delete').hasClass('euiButton--danger').hasClass('euiButton--fill');

    await click(modal.querySelector('.euiModalFooter .euiButtonEmpty')!);
    await click(modal.querySelector('.euiModalFooter .euiButton')!);

    assert.deepEqual(calls, ['cancel', 'confirm']);
  });

  test('EuiConfirmModal disabled / loading confirm button', async function (assert) {
    const noop = () => {};

    await render(
      <template><EuiConfirmModal @title="t" @confirmButtonText="OK" @cancelButtonText="No" @confirmButtonDisabled={{true}} @onConfirm={{noop}} @onCancel={{noop}} /></template>
    );

    assert.dom('.euiModal--confirmation .euiModalFooter .euiButton', document.body).isDisabled();
  });
});
