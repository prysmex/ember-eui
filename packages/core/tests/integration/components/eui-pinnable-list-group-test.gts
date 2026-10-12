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
    assert.dom('.euiPinnableListGroup__item').exists({ count: 3 });
    assert.dom('.euiPinnableListGroup__itemExtraAction').exists({ count: 2 }, 'not on unpinnable items');
    // The pin is a sibling of the item link inside the upstream wrapper
    // `<li>`; pinned pins are always shown (opacity 1) instead of the legacy
    // `-pinned`/`-alwaysShow` modifier classes.
    assert
      .dom('li:nth-child(1) .euiPinnableListGroup__itemExtraAction')
      .hasStyle({ opacity: '1' })
      .hasAria('label', 'Unpin item');
    assert.dom('li:nth-child(2) .euiPinnableListGroup__itemExtraAction').hasStyle({ opacity: '0' }).hasAria('label', 'Pin item');

    await click('li:nth-child(2) .euiPinnableListGroup__itemExtraAction');
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
