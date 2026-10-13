import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import { click, focus, render, triggerKeyEvent, waitUntil } from '@ember/test-helpers';

import EuiBreadcrumbs from '#src/components/eui-breadcrumbs.gts';
import EuiHeaderBreadcrumbs from '#src/components/eui-header-breadcrumbs.gts';

const Closer = <template>
  <button type="button" class="closer" {{on "click" @closePopover}}>Close {{@breadcrumb.text}}</button>
</template>;


const panel = () => document.querySelector('.euiPopover__panel');
const trigger = (n = 1) => `nav > ol > li:nth-child(${n}) button.euiBreadcrumb__content`;

module('Integration | Component | eui-breadcrumbs popoverContent', function (hooks) {
  setupRenderingTest(hooks);

  test('renders a button with a chevron that toggles the popover', async function (assert) {
    const crumbs = [{ text: 'Deployment', popoverContent: 'Pick one', href: '#ignored' }, { text: 'Home' }];
    await render(<template><EuiBreadcrumbs @breadcrumbs={{crumbs}} @responsive={{false}} /></template>);

    assert.dom(trigger()).exists().hasText('Deployment');
    assert.dom('nav a').doesNotExist('href is ignored');
    assert.dom(`${trigger()} svg`).exists();
    assert.dom(`${trigger()} [aria-label]`).hasAttribute('aria-label', ' - Clicking this button will toggle a popover dialog.');
    assert.notOk(panel());

    await click(trigger());
    await waitUntil(panel);
    assert.dom('.euiPopover__panel', document.body).containsText('Pick one');

    await click(trigger());
    await waitUntil(() => !panel());
    assert.notOk(panel());
  });

  test('onClick is ignored and the popover opens with the keyboard and closes on Escape', async function (assert) {
    let clicks = 0;
    const crumbs = [{ text: 'Space', popoverContent: 'Spaces', onClick: () => clicks++ }, { text: 'Home' }];
    await render(<template><EuiBreadcrumbs @breadcrumbs={{crumbs}} @responsive={{false}} /></template>);

    // A real Enter/Space keypress on a <button> fires `click`.
    await focus(trigger());
    assert.dom(trigger()).isFocused();
    await click(trigger());
    await waitUntil(panel);
    assert.strictEqual(clicks, 0);

    await triggerKeyEvent(panel()!, 'keydown', 'Escape');
    await waitUntil(() => !panel());
    assert.notOk(panel());
  });

  test('the last breadcrumb with a popover is the current page', async function (assert) {
    const crumbs = [{ text: 'Home' }, { text: 'Now', popoverContent: 'x' }];
    await render(<template><EuiBreadcrumbs @breadcrumbs={{crumbs}} @responsive={{false}} /></template>);
    assert.dom(trigger(2)).hasAttribute('aria-current', 'page');
  });

  test('a component receives @closePopover and @breadcrumb', async function (assert) {
    const crumbs = [{ text: 'Deployment', popoverContent: Closer as unknown as never }, { text: 'Home' }];
    await render(<template><EuiBreadcrumbs @breadcrumbs={{crumbs}} @responsive={{false}} /></template>);

    await click(trigger());
    await waitUntil(panel);
    assert.dom('.closer', document.body).hasText('Close Deployment');
    await click(document.querySelector('.closer')!);
    await waitUntil(() => !panel());
    assert.notOk(panel());
  });

  test('popoverContent: true yields the breadcrumb and closePopover to the block', async function (assert) {
    const crumbs = [{ text: 'Deployment', popoverContent: true as const }, { text: 'Home' }];
    await render(<template>
      <EuiBreadcrumbs @breadcrumbs={{crumbs}} @responsive={{false}}>
        <:popoverContent as |breadcrumb closePopover|>
          <button type="button" class="closer" {{on "click" closePopover}}>Block {{breadcrumb.text}}</button>
        </:popoverContent>
      </EuiBreadcrumbs>
    </template>);

    await click(trigger());
    await waitUntil(panel);
    assert.dom('.closer', document.body).hasText('Block Deployment');
    await click(document.querySelector('.closer')!);
    await waitUntil(() => !panel());
    assert.notOk(panel());
  });

  test('popoverProps are forwarded to EuiPopover', async function (assert) {
    const crumbs = [{ text: 'A', popoverContent: 'x', popoverProps: { panelPaddingSize: 'none' as const, panelClassName: 'custom-panel' } }, { text: 'B' }];
    await render(<template><EuiBreadcrumbs @breadcrumbs={{crumbs}} @responsive={{false}} /></template>);
    await click(trigger());
    await waitUntil(panel);
    assert.dom('.euiPopover__panel', document.body).hasClass('custom-panel');
    assert.strictEqual(getComputedStyle(panel()!).paddingTop, '0px');
  });

  test('works with @max, @truncate and the collapsed popover', async function (assert) {
    const crumbs = ['One', 'Two', 'Three', 'Four', 'Five'].map((text) => ({
      text,
      popoverContent: `Content ${text}`
    }));
    await render(<template><EuiBreadcrumbs @breadcrumbs={{crumbs}} @max={{3}} @truncate={{true}} @responsive={{false}} /></template>);

    assert.dom('nav > ol > li').exists({ count: 4 });
    assert.dom('nav > ol > li button.euiBreadcrumb__content').exists({ count: 4 });

    // Breadcrumbs in the collapsed popover keep their own popovers.
    await click('[aria-label="See collapsed breadcrumbs"]');
    await waitUntil(panel);
    const nested = document.querySelectorAll('.euiPopover__panel .euiBreadcrumb button.euiBreadcrumb__content');
    assert.strictEqual(nested.length, 2);

    await click(trigger(1));
    assert.dom('.euiPopover__panel', document.body).exists();
  });

  test('@truncate limits the text, not the chevron', async function (assert) {
    const crumbs = [{ text: 'A very long breadcrumb text '.repeat(10), popoverContent: 'x' }, { text: 'Home' }];
    await render(<template><EuiBreadcrumbs @breadcrumbs={{crumbs}} @truncate={{true}} @responsive={{false}} /></template>);
    const li = document.querySelector('nav > ol > li')!;
    const text = li.querySelector('button > span')!;
    assert.strictEqual(getComputedStyle(text).textOverflow, 'ellipsis');
    assert.ok(li.querySelector('svg')!.getBoundingClientRect().width > 0);
    assert.ok(text.getBoundingClientRect().width <= 161);
  });
});

