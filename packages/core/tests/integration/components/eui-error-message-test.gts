import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, waitFor } from '@ember/test-helpers';

import EuiErrorMessage, {
  euiErrorMessageText
} from '#src/components/eui-error-message.gts';
import type EuiI18n from '#src/services/eui-i18n.ts';

module('Integration | Component | eui-error-message', function (hooks) {
  setupRenderingTest(hooks);

  test('upstream EuiErrorBoundary fallback: striped panel, "Error" title, text in a code block', async function (assert) {
    await render(
      <template>
        <EuiErrorMessage @errorMessage="Error: boom\n  at Widget" class="mine" />
      </template>
    );

    assert.dom('.euiErrorBoundary').hasClass('mine').hasAttribute('data-test-subj', 'euiErrorBoundary');
    assert.dom('.euiErrorBoundary .euiCodeBlock').exists();
    await waitFor('.euiErrorBoundary .euiCodeBlock code .euiTitle');
    assert.dom('.euiErrorBoundary .euiCodeBlock code .euiTitle').hasText('Error', 'the title is inside the code block (upstream)');
    assert.dom('.euiErrorBoundary .euiCodeBlock code').includesText('Error: boom');
    assert.dom('.euiErrorBoundary .euiCodeBlock .token').doesNotExist('rich content is not highlighted');
    assert.notStrictEqual(
      getComputedStyle(this.element.querySelector('.euiErrorBoundary')!).backgroundImage,
      'none',
      'danger stripes'
    );
  });

  test('@error formats an Error like upstream (message, then the stack without its first line)', async function (assert) {
    const error = new Error('Could not load');
    error.stack = 'Error: Could not load\n    at loadModel (app.js:1:1)';

    assert.strictEqual(euiErrorMessageText(error), 'Error: Could not load\n    at loadModel (app.js:1:1)');
    assert.strictEqual(euiErrorMessageText('plain'), 'plain', 'non-errors are stringified');

    await render(<template><EuiErrorMessage @error={{error}} /></template>);
    await waitFor('.euiErrorBoundary code .euiTitle');

    assert.dom('.euiErrorBoundary .euiCodeBlock').includesText('Error: Could not load').includesText('at loadModel');
  });

  test('the title is translatable (euiErrorBoundary.error) and @css composes last', async function (assert) {
    const i18n = this.owner.lookup('service:eui-i18n') as EuiI18n;
    i18n.addTranslations({ euiErrorBoundary: { error: 'Fehler' } });
    const css = { paddingBlock: '3px' };

    await render(<template><EuiErrorMessage @errorMessage="x" @css={{css}} /></template>);
    await waitFor('.euiErrorBoundary code .euiTitle');

    assert.dom('.euiErrorBoundary .euiTitle').hasText('Fehler');
    assert.strictEqual(getComputedStyle(this.element.querySelector('.euiErrorBoundary')!).paddingTop, '3px');
  });
});
