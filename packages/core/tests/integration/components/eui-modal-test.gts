import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, triggerKeyEvent } from '@ember/test-helpers';

import EuiModal from '#src/components/eui-modal.gts';

module('Integration | Component | eui-modal', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders into the body with an overlay mask', async function (assert) {
    await render(
      <template>
        <EuiModal><p class="modal-content">Hello</p></EuiModal>
      </template>
    );

    assert.dom('.euiOverlayMask', document.body).exists();
    assert.dom('.euiModal', document.body).exists();
    assert.dom('.modal-content', document.body).hasText('Hello');
    assert.dom(document.body).hasClass('euiBody-hasOverlayMask');
  });

  test('Escape calls onClose with a default-prevented event', async function (assert) {
    const events: Event[] = [];
    const onClose = (e: Event) => events.push(e);

    await render(
      <template>
        <EuiModal @onClose={{onClose}}><p>Hello</p></EuiModal>
      </template>
    );

    await triggerKeyEvent(
      document.querySelector('.euiModal') as Element,
      'keydown',
      'Escape'
    );

    assert.strictEqual(events.length, 1, 'onClose called once');
    assert.true(events[0]?.defaultPrevented, 'default was prevented');
  });

  test('the close button calls onClose', async function (assert) {
    let calls = 0;
    const onClose = () => calls++;

    await render(
      <template>
        <EuiModal @onClose={{onClose}}><p>Hello</p></EuiModal>
      </template>
    );

    await click(document.querySelector('.euiModal__closeIcon') as Element);

    assert.strictEqual(calls, 1);
  });
});
