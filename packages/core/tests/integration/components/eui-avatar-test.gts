import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiAvatar from '#src/components/eui-avatar.gts';

module('Integration | Component | eui-avatar', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders initials from @name with an accessible label', async function (assert) {
    await render(<template><EuiAvatar @name="Jane Doe" /></template>);

    // legacy euiAvatar--m / --user classes are upstream emotion styles now
    assert.dom('.euiAvatar').hasStyle({ width: '32px', borderRadius: '50%' });
    assert.dom('.euiAvatar').hasAttribute('role', 'img').hasAttribute('aria-label', 'Jane Doe').hasAttribute('title', 'Jane Doe');
    assert.dom('.euiAvatar span').hasText('JD', 'one initial per word, up to 2');
  });

  test('@initialLength, @initials, @size and @type', async function (assert) {
    await render(
      <template>
        <EuiAvatar @name="Jane Doe" @initialLength={{1}} @size="xl" @type="space" class="one" />
        <EuiAvatar @name="Jane Doe" @initials="ZZ" @initialLength={{2}} class="custom" />
      </template>
    );

    assert.dom('.one').hasStyle({ width: '64px', borderRadius: '8px' });
    assert.dom('.one span').hasText('J');
    assert.dom('.custom span').hasText('ZZ');
  });

  test('@iconType renders an icon instead of initials', async function (assert) {
    await render(<template><EuiAvatar @name="Bot" @iconType="bell" /></template>);

    assert.dom('.euiAvatar svg.euiAvatar__icon').exists();
    assert.dom('.euiAvatar span[aria-hidden]').doesNotExist();
  });

  test('@isDisabled is presentational', async function (assert) {
    await render(<template><EuiAvatar @name="Jane" @isDisabled={{true}} /></template>);

    assert.dom('.euiAvatar').hasStyle({ cursor: 'not-allowed' }).hasAttribute('role', 'presentation').doesNotHaveAttribute('aria-label');
  });
});
