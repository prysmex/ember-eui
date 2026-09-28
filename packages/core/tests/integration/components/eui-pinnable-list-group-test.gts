import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';

import EuiPinnableListGroup from '#src/components/eui-pinnable-list-group.gts';

import type { EuiPinnableListGroupItem } from '#src/components/eui-pinnable-list-group.gts';

module('Integration | Component | eui-pinnable-list-group', function (hooks) {
  setupRenderingTest(hooks);

  test('items get a pin button, filled when pinned', async function (assert) {
    const pinned: string[] = [];
    const onPinClick = (item: EuiPinnableListGroupItem) => pinned.push(item.label);
    const items: EuiPinnableListGroupItem[] = [
      { label: 'Discover', href: '#discover', pinned: true },
      { label: 'Dashboards', href: '#dashboards' },
      { label: 'Settings', href: '#settings', pinnable: false },
    ];

    await render(<template><EuiPinnableListGroup @listItems={{items}} @onPinClick={{onPinClick}} /></template>);

    assert.dom('ul.euiPinnableListGroup').exists();
    assert.dom('.euiListGroupItem').exists({ count: 3 });
    assert.dom('.euiPinnableListGroup__itemExtraAction').exists({ count: 2 }, 'not on unpinnable items');
    assert
      .dom('.euiListGroupItem:nth-child(1) .euiPinnableListGroup__itemExtraAction')
      .hasClass('euiPinnableListGroup__itemExtraAction-pinned')
      .hasClass('euiListGroupItem__extraAction-alwaysShow')
      .hasAria('label', 'Unpin item');
    assert.dom('.euiListGroupItem:nth-child(2) .euiPinnableListGroup__itemExtraAction').hasAria('label', 'Pin item');

    await click('.euiListGroupItem:nth-child(2) .euiPinnableListGroup__itemExtraAction');
    assert.deepEqual(pinned, ['Dashboards']);
  });

  test('custom pin titles', async function (assert) {
    const items: EuiPinnableListGroupItem[] = [{ label: 'Logs' }];
    const pinTitle = (item: EuiPinnableListGroupItem) => `Pin ${item.label} to the top`;
    const noop = () => {};

    await render(
      <template><EuiPinnableListGroup @listItems={{items}} @onPinClick={{noop}} @pinTitle={{pinTitle}} /></template>
    );

    assert.dom('.euiPinnableListGroup__itemExtraAction').hasAria('label', 'Pin Logs to the top');
  });
});
