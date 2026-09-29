import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, fillIn, focus, render, rerender, waitUntil } from '@ember/test-helpers';
import { on } from '@ember/modifier';
import { tracked } from '@glimmer/tracking';

import EuiSelectableTemplateSitewide from '#src/components/eui-selectable-template-sitewide.gts';

import type { EuiSelectableTemplateSitewideOption } from '#src/components/eui-selectable-template-sitewide.gts';

class State {
  @tracked options: EuiSelectableTemplateSitewideOption[] = [
    {
      label: 'Dashboards',
      icon: { type: 'dashboardApp' },
      meta: [{ text: 'Analytics', type: 'application' }],
    },
    {
      label: 'Revenue by region',
      icon: { type: 'visBarVertical' },
      avatar: { name: 'Sales' },
      meta: [{ text: 'Visualization' }, { text: 'Revenue', highlightSearchString: true }],
    },
  ];

  chosen?: string;

  onChange = (options: EuiSelectableTemplateSitewideOption[]) => {
    this.chosen = options.find((option) => option.checked === 'on')?.label;
  };
}

module('Integration | Component | eui-selectable-template-sitewide', function (hooks) {
  setupRenderingTest(hooks);

  test('focusing the search opens the results', async function (assert) {
    const state = new State();

    await render(<template><EuiSelectableTemplateSitewide @options={{state.options}} @onChange={{state.onChange}} /></template>);

    assert.dom('input.euiSelectableTemplateSitewide__search').hasAttribute('placeholder', 'Search for anything...');

    await focus('input.euiSelectableTemplateSitewide__search');
    await waitUntil(() => document.querySelector('.euiSelectableTemplateSitewide__listItem'));

    assert.dom('.euiSelectableTemplateSitewide__listItem', document.body).exists({ count: 2 });
    assert.dom('.euiSelectableTemplateSitewide__listItemTitle', document.body).exists({ count: 2 });
    assert.dom('.euiSelectableTemplateSitewide__optionMeta--application', document.body).hasText('Analytics');
    assert.dom('.euiSelectableListItem__prepend .euiIcon', document.body).exists({ count: 2 });
    assert.dom('.euiSelectableListItem__append .euiAvatar', document.body).exists({ count: 1 });

    await fillIn('input.euiSelectableTemplateSitewide__search', 'rev');
    assert.dom('.euiSelectableTemplateSitewide__listItem', document.body).exists({ count: 1 });
    assert.dom('.euiSelectableTemplateSitewide__optionMeta mark', document.body).hasText('Rev', 'meta with highlightSearchString is highlighted');

    await click(document.querySelector('.euiSelectableTemplateSitewide__listItem') as Element);
    await rerender();
    assert.strictEqual(state.chosen, 'Revenue by region');
  });

  test('a popover button, title, footer and loading', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiSelectableTemplateSitewide @options={{state.options}} @isLoading={{true}}>
          <:popoverButton as |toggle|><button type="button" class="open" {{on "click" toggle}}>Search</button></:popoverButton>
          <:popoverTitle><span class="title">Find</span></:popoverTitle>
          <:popoverFooter><span class="footer">Tip</span></:popoverFooter>
        </EuiSelectableTemplateSitewide>
      </template>
    );

    assert.dom('input.euiSelectableTemplateSitewide__search').doesNotExist('the search moves into the popover');
    await click('.open');
    await waitUntil(() => document.querySelector('.euiSelectableTemplateSitewide__popover'));

    assert.dom('.euiPopoverTitle .title', document.body).exists();
    assert.dom('.euiPopoverTitle input.euiSelectableTemplateSitewide__search', document.body).exists();
    assert.dom('.euiPopoverFooter .footer', document.body).exists();
    assert.dom('.euiSelectableTemplateSitewide__popover', document.body).includesText('Loading results');
  });
});
