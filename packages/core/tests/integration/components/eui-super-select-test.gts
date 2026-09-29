import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, rerender, triggerKeyEvent, waitUntil } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiSuperSelect from '#src/components/eui-super-select.gts';

import type { EuiSuperSelectOption } from '#src/components/eui-super-select.gts';

const OPTIONS: EuiSuperSelectOption[] = [
  { value: 'warning', inputDisplay: 'Warning', dropdownDisplay: 'Warning: something may be wrong' },
  { value: 'minor', inputDisplay: 'Minor' },
  { value: 'critical', inputDisplay: 'Critical', disabled: true },
];

const option = (value: string) => document.querySelector(`.euiSuperSelect__item[id$="${OPTIONS.findIndex((o) => o.value === value)}"]`);

module('Integration | Component | eui-super-select', function (hooks) {
  setupRenderingTest(hooks);

  test('it shows the selected option and picks another', async function (assert) {
    class State {
      @tracked value = 'minor';
    }
    const state = new State();
    const onChange = (value: string) => (state.value = value);

    await render(
      <template><EuiSuperSelect @options={{OPTIONS}} @valueOfSelected={{state.value}} @onChange={{onChange}} @name="severity" /></template>
    );

    assert.dom('button.euiSuperSelectControl').hasText('Minor').hasAttribute('aria-haspopup', 'listbox');
    assert.dom('input[type="hidden"][name="severity"]').hasValue('minor');

    await click('button.euiSuperSelectControl');
    await waitUntil(() => document.querySelector('.euiSuperSelect__listbox'));

    assert.dom('.euiSuperSelect__item', document.body).exists({ count: 3 });
    assert.dom(option('warning')).hasText('Warning: something may be wrong', 'dropdownDisplay in the list');
    assert.dom(option('minor')).hasAria('selected', 'true');
    assert.dom(option('minor')!.querySelector('.euiIcon')).exists('a check mark on the selected option');
    assert.dom(option('critical')).isDisabled();
    assert.dom(option('minor')).isFocused('the selected option is focused');

    await click(option('warning')!);
    await rerender();

    assert.strictEqual(state.value, 'warning');
    assert.dom('button.euiSuperSelectControl').hasText('Warning');
    assert.dom('.euiSuperSelect__listbox', document.body).doesNotExist('the list closed');
  });

  test('keyboard: arrows open the list and move between options, Escape closes', async function (assert) {
    await render(<template><EuiSuperSelect @options={{OPTIONS}} /></template>);

    await triggerKeyEvent('button.euiSuperSelectControl', 'keydown', 'ArrowDown');
    await waitUntil(() => document.querySelector('.euiSuperSelect__listbox'));
    assert.dom(option('warning')).isFocused('the first enabled option without a selection');

    await triggerKeyEvent(option('warning')!, 'keydown', 'ArrowDown');
    assert.dom(option('minor')).isFocused();

    await triggerKeyEvent(option('minor')!, 'keydown', 'Escape');
    assert.dom('.euiSuperSelect__listbox', document.body).doesNotExist();
  });

  test('blocks render the options', async function (assert) {
    await render(
      <template>
        <EuiSuperSelect @options={{OPTIONS}} @valueOfSelected="warning" @hasDividers={{true}} @fullWidth={{true}}>
          <:inputDisplay as |opt|><strong class="selected">{{opt.inputDisplay}}!</strong></:inputDisplay>
          <:dropdownDisplay as |opt|><em class="item">{{opt.value}}</em></:dropdownDisplay>
        </EuiSuperSelect>
      </template>
    );

    assert.dom('.selected').hasText('Warning!');
    assert.dom('.euiSuperSelectControl').hasClass('euiSuperSelectControl--fullWidth');

    await click('button.euiSuperSelectControl');
    await waitUntil(() => document.querySelector('.euiSuperSelect__listbox'));
    assert.dom('.euiSuperSelect__item em.item', document.body).exists({ count: 3 });
    assert.dom('.euiSuperSelect__item', document.body).hasClass('euiSuperSelect__item--hasDividers');
  });
});
