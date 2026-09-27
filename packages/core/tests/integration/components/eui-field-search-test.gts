import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, fillIn, render, triggerKeyEvent } from '@ember/test-helpers';

import EuiFieldSearch from '#src/components/eui-field-search.gts';

module('Integration | Component | eui-field-search', function (hooks) {
  setupRenderingTest(hooks);

  test('Enter / change calls @onSearch with the value', async function (assert) {
    const searches: string[] = [];
    const onSearch = (value: string) => searches.push(value);

    await render(<template><EuiFieldSearch @placeholder="Search" @onSearch={{onSearch}} /></template>);

    assert.dom('input.euiFieldSearch').hasAttribute('placeholder', 'Search');
    assert.dom('.euiFormControlLayout svg.euiIcon').exists('search icon');

    await fillIn('input', 'cats');
    assert.deepEqual(searches, ['cats'], 'change searches');
  });

  test('@incremental searches on every key up', async function (assert) {
    const searches: string[] = [];
    const onSearch = (value: string) => searches.push(value);

    await render(<template><EuiFieldSearch @incremental={{true}} @onSearch={{onSearch}} /></template>);

    const input = (this.element as HTMLElement).querySelector('input')!;

    input.value = 'd';
    await triggerKeyEvent(input, 'keyup', 'D');
    input.value = 'do';
    await triggerKeyEvent(input, 'keyup', 'O');

    assert.deepEqual(searches, ['d', 'do']);
  });

  test('the clear button empties the value and searches ""', async function (assert) {
    const searches: string[] = [];
    const onSearch = (value: string) => searches.push(value);

    await render(<template><EuiFieldSearch @value="dogs" @isClearable={{true}} @onSearch={{onSearch}} /></template>);

    assert.dom('input').hasValue('dogs').hasClass('euiFieldSearch--isClearable');

    await click('.euiFormControlLayoutClearButton');

    assert.dom('input').hasValue('');
    assert.deepEqual(searches, ['']);
  });

  test('the clear button shows by default (isClearable defaults to true)', async function (assert) {
    const noop = () => {};

    await render(<template><EuiFieldSearch @value="dogs" @onSearch={{noop}} /></template>);

    assert.dom('.euiFormControlLayoutClearButton').exists();
  });

  test('@isClearable={{false}} and disabled hide the clear button', async function (assert) {
    const noop = () => {};

    await render(
      <template>
        <EuiFieldSearch @value="a" @isClearable={{false}} @onSearch={{noop}} class="not-clearable" />
        <EuiFieldSearch @value="b" @isClearable={{true}} @disabled={{true}} @onSearch={{noop}} class="disabled" />
      </template>
    );

    assert.dom('input.not-clearable').doesNotHaveClass('euiFieldSearch--isClearable');
    assert.dom('.euiFormControlLayoutClearButton').doesNotExist();
    assert.dom('input.disabled').isDisabled();
  });

  test('without @value, the clear button appears once there is text', async function (assert) {
    const noop = () => {};

    await render(<template><EuiFieldSearch @onSearch={{noop}} /></template>);

    assert.dom('.euiFormControlLayoutClearButton').doesNotExist();
    await fillIn('input', 'cats');
    assert.dom('.euiFormControlLayoutClearButton').exists();
  });

  test('@readOnly makes the input read-only and hides the clear button', async function (assert) {
    const noop = () => {};

    await render(<template><EuiFieldSearch @value="x" @readOnly={{true}} @onSearch={{noop}} /></template>);

    assert.dom('input').hasAttribute('readonly');
    assert.dom('.euiFormControlLayoutClearButton').doesNotExist();
  });
});
