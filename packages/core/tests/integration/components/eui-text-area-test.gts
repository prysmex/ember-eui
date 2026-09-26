import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import { fillIn, render } from '@ember/test-helpers';

import EuiTextArea from '#src/components/eui-text-area.gts';

module('Integration | Component | eui-text-area', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders the value and reports input', async function (assert) {
    const values: string[] = [];
    const onInput = (e: Event) => values.push((e.target as HTMLTextAreaElement).value);

    await render(<template><EuiTextArea @value="Hello" {{on "input" onInput}} /></template>);

    assert.dom('textarea.euiTextArea').hasValue('Hello').hasAttribute('rows', '6').hasClass('euiTextArea--resizeVertical');

    await fillIn('textarea', 'World');
    assert.deepEqual(values, ['World']);
  });

  test('rows, resize, compressed, full width, disabled, read only and invalid', async function (assert) {
    await render(
      <template>
        <EuiTextArea @compressed={{true}} @resize="none" @fullWidth={{true}} @readOnly={{true}} @isInvalid={{true}} class="a" />
        <EuiTextArea @rows={{2}} @disabled={{true}} class="b" />
      </template>
    );

    assert.dom('textarea.a').hasAttribute('rows', '3').hasClass('euiTextArea--resizeNone').hasClass('euiTextArea--compressed').hasClass('euiTextArea--fullWidth').hasAttribute('readonly');
    assert.false((document.querySelector('textarea.a') as HTMLTextAreaElement).validity.valid);
    assert.dom('textarea.b').hasAttribute('rows', '2').isDisabled();
  });
});
