import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

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
});
