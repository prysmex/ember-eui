import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import { click, render, rerender } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiButton from '#src/components/eui-button.gts';
import EuiCollapsibleNav from '#src/components/eui-collapsible-nav.gts';
import EuiCollapsibleNavGroup from '#src/components/eui-collapsible-nav-group.gts';

class State {
  @tracked isOpen = false;
  toggle = () => (this.isOpen = !this.isOpen);
  close = () => (this.isOpen = false);
}

module('Integration | Component | eui-collapsible-nav', function (hooks) {
  setupRenderingTest(hooks);

  test('the button toggles a flyout nav', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiCollapsibleNav @isOpen={{state.isOpen}} @onClose={{state.close}}>
          <:button as |trigger|>
            <EuiButton class="toggle" {{trigger}} {{on "click" state.toggle}}>Menu</EuiButton>
          </:button>
          <:content><p class="nav-content">Nav</p></:content>
        </EuiCollapsibleNav>
      </template>
    );

    assert.dom('.euiCollapsibleNav', document.body).doesNotExist();
    assert.dom('.toggle').hasAttribute('aria-controls');

    await click('.toggle');

    assert.dom('.euiCollapsibleNav', document.body).exists();
    assert.dom('.euiCollapsibleNav .nav-content', document.body).hasText('Nav');
    assert.dom('.toggle').hasAttribute('aria-expanded', 'true');

    state.close();
    await rerender();
    assert.dom('.euiCollapsibleNav', document.body).doesNotExist();
  });

  test('the trigger reports aria-expanded="false" when closed', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiCollapsibleNav @isOpen={{state.isOpen}} @onClose={{state.close}}>
          <:button as |trigger|><EuiButton class="toggle" {{trigger}}>Menu</EuiButton></:button>
          <:content>Nav</:content>
        </EuiCollapsibleNav>
      </template>
    );

    assert.dom('.toggle').hasAttribute('aria-expanded', 'false');
    assert.dom('.toggle').hasAttribute('aria-pressed', 'false');
  });

  test('EuiCollapsibleNavGroup: static and collapsible groups', async function (assert) {
    await render(
      <template>
        <EuiCollapsibleNavGroup @background="light" @iconType="logoKibana" class="static">
          <:title>Kibana</:title>
          <:content><span class="static-content">links</span></:content>
        </EuiCollapsibleNavGroup>
        <EuiCollapsibleNavGroup @isCollapsible={{true}} @initialIsOpen={{false}} class="collapsible">
          <:title>Settings</:title>
          <:content><span class="collapsible-content">more</span></:content>
        </EuiCollapsibleNavGroup>
      </template>
    );

    assert.dom('.static').hasClass('euiCollapsibleNavGroup--light').hasClass('euiCollapsibleNavGroup--withHeading');
    assert.dom('.static .euiCollapsibleNavGroup__title').hasText('Kibana');
    assert.dom('.static svg.euiIcon').exists();

    assert.dom('.collapsible.euiAccordion').doesNotHaveClass('euiAccordion-isOpen');
    await click('.collapsible .euiCollapsibleNavGroup__heading');
    assert.dom('.collapsible.euiAccordion').hasClass('euiAccordion-isOpen');
    assert.dom('.collapsible .collapsible-content').hasText('more');
  });
});
