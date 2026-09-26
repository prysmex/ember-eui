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

    assert.dom('dl.euiDescriptionList').hasClass('euiDescriptionList--row');
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

    assert.dom('dl').hasClass('euiDescriptionList--column').hasClass('euiDescriptionList--center').hasClass('euiDescriptionList--reverse').hasClass('euiDescriptionList--compressed');
    assert.dom('dt').hasText('Key');
    assert.dom('dd').hasText('Value');
  });
});
