import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, fillIn, render, waitUntil } from '@ember/test-helpers';

import EuiSuggest from '#src/components/eui-suggest.gts';
import EuiSuggestItem from '#src/components/eui-suggest-item.gts';

import type { EuiSuggestion } from '#src/components/eui-suggest.gts';

const SUGGESTIONS: EuiSuggestion[] = [
  { type: { iconType: 'kqlField', color: 'tint4' }, label: 'Field sample', description: 'This is the description' },
  { type: { iconType: 'search', color: 'tint10' }, label: 'Saved query' },
];

module('Integration | Component | eui-suggest', function (hooks) {
  setupRenderingTest(hooks);

  test('typing opens the suggestions, clicking one reports it', async function (assert) {
    const typed: string[] = [];
    const clicked: string[] = [];
    const onInputChange = (value: string) => typed.push(value);
    const onItemClick = (item: EuiSuggestion) => clicked.push(item.label);

    await render(
      <template>
        <EuiSuggest @suggestions={{SUGGESTIONS}} @onInputChange={{onInputChange}} @onItemClick={{onItemClick}} aria-label="Search" />
      </template>
    );

    assert.dom('.euiSuggestItem', document.body).doesNotExist('closed while empty');

    await fillIn('input', 'sam');
    await waitUntil(() => document.querySelector('.euiSuggestItem'));
    assert.deepEqual(typed, ['sam']);
    assert.dom('button.euiSuggestItem', document.body).exists({ count: 2 });

    await click(document.querySelector('button.euiSuggestItem') as Element);
    assert.deepEqual(clicked, ['Field sample']);
    assert.dom('.euiSuggestItem', document.body).doesNotExist('closed after a click');
  });

  test('status icons', async function (assert) {
    await render(
      <template>
        <div class="saved"><EuiSuggest @suggestions={{SUGGESTIONS}} @status="saved" aria-label="A" /></div>
        <div class="loading"><EuiSuggest @suggestions={{SUGGESTIONS}} @status="loading" aria-label="B" /></div>
      </template>
    );

    assert.dom('.saved .euiSuggestInput__statusIcon').exists();
    assert.dom('.loading .euiLoadingSpinner').exists();
  });

  test('EuiSuggestItem', async function (assert) {
    const type = { iconType: 'kqlValue', color: 'tint2' };

    await render(
      <template>
        <EuiSuggestItem class="plain" @type={{type}} @label="Label only" />
        <EuiSuggestItem class="full" @type={{type}} @label="Label" @description="Description" @labelWidth="30" @descriptionDisplay="wrap" />
      </template>
    );

    assert.dom('div.plain').hasClass('euiSuggestItem');
    assert.dom('.plain .euiSuggestItem__type').hasClass('euiSuggestItem__type--tint2');
    assert.dom('.plain .euiSuggestItem__label').hasClass('euiSuggestItem__labelDisplay--expand');
    assert.dom('.full .euiSuggestItem__label').hasClass('euiSuggestItem__labelDisplay--fixed').hasClass('euiSuggestItem__label--width30');
    assert.dom('.full .euiSuggestItem__description').hasClass('euiSuggestItem__description--wrap').hasText('Description');
  });
});
