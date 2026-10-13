import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';

import EuiCallOut from '#src/components/eui-call-out.gts';

module('Integration | Component | eui-call-out', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders title, icon and body', async function (assert) {
    await render(
      <template>
        <EuiCallOut @title="Heads up" @iconType="help" @color="warning">Body text</EuiCallOut>
      </template>
    );

    assert.dom('.euiCallOut').hasClass('euiCallOut--warning');
    // Upstream has no header wrapper: the title is a `p` by default.
    assert.dom('p.euiCallOutHeader__title').hasText('Heads up');
    assert.dom('.euiCallOut svg[aria-hidden="true"]').exists({ count: 1 }, 'the custom icon replaces the default one');
    assert.dom('.euiCallOut .euiNotificationIcon').doesNotExist();
    assert.dom('.euiCallOut .euiCallOut__additionalContent').hasText('Body text');
  });

  test('named blocks and @heading', async function (assert) {
    await render(
      <template>
        <EuiCallOut @heading="h3" @size="s">
          <:title>Block title</:title>
          <:body>Block body</:body>
        </EuiCallOut>
      </template>
    );

    // Upstream has no size modifier class; size is the `data-size` attribute.
    assert.dom('.euiCallOut').hasAttribute('data-size', 's');
    assert.dom('h3.euiCallOutHeader__title').hasText('Block title');
    assert.dom('.euiCallOut .euiCallOut__additionalContent').hasText('Block body');
  });

  test('@actionProps render a small primary EuiButton and secondary EuiButtonEmpty in the callout color', async function (assert) {
    const clicks: string[] = [];
    const actionProps = {
      primary: { children: 'Update now', onClick: () => clicks.push('primary'), 'data-test-subj': 'p-action' },
      secondary: { children: 'Learn more', href: '#learn', className: 'extra' }
    };
    await render(
      <template>
        <EuiCallOut @title="Needs update" @color="warning" @text="It may take a while" @actionProps={{actionProps}} />
      </template>
    );

    assert.dom('.euiCallOut button.euiCallOutAction').hasText('Update now').hasAttribute('data-test-subj', 'p-action');
    assert.dom('.euiCallOut a.euiCallOutAction.extra').hasText('Learn more').hasAttribute('href', '#learn');
    // Emotion labels carry the size and color (`…-s-base-warning`)
    assert.ok(/-s-.*warning/.test(document.querySelector('button.euiCallOutAction')!.className), 'small, warning button');
    assert.ok(/-s-.*warning/.test(document.querySelector('a.euiCallOutAction')!.className), 'small, warning empty button');

    await click('button.euiCallOutAction');
    assert.deepEqual(clicks, ['primary']);
  });

  test('a secondary action can stand alone, and actionProps combine with the <:actions> block', async function (assert) {
    const actionProps = { secondary: { children: 'Only secondary' } };
    await render(
      <template>
        <EuiCallOut @title="Alone" @actionProps={{actionProps}}>
          <:actions><button type="button" class="from-block">Block</button></:actions>
        </EuiCallOut>
      </template>
    );

    assert.dom('.euiCallOutAction').exists({ count: 1 });
    assert.dom('.euiCallOutAction + .from-block').exists('block content follows the props actions');
  });

  test('no actions area without actionProps or the block', async function (assert) {
    await render(<template><EuiCallOut @title="Plain" /></template>);
    assert.dom('.euiCallOutAction').doesNotExist();
  });

  test('an action with tooltipProps gets a tooltip', async function (assert) {
    const actionProps = { primary: { children: 'Hover', tooltipProps: { content: 'Tip text' } } };
    await render(<template><EuiCallOut @title="T" @actionProps={{actionProps}} /></template>);

    assert.dom('.euiToolTipAnchor .euiCallOutAction').exists();
  });
  test('action popoverProps: content only while isOpen (primary and secondary)', async function (assert) {
    const noop = () => {};
    const Content = <template><span class="pop-content">Popover content</span></template>;
    const closed = { primary: { children: 'P', popoverProps: { isOpen: false, closePopover: noop, children: Content } } };
    await render(<template><EuiCallOut @title="T" @actionProps={{closed}} /></template>);
    assert.dom('.pop-content').doesNotExist('closed popover renders no content');

    const open = {
      primary: { children: 'P' },
      secondary: { children: 'S', popoverProps: { isOpen: true, closePopover: noop, children: 'Secondary popover text' } }
    };
    await render(<template><EuiCallOut @title="T" @actionProps={{open}} /></template>);
    assert.dom('[data-popover-panel]').hasText('Secondary popover text');
    assert.dom('.euiPopover .euiCallOutAction').exists({ count: 1 }, 'the action is the popover button');

    const primaryOpen = { primary: { children: 'P', popoverProps: { isOpen: true, closePopover: noop, children: Content } } };
    await render(<template><EuiCallOut @title="T" @actionProps={{primaryOpen}} /></template>);
    assert.dom('.pop-content').hasText('Popover content');
  });
});
