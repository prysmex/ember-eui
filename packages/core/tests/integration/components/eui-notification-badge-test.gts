import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiNotificationBadge from '#src/components/eui-notification-badge.gts';

module('Integration | Component | eui-notification-badge', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders the count with size and color', async function (assert) {
    await render(
      <template>
        <EuiNotificationBadge class="default">3</EuiNotificationBadge>
        <EuiNotificationBadge @size="m" @color="subdued" class="custom">5</EuiNotificationBadge>
      </template>
    );

    assert.dom('.default').hasClass('euiNotificationBadge').hasText('3');
    assert.dom('.custom').hasClass('euiNotificationBadge--medium').hasClass('euiNotificationBadge--subdued');
  });
});
