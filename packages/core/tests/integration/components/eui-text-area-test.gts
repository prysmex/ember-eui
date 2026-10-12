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

    assert.dom('textarea.euiTextArea').hasValue('Hello').hasAttribute('rows', '6');
    assert.strictEqual(getComputedStyle(document.querySelector('textarea')!).resize, 'vertical');

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

    assert.dom('textarea.a').hasAttribute('rows', '3').hasAttribute('readonly');
    // Legacy modifier classes are gone; check the upstream styles instead.
    const a = getComputedStyle(document.querySelector('textarea.a')!);
    assert.strictEqual(a.resize, 'none');
    assert.strictEqual(a.paddingTop, '8px', 'compressed');
    assert.strictEqual(a.maxWidth, '100%', 'full width');
    assert.false((document.querySelector('textarea.a') as HTMLTextAreaElement).validity.valid);
    assert.dom('textarea.b').hasAttribute('rows', '2').isDisabled();
  });
});
