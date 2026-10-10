import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import { clearRender, click, render, rerender, triggerEvent, triggerKeyEvent, waitUntil } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiButton from '#src/components/eui-button.gts';
import EuiInputPopover from '#src/components/eui-input-popover.gts';
import EuiPopover from '#src/components/eui-popover.gts';
import EuiPopoverFooter from '#src/components/eui-popover-footer.gts';
import EuiPopoverTitle from '#src/components/eui-popover-title.gts';

class State {
  @tracked isOpen = false;
  closes = 0;
  open = () => (this.isOpen = true);
  close = () => {
    this.closes++;
    this.isOpen = false;
  };
}

const panel = () => document.querySelector('.euiPopover__panel') as HTMLElement | null;

module('Integration | Component | eui-popover', function (hooks) {
  setupRenderingTest(hooks);

  test('the button opens a dialog panel with title, content and footer', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiPopover @isOpen={{state.isOpen}} @closePopover={{state.close}} @anchorPosition="upCenter" @panelPaddingSize="s">
          <:button><EuiButton class="trigger" {{on "click" state.open}}>Open</EuiButton></:button>
          <:content>
            <EuiPopoverTitle @paddingSize="s">Title</EuiPopoverTitle>
            <p class="popover-body">Content</p>
            <EuiPopoverFooter @paddingSize="m">Footer</EuiPopoverFooter>
          </:content>
        </EuiPopover>
      </template>
    );

    assert.dom('.euiPopover').hasClass('euiPopover--anchorUpCenter');
    assert.dom('.euiPopover__anchor .trigger').exists();
    assert.strictEqual(panel(), null, 'closed initially');

    await click('.trigger');
    await waitUntil(panel);

    assert.dom(panel()).hasAttribute('role', 'dialog').hasClass('euiPopover__panel--top');
    assert.dom('.euiPopoverTitle', panel()).hasText('Title').hasClass('euiPopoverTitle--paddingSmall');
    assert.dom('.popover-body', panel()).hasText('Content');
    assert.dom('.euiPopoverFooter', panel()).hasText('Footer').hasClass('euiPopoverFooter--paddingMedium');
  });

  test('Escape and outside clicks call @closePopover', async function (assert) {
    const state = new State();

    state.isOpen = true;

    await render(
      <template>
        <button type="button" class="outside">outside</button>
        <EuiPopover @isOpen={{state.isOpen}} @closePopover={{state.close}}>
          <:button><EuiButton>Anchor</EuiButton></:button>
          <:content><button type="button">inside</button></:content>
        </EuiPopover>
      </template>
    );

    await waitUntil(panel);
    await triggerKeyEvent(panel()!, 'keydown', 'Escape');
    assert.strictEqual(state.closes, 1, 'Escape');
    await waitUntil(() => !panel());
    assert.dom('.euiPopover__panel', document.body).doesNotExist('Escape closes the rendered panel');

    state.isOpen = true;
    await rerender();
    await waitUntil(panel);
    await triggerEvent('.outside', 'mousedown');
    await triggerEvent('.outside', 'mouseup');
    await click('.outside');
    assert.true(state.closes >= 2, 'outside click');
    await waitUntil(() => !panel());
    assert.dom('.euiPopover__panel', document.body).doesNotExist();
  });

  test('destroying an open popover removes its portaled panel', async function (assert) {
    const state = new State();
    state.isOpen = true;

    await render(
      <template>
        <EuiPopover @isOpen={{state.isOpen}} @closePopover={{state.close}}>
          <:button><button type="button">Anchor</button></:button>
          <:content><span data-test-portaled-content>Content</span></:content>
        </EuiPopover>
      </template>
    );

    await waitUntil(panel);
    await clearRender();
    assert.dom('.euiPopover__panel', document.body).doesNotExist();
    assert.dom('[data-test-portaled-content]', document.body).doesNotExist();
    assert.strictEqual(state.closes, 0, 'teardown does not report a user dismissal');
  });

  test('display block and no arrow', async function (assert) {
    const state = new State();
    state.isOpen = true;

    await render(
      <template>
        <EuiPopover @isOpen={{state.isOpen}} @closePopover={{state.close}} @display="block" @hasArrow={{false}}>
          <:button><EuiButton>Anchor</EuiButton></:button>
          <:content>x</:content>
        </EuiPopover>
      </template>
    );

    await waitUntil(panel);
    assert.dom('.euiPopover').hasClass('euiPopover--displayBlock');
    assert.dom(panel()).hasClass('euiPopover__panel-noArrow');
  });

  test('EuiInputPopover attaches the panel to the input', async function (assert) {
    const state = new State();
    state.isOpen = true;

    await render(
      <template>
        <EuiInputPopover @isOpen={{state.isOpen}} @closePopover={{state.close}} @fullWidth={{true}}>
          <:input><input class="the-input" /></:input>
          <:content><span class="input-popover-content">Options</span></:content>
        </EuiInputPopover>
      </template>
    );

    await waitUntil(panel);
    assert.dom('.euiInputPopover').hasClass('euiInputPopover--fullWidth');
    assert.dom('.euiInputPopover .the-input').exists();
    assert.dom(panel()).hasClass('euiPopover__panel-isAttached');
    assert.dom('.input-popover-content', panel()).hasText('Options');
  });
});
