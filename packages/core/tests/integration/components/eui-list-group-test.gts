import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiListGroup from '#src/components/eui-list-group.gts';
import EuiListGroupItem from '#src/components/eui-list-group-item.gts';

module('Integration | Component | eui-list-group', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders items with gutter, border and flush options', async function (assert) {
    await render(
      <template>
        <EuiListGroup @gutterSize="m" @bordered={{true}} @flush={{true}} @maxWidth={{true}}>
          <EuiListGroupItem @label="One" />
          <EuiListGroupItem @label="Two" />
        </EuiListGroup>
      </template>
    );

    assert.dom('ul.euiListGroup').hasClass('euiListGroup--gutterMedium').hasClass('euiListGroup-bordered').hasClass('euiListGroup-flush').hasClass('euiListGroup-maxWidthDefault');
    assert.dom('ul.euiListGroup .euiListGroupItem').exists({ count: 2 });
  });

  test('a custom @maxWidth becomes an inline style', async function (assert) {
    await render(<template><EuiListGroup @maxWidth="200px"><EuiListGroupItem @label="One" /></EuiListGroup></template>);

    assert.dom('ul.euiListGroup').hasStyle({ maxWidth: '200px' });
  });
});
