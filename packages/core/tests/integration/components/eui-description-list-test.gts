import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiDescriptionList from '#src/components/eui-description-list.gts';
import EuiDescriptionListDescription from '#src/components/eui-description-list-description.gts';
import EuiDescriptionListTitle from '#src/components/eui-description-list-title.gts';

const ITEMS = [
  { title: 'Name', description: 'Jane' },
  { title: 'Role', description: 'Admin' }
];

module('Integration | Component | eui-description-list', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders @listItems as dt/dd pairs', async function (assert) {
    await render(<template><EuiDescriptionList @listItems={{ITEMS}} /></template>);

    // Upstream exposes the type as `data-type`, not a modifier class.
    assert.dom('dl.euiDescriptionList').hasAttribute('data-type', 'row');
    assert.dom('dt.euiDescriptionList__title').exists({ count: 2 });
    assert.dom('dt.euiDescriptionList__title').hasText('Name');
    assert.dom('dd.euiDescriptionList__description').hasText('Jane');
  });

  test('type, alignment, text style and compressed', async function (assert) {
    await render(
      <template>
        <EuiDescriptionList @type="column" @align="center" @textStyle="reverse" @compressed={{true}}>
          <EuiDescriptionListTitle>Key</EuiDescriptionListTitle>
          <EuiDescriptionListDescription>Value</EuiDescriptionListDescription>
        </EuiDescriptionList>
      </template>
    );

    // Legacy modifier classes are gone; column layout and center alignment
    // are computed styles (reverse/compressed fonts: eui-lists-test).
    assert.dom('dl').hasAttribute('data-type', 'column').hasStyle({ display: 'grid', textAlign: 'center' });
    assert.dom('dt').hasStyle({ textAlign: 'end' });
    assert.dom('dt').hasText('Key');
    assert.dom('dd').hasText('Value');
  });
});
