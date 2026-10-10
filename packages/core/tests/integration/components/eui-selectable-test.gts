import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, fillIn, render, rerender, triggerKeyEvent } from '@ember/test-helpers';
import { hash } from '@ember/helper';
import { tracked } from '@glimmer/tracking';

import EuiSelectable from '#src/components/eui-selectable.gts';
import EuiSelectableListItem from '#src/components/eui-selectable-list-item.gts';
import EuiSelectableMessage from '#src/components/eui-selectable-message.gts';

import type { EuiSelectableOption } from '#src/components/eui-selectable.gts';

class State {
  @tracked options: EuiSelectableOption[] = [
    { label: 'Fruits', isGroupLabel: true },
    { label: 'Apple', checked: 'on' },
    { label: 'Banana' },
    { label: 'Cherry', disabled: true },
    { label: 'Vegetables', isGroupLabel: true },
    { label: 'Carrot', append: '12' },
  ];

  onChange = (options: EuiSelectableOption[]) => (this.options = options);

  get checked() {
    return this.options.filter((option) => option.checked).map((option) => `${option.label}:${option.checked}`);
  }
}

module('Integration | Component | eui-selectable', function (hooks) {
  setupRenderingTest(hooks);

  test('it lists the options and toggles them on click', async function (assert) {
    const state = new State();

    await render(<template><EuiSelectable @options={{state.options}} @onChange={{state.onChange}} aria-label="Food" /></template>);

    assert.dom('ul[role="listbox"]').hasAttribute('aria-multiselectable', 'true');
    assert.dom('.euiSelectableList__groupLabel').exists({ count: 2 });
    assert.dom('.euiSelectableListItem').exists({ count: 4 });
    assert.dom('.euiSelectableListItem:not([aria-disabled])[aria-selected="true"]').hasText('Apple');
    assert.dom('li[title="Carrot"] .euiSelectableListItem__append').hasText('12');

    await click('li[title="Banana"]');
    await rerender();
    assert.deepEqual(state.checked, ['Apple:on', 'Banana:on']);
    assert.dom('li[title="Banana"]').hasAttribute('aria-selected', 'true');

    await click('li[title="Apple"]');
    await rerender();
    assert.deepEqual(state.checked, ['Banana:on']);
    assert.dom('li[title="Apple"]').hasAttribute('aria-selected', 'false');

    await click('li[title="Cherry"]');
    assert.deepEqual(state.checked, ['Banana:on'], 'disabled options do nothing');
  });

  test('replacing options externally updates selected state and removes stale rows', async function (assert) {
    const state = new State();

    await render(<template><EuiSelectable @options={{state.options}} @onChange={{state.onChange}} aria-label="Food" /></template>);

    state.options = [{ label: 'Pear', checked: 'on' }, { label: 'Plum' }];
    await rerender();
    assert.dom('.euiSelectableListItem').exists({ count: 2 });
    assert.dom('li[title="Apple"]').doesNotExist();
    assert.dom('li[title="Pear"]').hasAttribute('aria-selected', 'true');

    await click('li[title="Plum"]');
    assert.dom('li[title="Plum"]').hasAttribute('aria-selected', 'true');
    assert.deepEqual(state.checked, ['Pear:on', 'Plum:on']);

    state.options = [];
    await rerender();
    assert.dom('.euiSelectableListItem').doesNotExist();
    assert.dom('.euiSelectableMessage').exists();
  });

  test('single selection and exclusions', async function (assert) {
    const single = new State();
    const exclusions = new State();

    await render(
      <template>
        <EuiSelectable class="single" @options={{single.options}} @onChange={{single.onChange}} @singleSelection="always" />
        <EuiSelectable class="exclusions" @options={{exclusions.options}} @onChange={{exclusions.onChange}} @allowExclusions={{true}} />
      </template>
    );

    await click('.single li[title="Banana"]');
    await rerender();
    assert.deepEqual(single.checked, ['Banana:on'], 'one option at most');
    await click('.single li[title="Banana"]');
    await rerender();
    assert.deepEqual(single.checked, ['Banana:on'], "'always' keeps one option");

    await click('.exclusions li[title="Apple"]');
    await rerender();
    assert.deepEqual(exclusions.checked, ['Apple:off'], 'a checked option is excluded first');
    assert.dom('.exclusions li[title="Apple"] .euiScreenReaderOnly').includesText('Excluded option.');
    await click('.exclusions li[title="Apple"]');
    await rerender();
    assert.deepEqual(exclusions.checked, [], 'then unchecked');
  });

  test('search filters the options and shows a message without matches', async function (assert) {
    const state = new State();
    const searches: string[] = [];
    const onSearch = (value: string) => searches.push(value);

    await render(
      <template>
        <EuiSelectable @options={{state.options}} @onChange={{state.onChange}} @searchable={{true}} @searchProps={{hash onSearch=onSearch}} />
      </template>
    );

    assert.dom('input.euiSelectableSearch').hasAttribute('placeholder', 'Filter options');

    await fillIn('input.euiSelectableSearch', 'an');
    assert.deepEqual(searches, ['an']);
    assert.dom('.euiSelectableListItem').exists({ count: 1 });
    assert.dom('.euiSelectableListItem mark').hasText('an');

    await fillIn('input.euiSelectableSearch', 'zzz');
    assert.dom('.euiSelectableMessage').hasText("zzz doesn't match any options");
    assert.dom('.euiSelectableMessage strong').hasText('zzz');
  });

  test('the keyboard moves the current option and Enter toggles it', async function (assert) {
    const state = new State();

    await render(<template><EuiSelectable @options={{state.options}} @onChange={{state.onChange}} @searchable={{true}} /></template>);

    await triggerKeyEvent('.euiSelectable', 'keydown', 'ArrowDown');
    assert.dom('li[title="Apple"]').hasClass('euiSelectableListItem-isFocused', 'group labels are skipped');
    assert.dom('input.euiSelectableSearch').hasAria('activedescendant', this.element.querySelector('li[title="Apple"]')!.id);

    await triggerKeyEvent('.euiSelectable', 'keydown', 'ArrowDown');
    await triggerKeyEvent('.euiSelectable', 'keydown', 'ArrowDown');
    assert.dom('li[title="Carrot"]').hasClass('euiSelectableListItem-isFocused', 'disabled options are skipped');
    assert.dom('li[title="Carrot"] .euiSelectableListItem__onFocusBadge').exists();

    await triggerKeyEvent('.euiSelectable', 'keydown', 'Enter');
    await rerender();
    assert.deepEqual(state.checked, ['Apple:on', 'Carrot:on']);
  });

  test('messages: loading and empty', async function (assert) {
    const none: EuiSelectableOption[] = [];

    await render(
      <template>
        <EuiSelectable class="loading" @options={{none}} @isLoading={{true}} />
        <EuiSelectable class="empty" @options={{none}} @emptyMessage="Nothing here" />
      </template>
    );

    assert.dom('.loading .euiSelectableMessage').includesText('Loading options');
    assert.dom('.loading .euiLoadingSpinner').exists();
    assert.dom('.empty .euiSelectableMessage').hasText('Nothing here');
  });

  test('custom layout and option blocks', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiSelectable @options={{state.options}} @onChange={{state.onChange}} @searchable={{true}} as |parts|>
          <div class="list-first"><parts.list>
            <:option as |option|><em>{{option.label}}</em></:option>
            <:optionPrepend as |option|>{{#if option.checked}}<span class="dot">•</span>{{/if}}</:optionPrepend>
          </parts.list></div>
          <div class="search-last">{{#if parts.search}}<parts.search />{{/if}}</div>
        </EuiSelectable>
      </template>
    );

    assert.dom('.list-first li[title="Banana"] em').hasText('Banana');
    assert.dom('.list-first li[title="Apple"] .euiSelectableListItem__prepend .dot').exists();
    assert.dom('.list-first li[title="Banana"] .euiSelectableListItem__prepend').hasText('', 'an empty wrapper');
    assert.dom('.search-last input.euiSelectableSearch').exists();
  });

  test('EuiSelectableListItem and EuiSelectableMessage on their own', async function (assert) {
    await render(
      <template>
        <ul role="listbox" aria-label="Items">
          <EuiSelectableListItem class="on" @checked="on" @isFocused={{true}} @prepend="#">Included</EuiSelectableListItem>
          <EuiSelectableListItem class="off" @checked="off" @showIcons={{false}} @onFocusBadge={{false}}>Excluded</EuiSelectableListItem>
        </ul>
        <EuiSelectableMessage @bordered={{true}}>Message</EuiSelectableMessage>
      </template>
    );

    assert.dom('.on').hasClass('euiSelectableListItem-isFocused').hasAria('selected', 'true');
    assert.dom('.on .euiSelectableListItem__icon').exists();
    assert.dom('.on .euiSelectableListItem__prepend').hasText('#');
    assert.dom('.on .euiSelectableListItem__onFocusBadge').exists();
    assert.dom('.off .euiSelectableListItem__icon').doesNotExist();
    assert.dom('.euiSelectableMessage').hasClass('euiSelectableMessage--bordered').hasText('Message');
  });
});
