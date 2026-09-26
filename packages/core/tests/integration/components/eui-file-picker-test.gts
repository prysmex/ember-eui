import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, triggerEvent } from '@ember/test-helpers';

import EuiFilePicker from '#src/components/eui-file-picker.gts';

module('Integration | Component | eui-file-picker', function (hooks) {
  setupRenderingTest(hooks);

  test('it shows the initial prompt and reports selected files', async function (assert) {
    const received: (FileList | null)[] = [];
    const onChange = (files: FileList | null) => received.push(files);

    await render(
      <template><EuiFilePicker @initialPromptText="Pick files" @multiple={{true}} @onChange={{onChange}} /></template>
    );

    assert.dom('input[type="file"].euiFilePicker__input').hasAttribute('multiple');
    assert.dom('.euiFilePicker__promptText').hasText('Pick files');

    const files = [new File(['a'], 'a.txt'), new File(['b'], 'b.txt')];

    await triggerEvent('input[type="file"]', 'change', { files });

    assert.strictEqual(received.length, 1);
    assert.strictEqual(received[0]!.length, 2);
    assert.dom('.euiFilePicker__promptText').hasText('2 files selected');
    assert.dom('.euiFilePicker').hasClass('euiFilePicker--hasFiles');
  });

  test('the clear button removes the selection', async function (assert) {
    const received: (FileList | null)[] = [];
    const onChange = (files: FileList | null) => received.push(files);

    await render(
      <template><EuiFilePicker @initialPromptText="Pick files" @multiple={{true}} @onChange={{onChange}} /></template>
    );

    await triggerEvent('input[type="file"]', 'change', { files: [new File(['a'], 'a.txt'), new File(['b'], 'b.txt')] });
    await click('.euiFilePicker__clearButton');

    assert.dom('.euiFilePicker__promptText').hasText('Pick files');
    assert.dom('.euiFilePicker').doesNotHaveClass('euiFilePicker--hasFiles');
  });

  test('states and display', async function (assert) {
    await render(
      <template><EuiFilePicker @compressed={{true}} @fullWidth={{true}} @isInvalid={{true}} @isLoading={{true}} @disabled={{true}} @display="large" /></template>
    );

    assert.dom('.euiFilePicker').hasClass('euiFilePicker--compressed').hasClass('euiFilePicker--fullWidth').hasClass('euiFilePicker--isInvalid').hasClass('euiFilePicker--isLoading').hasClass('euiFilePicker--large');
    assert.dom('input[type="file"]').isDisabled();
  });
});
