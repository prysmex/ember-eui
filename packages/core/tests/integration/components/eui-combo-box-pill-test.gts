import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';

import EuiComboBoxPill from '#src/components/eui-combo-box-pill.gts';
import EuiSelectableListItem from '#src/components/eui-selectable-list-item.gts';

module('Integration | Component | eui-combo-box-pill / selectable-list-item', function (hooks) {
  setupRenderingTest(hooks);

  test('a pill with @onClose renders a close icon that passes the option', async function (assert) {
    const closed: unknown[] = [];
    const onClose = (option: unknown) => closed.push(option);
    const option = { label: 'Apple' };

    await render(
      <template><EuiComboBoxPill @option={{option}} @onClose={{onClose}} @color="primary" @iconOnClickAriaLabel="Remove Apple">Apple</EuiComboBoxPill></template>
    );

    assert.dom('.euiComboBoxPill.euiBadge').hasText('Apple');
    await click('.euiComboBoxPill [aria-label="Remove Apple"]');
    assert.deepEqual(closed, [option]);
  });

  test('plain text and read only pills', async function (assert) {
    await render(
      <template>
        <EuiComboBoxPill @asPlainText={{true}} class="plain">Plain</EuiComboBoxPill>
        <EuiComboBoxPill class="badge">Badge</EuiComboBoxPill>
      </template>
    );

    assert.dom('span.euiComboBoxPill--plainText').hasText('Plain');
    assert.dom('.badge.euiBadge').hasText('Badge');
  });

  test('EuiSelectableListItem option states', async function (assert) {
    await render(
      <template>
        <ul>
          <EuiSelectableListItem @checked="on" @isFocused={{true}} class="on">On</EuiSelectableListItem>
          <EuiSelectableListItem class="off">Off</EuiSelectableListItem>
          <EuiSelectableListItem @checked="on" @disabled={{true}} class="disabled">Disabled</EuiSelectableListItem>
        </ul>
      </template>
    );

    assert.dom('li.on').hasAttribute('role', 'option').hasAttribute('aria-selected', 'true');
    assert.dom('li.on .euiSelectableListItem__text').hasText('On');
    assert.dom('li.off').hasAttribute('aria-selected', 'false');
    assert.dom('li.disabled').hasAttribute('aria-selected', 'false').hasAttribute('aria-disabled', 'true');
  });
});