module('Integration | Component | eui-header-breadcrumbs args', function (hooks) {
  setupRenderingTest(hooks);

  const crumbs = ['One', 'Two', 'Three', 'Four', 'Five', 'Six'].map((text) => ({ text }));

  test('defaults to max 4 and application type', async function (assert) {
    await render(<template><EuiHeaderBreadcrumbs @breadcrumbs={{crumbs}} @responsive={{false}} /></template>);
    assert.dom('nav > ol > li').exists({ count: 5 });
  });

  test('forwards max, truncate and responsive', async function (assert) {
    await render(<template><EuiHeaderBreadcrumbs @breadcrumbs={{crumbs}} @max={{0}} @responsive={{false}} @truncate={{false}} /></template>);
    assert.dom('nav > ol > li').exists({ count: 6 });
    assert.notStrictEqual(getComputedStyle(document.querySelector('nav ol')!).flexWrap, 'nowrap');
  });

  test('popover breadcrumbs work in the header', async function (assert) {
    const items = [{ text: 'Space', popoverContent: 'Spaces' }, { text: 'Home' }];
    await render(<template><EuiHeaderBreadcrumbs @breadcrumbs={{items}} @responsive={{false}} /></template>);
    await click(trigger());
    await waitUntil(panel);
    assert.dom('.euiPopover__panel', document.body).containsText('Spaces');
  });
});
