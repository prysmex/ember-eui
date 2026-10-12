import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';

import EuiToast from '#src/components/eui-toast.gts';

module('Integration | Component | eui-toast', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders title, icon, color and body', async function (assert) {
    await render(
      <template><EuiToast @title="Saved" @color="success" @iconType="check" @body="All good" /></template>
    );

    assert.dom('.euiToast').hasClass('euiToast--success');
    assert.dom('.euiToastHeader__title').hasText('Saved');
    // upstream has no header wrapper/modifier: the body follows the title
    assert.dom('[data-test-subj="euiToastBody"] .euiToast__text').hasText('All good');
    assert.dom('svg[data-icon-type="check"]').hasAttribute('aria-hidden', 'true');
    assert.dom('.euiToast').containsText('All good');
  });

  test('@onClose renders a dismiss button', async function (assert) {
    let closed = 0;
    const onClose = () => closed++;

    await render(<template><EuiToast @title="Bye" @onClose={{onClose}} /></template>);

    await click('[data-test-subj="toastCloseButton"]');
    assert.strictEqual(closed, 1);
  });
});
