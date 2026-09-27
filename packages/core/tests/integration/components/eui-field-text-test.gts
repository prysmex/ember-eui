import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import { click, fillIn, render } from '@ember/test-helpers';

import EuiFieldNumber from '#src/components/eui-field-number.gts';
import EuiFieldPassword from '#src/components/eui-field-password.gts';
import EuiFieldText from '#src/components/eui-field-text.gts';

module('Integration | Component | eui-field-text / number / password', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiFieldText: value, placeholder and input', async function (assert) {
    const values: string[] = [];
    const onInput = (e: Event) => values.push((e.target as HTMLInputElement).value);

    await render(<template><EuiFieldText @value="Hi" @placeholder="Name" {{on "input" onInput}} /></template>);

    assert.dom('input.euiFieldText[type="text"]').hasValue('Hi').hasAttribute('placeholder', 'Name');
    assert.dom('.euiFormControlLayout input.euiFieldText').exists();

    await fillIn('input', 'Hello');
    assert.deepEqual(values, ['Hello']);
  });

  test('EuiFieldText: icon, states, invalid and controlOnly', async function (assert) {
    await render(
      <template>
        <EuiFieldText @icon="user" @fullWidth={{true}} @compressed={{true}} @isLoading={{true}} @readOnly={{true}} @isInvalid={{true}} class="a" />
        <EuiFieldText @disabled={{true}} @controlOnly={{true}} class="b" />
      </template>
    );

    assert.dom('input.a').hasClass('euiFieldText--withIcon').hasClass('euiFieldText--fullWidth').hasClass('euiFieldText--compressed').hasClass('euiFieldText--isLoading').hasAttribute('readonly');
    assert.false((document.querySelector('input.a') as HTMLInputElement).validity.valid);
    assert.dom('input.b').isDisabled();
    assert.strictEqual(document.querySelector('input.b')!.parentElement!.classList.contains('euiFormControlLayout__childrenWrapper'), false, 'no layout wrapper');
  });

  test('EuiFieldText: prepend and append', async function (assert) {
    await render(
      <template>
        <EuiFieldText>
          <:prepend as |classes|><span class="pre {{classes}}">@</span></:prepend>
          <:append as |classes|><span class="post {{classes}}">.com</span></:append>
        </EuiFieldText>
      </template>
    );

    assert.dom('input').hasClass('euiFieldText--inGroup');
    assert.dom('.pre').hasText('@');
    assert.dom('.post').hasText('.com');
  });

  test('EuiFieldNumber: min, max, step and value', async function (assert) {
    await render(<template><EuiFieldNumber @value={{5}} @min={{0}} @max={{10}} @step={{1}} @icon="number" /></template>);

    assert.dom('input.euiFieldNumber[type="number"]').hasValue('5').hasAttribute('min', '0').hasAttribute('max', '10').hasAttribute('step', '1').hasClass('euiFieldNumber--withIcon');
  });

  test('EuiFieldPassword: the dual type toggles visibility', async function (assert) {
    await render(<template><EuiFieldPassword @value="secret" /></template>);

    assert.dom('input.euiFieldPassword').hasAttribute('type', 'password').hasClass('euiFieldPassword--withToggle');

    await click('.euiButtonIcon');
    assert.dom('input.euiFieldPassword').hasAttribute('type', 'text');

    await click('.euiButtonIcon');
    assert.dom('input.euiFieldPassword').hasAttribute('type', 'password');
  });

  test('EuiFieldPassword: plain password type has no toggle', async function (assert) {
    await render(<template><EuiFieldPassword @type="password" /></template>);

    assert.dom('input').hasAttribute('type', 'password');
    assert.dom('.euiButtonIcon').doesNotExist();
  });

  test('@inputRef receives the input, with or without @controlOnly', async function (assert) {
    const refs: Element[] = [];
    const inputRef = (element: Element | null) => {
      if (element) refs.push(element);
    };

    await render(
      <template>
        <EuiFieldText class="text" @inputRef={{inputRef}} />
        <EuiFieldText class="text-only" @controlOnly={{true}} @inputRef={{inputRef}} />
        <EuiFieldNumber class="number" @inputRef={{inputRef}} />
      </template>
    );

    assert.deepEqual(
      refs.map((element) => element.className.split(' ').find((c) => ['text', 'text-only', 'number'].includes(c))),
      ['text', 'text-only', 'number']
    );
    assert.true(refs.every((element) => element.tagName === 'INPUT'));
  });
});
