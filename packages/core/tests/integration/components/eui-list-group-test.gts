import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, triggerEvent, waitUntil } from '@ember/test-helpers';

import EuiListGroup from '#src/components/eui-list-group.gts';
import EuiListGroupItem from '#src/components/eui-list-group-item.gts';

module('Integration | Component | eui-list-group', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders items; border and default max width are computed styles', async function (assert) {
    await render(
      <template>
        <EuiListGroup @gutterSize="m" @bordered={{true}} @flush={{true}} @maxWidth={{true}}>
          <EuiListGroupItem @label="One" />
          <EuiListGroupItem @label="Two" />
        </EuiListGroup>
      </template>
    );

    // Latest EUI has no gutter/flush modifiers (deprecated no-ops) and no
    // legacy modifier classes; the border and max width are upstream styles.
    assert.dom('ul.euiListGroup').hasStyle({ borderTopWidth: '1px', borderTopStyle: 'solid', maxWidth: '400px' });
    assert.dom('ul.euiListGroup').doesNotHaveClass('euiListGroup-bordered').doesNotHaveClass('euiListGroup--gutterMedium');
    assert.dom('ul.euiListGroup .euiListGroupItem').exists({ count: 2 });
  });

  test('a custom @maxWidth becomes an inline style', async function (assert) {
    await render(<template><EuiListGroup @maxWidth="200px"><EuiListGroupItem @label="One" /></EuiListGroup></template>);

    assert.dom('ul.euiListGroup').hasStyle({ maxWidth: '200px' });
  });

  test('@listItems render EuiListGroupItems instead of the block, inheriting @color and @wrapText', async function (assert) {
    const clicked: string[] = [];
    const items = [
      { label: 'Link', href: '/somewhere', iconType: 'user' },
      { label: 'Action', onClick: () => clicked.push('action'), isActive: true },
      { label: 'Plain', color: 'primary' }
    ];
    await render(
      <template>
        <EuiListGroup @listItems={{items}} @wrapText={{true}} @color="subdued">
          <EuiListGroupItem @label="Ignored block item" />
        </EuiListGroup>
      </template>
    );

    assert.dom('.euiListGroupItem').exists({ count: 3 });
    assert.dom('a.euiListGroupItem').hasAttribute('href', '/somewhere');
    assert.dom('button.euiListGroupItem').hasAttribute('aria-current', 'true');
    assert.dom('ul').doesNotIncludeText('Ignored block item');
    assert.dom('.euiListGroupItem__label').hasStyle({ whiteSpace: 'normal' });

    await click('button.euiListGroupItem');
    assert.deepEqual(clicked, ['action']);
  });

  test('an empty @listItems falls back to the block', async function (assert) {
    const items: Array<{ label: string }> = [];
    await render(
      <template>
        <EuiListGroup @listItems={{items}}><EuiListGroupItem @label="From block" /></EuiListGroup>
      </template>
    );
    assert.dom('.euiListGroupItem').exists({ count: 1 }).hasText('From block');
  });

  test('@showToolTips shows each item label as a tooltip to the right; an item can opt out', async function (assert) {
    const items = [
      { label: 'First', href: '/a' },
      { label: 'Second', showToolTip: false },
      { label: 'Third', toolTipText: 'Custom text' }
    ];
    await render(<template><EuiListGroup @listItems={{items}} @showToolTips={{true}} /></template>);

    assert.dom('.euiListGroupItem__tooltip').exists({ count: 2 });
    assert.dom('.euiListGroupItem__label').exists({ count: 3 });
    // upstream: no native title when a tooltip shows the label
    assert.dom('.euiListGroupItem__label[title]').exists({ count: 1 }, 'only the opted-out item');

    await triggerEvent('li:nth-child(3) .euiListGroupItem__tooltip', 'mouseover');
    await waitUntil(() => document.querySelector('.euiToolTip'));
    assert.dom('.euiToolTip', document.body).hasText('Custom text');
  });

  test('block items also inherit @showToolTips', async function (assert) {
    await render(
      <template>
        <EuiListGroup @showToolTips={{true}}>
          <EuiListGroupItem @label="A" />
          <EuiListGroupItem @label="B" @showToolTip={{false}} />
        </EuiListGroup>
      </template>
    );
    assert.dom('.euiListGroupItem__tooltip').exists({ count: 1 });
  });
});
