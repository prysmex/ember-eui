import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import { click, render } from '@ember/test-helpers';

import EuiContextMenuItem from '#src/components/eui-context-menu-item.gts';
import EuiContextMenuPanel from '#src/components/eui-context-menu-panel.gts';

module('Integration | Component | eui-context-menu', function (hooks) {
  setupRenderingTest(hooks);

  test('items render as buttons or links inside a panel', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;

    await render(
      <template>
        <EuiContextMenuPanel>
          <EuiContextMenuItem @icon="copy" class="copy" {{on "click" onClick}}>Copy</EuiContextMenuItem>
          <EuiContextMenuItem @icon="link" @href="#share" class="share">Share</EuiContextMenuItem>
          <EuiContextMenuItem @icon="trash" @disabled={{true}} class="delete">Delete</EuiContextMenuItem>
          <EuiContextMenuItem @icon="gear" @hasPanel={{true}} @size="s" class="more">More</EuiContextMenuItem>
        </EuiContextMenuPanel>
      </template>
    );

    assert.dom('.euiContextMenuPanel').hasAttribute('tabindex', '-1');
    assert.dom('button.copy').hasClass('euiContextMenuItem');
    assert.dom('button.copy .euiContextMenuItem__text').hasText('Copy');
    assert.dom('button.copy svg.euiContextMenu__icon').exists();
    assert.dom('a.share').hasAttribute('href', '#share');
    assert.dom('button.delete').isDisabled().hasClass('euiContextMenuItem-isDisabled');
    assert.dom('button.more').hasClass('euiContextMenuItem--small');
    assert.dom('button.more svg.euiIcon').exists({ count: 2 }, 'icon and panel arrow');

    await click('button.copy');
    assert.strictEqual(clicks, 1);
  });

  test('@isLoading shows a spinner instead of the icon', async function (assert) {
    await render(<template><EuiContextMenuItem @icon="copy" @isLoading={{true}}>Copy</EuiContextMenuItem></template>);

    assert.dom('.euiContextMenuItem .euiContextMenu__icon.euiLoadingSpinner').exists();
  });
});
