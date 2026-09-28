import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import { click, render, triggerKeyEvent } from '@ember/test-helpers';

import EuiContextMenu from '#src/components/eui-context-menu.gts';
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

  test('@layoutAlign aligns the icon and text', async function (assert) {
    await render(
      <template>
        <EuiContextMenuItem @icon="copy" class="top" @layoutAlign="top">Copy</EuiContextMenuItem>
        <EuiContextMenuItem @icon="copy" class="center">Copy</EuiContextMenuItem>
      </template>
    );

    assert.dom('.top .euiContextMenu__itemLayout').hasClass('euiContextMenu__itemLayout--top');
    assert.dom('.top').doesNotHaveClass('euiContextMenu__itemLayout--top', 'only on the inner layout');
    assert
      .dom('.center .euiContextMenu__itemLayout')
      .doesNotHaveClass('euiContextMenu__itemLayout--top')
      .doesNotHaveClass('euiContextMenu__itemLayout--bottom');
  });

  test('an item without @icon renders no icon', async function (assert) {
    await render(<template><EuiContextMenuItem>Plain</EuiContextMenuItem></template>);

    assert.dom('.euiContextMenuItem .euiContextMenu__icon').doesNotExist();
    assert.dom('.euiContextMenuItem').hasText('Plain');
  });

  test('a panel title, and a back button with @onClose', async function (assert) {
    let closed = 0;
    const onClose = () => closed++;

    await render(
      <template>
        <EuiContextMenuPanel class="plain" @title="Actions" />
        <EuiContextMenuPanel class="back" @title="Share" @onClose={{onClose}} @size="s" />
      </template>
    );

    assert.dom('.plain div.euiContextMenuPanelTitle').hasText('Actions');
    assert.dom('.back button.euiContextMenuPanelTitle').hasClass('euiContextMenuPanelTitle--small').hasText('Share');
    await click('.back button.euiContextMenuPanelTitle');
    assert.strictEqual(closed, 1);
  });

  test('arrow keys move between the items of a panel', async function (assert) {
    await render(
      <template>
        <EuiContextMenuPanel>
          <EuiContextMenuItem class="one">One</EuiContextMenuItem>
          <EuiContextMenuItem class="two">Two</EuiContextMenuItem>
        </EuiContextMenuPanel>
      </template>
    );

    await triggerKeyEvent('.euiContextMenuPanel', 'keydown', 'ArrowDown');
    assert.dom('.one').isFocused();
    await triggerKeyEvent('.euiContextMenuPanel', 'keydown', 'ArrowDown');
    assert.dom('.two').isFocused();
    await triggerKeyEvent('.euiContextMenuPanel', 'keydown', 'ArrowDown');
    assert.dom('.one').isFocused('wraps around');
    await triggerKeyEvent('.euiContextMenuPanel', 'keydown', 'ArrowUp');
    assert.dom('.two').isFocused();
  });

  module('EuiContextMenu', function () {
    const panels = [
      {
        id: 0,
        title: 'Options',
        items: [
          { name: 'Share', icon: 'share', panel: 1 },
          { isSeparator: true as const },
          { name: 'Delete', icon: 'trash', 'data-test-subj': 'delete' },
        ],
      },
      {
        id: 1,
        title: 'Share',
        items: [{ name: 'Copy link', icon: 'link' }],
      },
      { id: 2, title: 'Settings' },
    ];

    test('it shows the initial panel, and items open other panels', async function (assert) {
      await render(<template><EuiContextMenu @panels={{panels}} @initialPanelId={{0}} /></template>);

      assert.dom('.euiContextMenu .euiContextMenuPanel').exists({ count: 1 });
      assert.dom('.euiContextMenuPanelTitle').hasText('Options');
      assert.dom('.euiContextMenuItem').exists({ count: 2 });
      assert.dom('.euiHorizontalRule').exists();
      assert.dom('[data-test-subj="delete"]').hasText('Delete');
      assert.dom('.euiContextMenuItem .euiContextMenu__arrow').exists({ count: 1 }, 'items opening a panel have an arrow');

      await click('.euiContextMenuItem');
      assert.dom('.euiContextMenuPanel').exists({ count: 1 }, 'without animations the old panel goes at once');
      assert.dom('button.euiContextMenuPanelTitle').hasText('Share');
      assert.dom('.euiContextMenuItem').hasText('Copy link');

      await click('button.euiContextMenuPanelTitle');
      assert.dom('.euiContextMenuPanelTitle').hasText('Options');
      assert.dom('div.euiContextMenuPanelTitle').exists('the first panel has no back button');
    });

    test('item clicks call onClick', async function (assert) {
      const clicked: string[] = [];
      const withClicks = [
        {
          id: 'main',
          items: [
            { name: 'Edit', onClick: () => clicked.push('edit') },
            { name: 'More', panel: 'more', onClick: () => clicked.push('more') },
          ],
        },
        { id: 'more', items: [{ name: 'Archive' }] },
      ];

      await render(<template><EuiContextMenu @panels={{withClicks}} @initialPanelId="main" /></template>);

      await click('.euiContextMenuItem:first-child');
      await click('.euiContextMenuItem:last-child');
      assert.deepEqual(clicked, ['edit', 'more']);
      assert.dom('.euiContextMenuItem').hasText('Archive');
    });

    test('the keyboard moves between items and panels', async function (assert) {
      await render(<template><EuiContextMenu @panels={{panels}} @initialPanelId={{0}} /></template>);

      await triggerKeyEvent('.euiContextMenuPanel', 'keydown', 'ArrowDown');
      assert.dom('.euiContextMenuItem').isFocused();

      await triggerKeyEvent('.euiContextMenuPanel', 'keydown', 'ArrowRight');
      assert.dom('.euiContextMenuPanelTitle').hasText('Share');
      assert.dom('.euiContextMenuItem').isFocused('the first item of the new panel is focused');

      await triggerKeyEvent('.euiContextMenuPanel', 'keydown', 'ArrowLeft');
      assert.dom('.euiContextMenuPanelTitle').hasText('Options');
      assert.dom('.euiContextMenuItem').isFocused('back on the item that opened it');
    });

    test('panels without items render the content block', async function (assert) {
      await render(
        <template>
          <EuiContextMenu @panels={{panels}} @initialPanelId={{2}} @size="s">
            <:content as |panel|><p class="custom">Content of {{panel.title}}</p></:content>
          </EuiContextMenu>
        </template>
      );

      assert.dom('.euiContextMenu').hasClass('euiContextMenu--small');
      assert.dom('.custom').hasText('Content of Settings');
    });
  });
});
