import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, triggerKeyEvent } from '@ember/test-helpers';

import EuiFlyout from '#src/components/eui-flyout.gts';
import EuiFlyoutBody from '#src/components/eui-flyout-body.gts';
import EuiFlyoutFooter from '#src/components/eui-flyout-footer.gts';
import EuiFlyoutHeader from '#src/components/eui-flyout-header.gts';

const flyout = () => document.querySelector('.euiFlyout') as HTMLElement;

const noop = () => {};

module('Integration | Component | eui-flyout', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders a dialog with header, body and footer over a mask', async function (assert) {
    const noop = () => {};

    await render(
      <template>
        <EuiFlyout @onClose={{noop}} aria-labelledby="flyout-title">
          <EuiFlyoutHeader @hasBorder={{true}}><h2 id="flyout-title">Title</h2></EuiFlyoutHeader>
          <EuiFlyoutBody>
            <:banner><span class="banner">Banner</span></:banner>
            <:default><p class="body">Body</p></:default>
          </EuiFlyoutBody>
          <EuiFlyoutFooter><span class="footer">Footer</span></EuiFlyoutFooter>
        </EuiFlyout>
      </template>
    );

    assert.dom('.euiOverlayMask .euiFlyout', document.body).exists('ownFocus renders an overlay mask');
    assert.dom(flyout()).hasAttribute('role', 'dialog').hasClass('euiFlyout--medium').hasClass('euiFlyout--paddingLarge');
    assert.dom('.euiFlyoutHeader', flyout()).hasClass('euiFlyoutHeader--hasBorder');
    assert.dom('.euiFlyoutBody__overflow', flyout()).hasClass('euiFlyoutBody__overflow--hasBanner');
    assert.dom('.euiFlyoutBody__banner .banner', flyout()).exists();
    assert.dom('.euiFlyoutBody__overflowContent .body', flyout()).hasText('Body');
    assert.dom('.euiFlyoutFooter .footer', flyout()).hasText('Footer');
  });

  test('the close button calls @onClose', async function (assert) {
    let closed = 0;
    const onClose = () => closed++;

    await render(<template><EuiFlyout @onClose={{onClose}} @closeButtonAriaLabel="Close it">x</EuiFlyout></template>);

    const button = flyout().querySelector('.euiFlyout__closeButton') as HTMLElement;

    assert.dom(button).hasAttribute('aria-label', 'Close it');
    await click(button);
    assert.strictEqual(closed, 1);
  });

  test('the close button is labelled by default', async function (assert) {
    await render(<template><EuiFlyout @onClose={{noop}}>x</EuiFlyout></template>);

    assert
      .dom(flyout().querySelector('.euiFlyout__closeButton') as HTMLElement)
      .hasAttribute('aria-label', 'Close this dialog');
  });

  test('size, side, padding, no mask and hidden close button', async function (assert) {
    const noop = () => {};

    await render(
      <template>
        {{! the focus trap needs at least one tabbable element }}
        <EuiFlyout @onClose={{noop}} @size="s" @side="left" @paddingSize="none" @ownFocus={{false}} @hideCloseButton={{true}}>
          <button type="button">Focusable</button>
        </EuiFlyout>
      </template>
    );

    assert.dom('.euiOverlayMask', document.body).doesNotExist();
    assert.dom(flyout()).hasClass('euiFlyout--small').hasClass('euiFlyout--left').hasClass('euiFlyout--paddingNone');
    assert.dom('.euiFlyout__closeButton', flyout()).doesNotExist();
  });

  test('Escape closes an overlay flyout', async function (assert) {
    let closed = 0;
    const onClose = () => closed++;

    await render(<template><EuiFlyout @onClose={{onClose}}>x</EuiFlyout></template>);

    await triggerKeyEvent(flyout(), 'keydown', 'Escape');
    assert.strictEqual(closed, 1);
  });

  test('Escape also closes a flyout without the mask', async function (assert) {
    let closed = 0;
    const onClose = () => closed++;

    await render(<template><EuiFlyout @onClose={{onClose}} @ownFocus={{false}}>x</EuiFlyout></template>);

    await triggerKeyEvent(flyout(), 'keydown', 'Escape');
    assert.strictEqual(closed, 1);
  });
});
