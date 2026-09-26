import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import { fillIn, render } from '@ember/test-helpers';

import EuiSelect from '#src/components/eui-select.gts';

const OPTIONS = [
  { value: 'a', text: 'Option A' },
  { value: 'b', text: 'Option B' },
  { value: 'c', text: 'Option C', disabled: true }
];

module('Integration | Component | eui-select', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders options, selects @value and reports changes', async function (assert) {
    const values: string[] = [];
    const onChange = (e: Event) => values.push((e.target as HTMLSelectElement).value);

    await render(<template><EuiSelect @options={{OPTIONS}} @value="b" {{on "change" onChange}} /></template>);

    assert.dom('select.euiSelect option').exists({ count: 3 });
    assert.dom('select').hasValue('b');
    assert.dom('option[value="c"]').isDisabled();
    assert.dom('.euiFormControlLayout svg.euiIcon').exists('arrow icon');

    await fillIn('select', 'a');
    assert.deepEqual(values, ['a']);
  });

  test('@hasNoInitialSelection adds an empty hidden option', async function (assert) {
    await render(<template><EuiSelect @options={{OPTIONS}} @hasNoInitialSelection={{true}} /></template>);

    assert.dom('select option').exists({ count: 4 });
    assert.dom('select').hasValue('');
  });

  test('full width, compressed, loading, disabled and invalid', async function (assert) {
    await render(
      <template><EuiSelect @options={{OPTIONS}} @fullWidth={{true}} @compressed={{true}} @isLoading={{true}} @disabled={{true}} @isInvalid={{true}} /></template>
    );

    assert.dom('select').hasClass('euiSelect--fullWidth').hasClass('euiSelect--compressed').hasClass('euiSelect--isLoading').isDisabled();
    assert.false((document.querySelector('select') as HTMLSelectElement).validity.valid, 'invalid');
  });

  test('prepend and append blocks put the select in a group', async function (assert) {
    await render(
      <template>
        <EuiSelect @options={{OPTIONS}}>
          <:prepend as |classes|><span class="pre {{classes}}">Pre</span></:prepend>
          <:append as |classes|><span class="post {{classes}}">Post</span></:append>
        </EuiSelect>
      </template>
    );

    assert.dom('select').hasClass('euiSelect--inGroup');
    assert.dom('.pre').hasText('Pre');
    assert.dom('.post').hasText('Post');
  });
});
