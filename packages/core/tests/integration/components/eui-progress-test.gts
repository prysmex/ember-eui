import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiProgress from '#src/components/eui-progress.gts';

module('Integration | Component | eui-progress', function (hooks) {
  setupRenderingTest(hooks);

  test('without @max it is an indeterminate bar', async function (assert) {
    await render(<template><EuiProgress @size="xs" @color="primary" /></template>);

    assert.dom('progress').doesNotExist();
    // Legacy modifier classes are replaced by computed styles (see eui-utilities-test).
    assert.dom('div.euiProgress').exists();
    assert.strictEqual(getComputedStyle(document.querySelector('.euiProgress')!).height, '2px');
  });

  test('with @max it renders a native progress element', async function (assert) {
    await render(<template><EuiProgress @max={{100}} @value={{40}} @color="danger" /></template>);

    assert.dom('progress.euiProgress').hasAttribute('max', '100').hasAttribute('value', '40');
  });

  test('label and @valueText', async function (assert) {
    await render(
      <template>
        <EuiProgress @max={{100}} @value={{70}} @valueText={{true}}>
          <:label>Upload</:label>
        </EuiProgress>
      </template>
    );

    assert.dom('.euiProgress__label').hasText('Upload');
    // Upstream renders `@valueText={{true}}` as a percentage.
    assert.dom('.euiProgress__valueText').hasText('70%');
  });
});
