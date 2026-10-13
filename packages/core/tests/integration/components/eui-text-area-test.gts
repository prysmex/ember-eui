import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import { click, fillIn, render } from '@ember/test-helpers';

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
  test('it sits in a form control layout like upstream', async function (assert) {
    await render(<template><EuiTextArea @fullWidth={{true}} /></template>);

    assert
      .dom('.euiFormControlLayout.euiFormControlLayout--euiTextArea .euiFormControlLayout__childrenWrapper > textarea.euiTextArea')
      .exists();
    assert.dom('.euiFormControlLayout').hasStyle({ height: `${document.querySelector('textarea')!.offsetHeight}px` });
  });

  test('icon, isLoading and invalid use the layout icons', async function (assert) {
    await render(
      <template><EuiTextArea @icon="search" @isLoading={{true}} @isInvalid={{true}} /></template>
    );

    assert.dom('.euiFormControlLayoutIcons').exists({ count: 2 });
    assert.dom('.euiFormControlLayoutIcons .euiBorealisLoadingSpinner').exists();
    assert.dom('.euiFormControlLayoutIcons [data-icon-type="warning"]').exists();
    // upstream anchors the icons to the bottom of a textarea
    const icons = document.querySelector('.euiFormControlLayoutIcons:has([data-icon-type="warning"])') as HTMLElement;
    const area = document.querySelector('textarea')!.getBoundingClientRect();
    const box = icons.getBoundingClientRect();
    assert.true(box.top > area.top + area.height / 2, 'the icons sit at the bottom, not centered');
    assert.true(box.bottom <= area.bottom, 'inside the textarea');
  });

  test('isClearable empties the textarea, fires input and focuses it', async function (assert) {
    const values: string[] = [];
    const onInput = (e: Event) => values.push((e.target as HTMLTextAreaElement).value);

    await render(
      <template><EuiTextArea @isClearable={{true}} @value="Hello" {{on "input" onInput}} /></template>
    );

    assert.dom('[data-test-subj="clearTextAreaButton"]').exists();
    await click('[data-test-subj="clearTextAreaButton"]');

    assert.dom('textarea').hasValue('').isFocused();
    assert.deepEqual(values, ['']);
  });

  test('no clear button without isClearable; none while disabled works', async function (assert) {
    await render(
      <template>
        <EuiTextArea class="a" @value="x" />
        <EuiTextArea class="b" @isClearable={{true}} @disabled={{true}} @value="x" />
      </template>
    );

    assert.dom('.a').exists();
    assert.dom('[data-test-subj="clearTextAreaButton"]').exists({ count: 1 });
    assert.dom('[data-test-subj="clearTextAreaButton"]').isDisabled();
  });
});
