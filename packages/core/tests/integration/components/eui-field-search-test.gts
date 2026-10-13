import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, fillIn, render, rerender, triggerKeyEvent } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

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

    assert.dom('input').hasValue('dogs');
    assert.dom('.euiFormControlLayoutClearButton').exists('clearable');

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

  // Regression: a controlled value that became '' removed the clear button in
  // the middle of a render and threw "must pass a function to on".
  test('a controlled @value changing follows the value, also to "" (clear button)', async function (assert) {
    const state = new (class {
      @tracked value = 'dogs';
    })();
    const noop = () => {};

    await render(
      <template><EuiFieldSearch @value={{state.value}} @onSearch={{noop}} /></template>
    );

    assert.dom('input').hasValue('dogs');
    assert.dom('.euiFormControlLayoutClearButton').exists();

    state.value = 'cats';
    await rerender();
    assert.dom('input').hasValue('cats');
    assert.dom('.euiFormControlLayoutClearButton').exists();

    state.value = '';
    await rerender();
    assert.dom('input').hasValue('');
    assert.dom('.euiFormControlLayoutClearButton').doesNotExist();

    state.value = 'birds';
    await rerender();
    assert.dom('input').hasValue('birds');
    assert.dom('.euiFormControlLayoutClearButton').exists();
  });

  test('a controlled round trip (typing updates @value) then the value changing to ""', async function (assert) {
    const state = new (class {
      @tracked value = '';
      onSearch = (value: string) => (this.value = value);
    })();

    await render(
      <template>
        <EuiFieldSearch @value={{state.value}} @incremental={{true}} @onSearch={{state.onSearch}} />
      </template>
    );

    await fillIn('input', 'typed');
    assert.strictEqual(state.value, 'typed');
    assert.dom('.euiFormControlLayoutClearButton').exists();

    state.value = '';
    await rerender();
    assert.dom('input').hasValue('');
    assert.dom('.euiFormControlLayoutClearButton').doesNotExist();

    await fillIn('input', 'again');
    assert.dom('.euiFormControlLayoutClearButton').exists();
    await click('.euiFormControlLayoutClearButton');
    assert.dom('input').hasValue('');
    assert.strictEqual(state.value, '', 'clearing reports ""');
  });

  test('a controlled @value through several changes, ending in ""', async function (assert) {
    const state = new (class {
      @tracked value = 'pan';
    })();
    const noop = () => {};

    await render(
      <template>
        <EuiFieldSearch @value={{state.value}} @incremental={{true}} @fullWidth={{true}} @compressed={{true}} @onSearch={{noop}} />
      </template>
    );

    for (const next of ['Mi', 'not in the list', '', 'x', '']) {
      state.value = next;
      await rerender();
      assert.dom('input').hasValue(next);
      assert.dom('.euiFormControlLayoutClearButton').exists({ count: next ? 1 : 0 });
    }
  });

  // Regression: the parent resets the controlled value in the same tick the
  // user types. EuiFieldSearch used to set its text from a modifier while the
  // clear button's `{{on}}` was updating with the cleared `@clear`.
  test('a controlled @value reset to "" while typing (clear button)', async function (assert) {
    const state = new (class {
      @tracked value = 'a';
      searches: string[] = [];
      onSearch = (value: string) => {
        this.searches.push(value);
        this.value = '';
      };
    })();

    await render(
      <template>
        <EuiFieldSearch @value={{state.value}} @incremental={{true}} @onSearch={{state.onSearch}} />
      </template>
    );

    assert.dom('.euiFormControlLayoutClearButton').exists();

    await fillIn('input', 'b');

    assert.deepEqual(state.searches, ['b']);
    assert.dom('input').hasValue('', 'the parent reset the value');
    assert.dom('.euiFormControlLayoutClearButton').doesNotExist();

    state.value = 'c';
    await rerender();
    assert.dom('input').hasValue('c');
    assert.dom('.euiFormControlLayoutClearButton').exists();
  });
});
