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

    // legacy `euiPopover--anchorUpCenter` class is gone; placement is
    // asserted on geometry below
    assert.dom('.euiPopover__anchor .trigger').exists();
    assert.strictEqual(panel(), null, 'closed initially');

    await click('.trigger');
    await waitUntil(panel);

    assert.dom(panel()).hasAttribute('role', 'dialog');
    // was `euiPopover__panel--top`: the panel now sits above the trigger
    assert.true(
      panel()!.getBoundingClientRect().bottom <= document.querySelector('.trigger')!.getBoundingClientRect().top,
      'upCenter opens above the anchor'
    );
    // was `euiPopoverTitle--paddingSmall` / `euiPopoverFooter--paddingMedium`
    assert.dom('.euiPopoverTitle', panel()).hasText('Title').hasStyle({ paddingTop: '8px' });
    assert.dom('.popover-body', panel()).hasText('Content');
    assert.dom('.euiPopoverFooter', panel()).hasText('Footer').hasStyle({ paddingTop: '16px' });
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
    // were `euiPopover--displayBlock` / `euiPopover__panel-noArrow`
    assert.dom('.euiPopover').hasStyle({ display: 'block' });
    assert.dom('.euiPopover__arrow', panel()).doesNotExist();
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
    // were `euiInputPopover--fullWidth` / `euiPopover__panel-isAttached`
    assert.dom('.euiInputPopover').hasStyle({ maxWidth: '100%' });
    assert.dom('.euiInputPopover .the-input').exists();
    assert.dom('.euiPopover__arrow', panel()).doesNotExist();
    assert.dom(panel()).hasStyle({ transform: 'none' }, 'attached panels do not slide');
    assert.dom('.input-popover-content', panel()).hasText('Options');
  });
});
