import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiBadge from '#src/components/eui-badge.gts';
import EuiBadgeGroup from '#src/components/eui-badge-group.gts';

module('Integration | Component | eui-badge-group', function (hooks) {
  setupRenderingTest(hooks);

  test('it wraps badges in group items', async function (assert) {
    await render(
      <template>
        <EuiBadgeGroup @gutterSize="s" as |group|>
          <group.item><EuiBadge>One</EuiBadge></group.item>
          <group.item><EuiBadge>Two</EuiBadge></group.item>
        </EuiBadgeGroup>
      </template>
    );

    assert.dom('.euiBadgeGroup').hasClass('euiBadgeGroup--gutterSmall');
    assert.dom('.euiBadgeGroup__item .euiBadge').exists({ count: 2 });
  });
});
