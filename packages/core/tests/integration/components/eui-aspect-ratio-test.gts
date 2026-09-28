import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiAspectRatio from '#src/components/eui-aspect-ratio.gts';

module('Integration | Component | eui-aspect-ratio', function (hooks) {
  setupRenderingTest(hooks);

  test('it keeps the ratio with a bottom padding', async function (assert) {
    await render(
      <template><EuiAspectRatio @width={{16}} @height={{9}}><iframe title="Video"></iframe></EuiAspectRatio></template>
    );

    assert.dom('.euiAspectRatio').hasAttribute('style', 'padding-bottom: 56.25%');
    assert.dom('.euiAspectRatio iframe').exists();
  });

  test('@maxWidth limits the width', async function (assert) {
    await render(<template><EuiAspectRatio @width={{1}} @height={{1}} @maxWidth={{300}}>x</EuiAspectRatio></template>);

    assert.dom('.euiAspectRatio').hasStyle({ maxWidth: '300px' });
    assert.dom('.euiAspectRatio').hasAttribute('style', 'padding-bottom: 100%; max-width: 300px');
  });
});
