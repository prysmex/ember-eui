import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { click, fillIn, focus, getRootElement, render, settled, triggerEvent, triggerKeyEvent } from '@ember/test-helpers';

import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiSearchBar, { Query } from '#src/components/eui-search-bar.gts';
import EuiSearchBarFilters from '#src/components/eui-search-bar-filters.gts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiSearchBarOnChangeArgs, SearchFilterConfig } from '#src/components/eui-search-bar.gts';
import type { CustomComponentProps } from '#src/components/eui-search-bar-filters.gts';

const light = resolveBorealisTheme('light').euiTheme;

/** In the test root first, then in portals. */
function el(selector: string): HTMLElement {
  const element =
    (getRootElement() as HTMLElement).querySelector<HTMLElement>(selector) ??
    document.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function rgb(color: string): string {
  const probe = document.createElement('div');
  probe.style.color = color;
  document.body.appendChild(probe);
  const resolved = getComputedStyle(probe).color;
  probe.remove();
  return resolved;
}

class State {
  @tracked query: Query | string | undefined;
  changes: EuiSearchBarOnChangeArgs[] = [];
  onChange = (args: EuiSearchBarOnChangeArgs) => {
    this.changes.push(args);
    if (args.query) this.query = args.query;
  };
}

module('Integration | Component | Borealis search bar', function (hooks) {
  setupRenderingTest(hooks);

  test('renders the upstream layout, field semantics and holder styles', async function (assert) {
    const filters: SearchFilterConfig[] = [{ type: 'is', field: 'open', name: 'Open' }];
    const rootCss = { marginTop: '7px' };
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiSearchBar @defaultQuery="is:open status:done" @filters={{filters}} @css={{rootCss}} class="caller">
            <:toolsLeft><button type="button" data-tool-left>Left</button></:toolsLeft>
            <:toolsRight><button type="button" data-tool-right>Right</button></:toolsRight>
          </EuiSearchBar>
        </EuiEmotionProvider>
      </template>
    );

    assert.dom('.caller.euiFlexGroup').exists('attributes go to the flex group').hasStyle({ marginTop: '7px' }, '@css');
    const items = [...el('.caller').children];
    assert.strictEqual(items.length, 4, 'tools, search holder, filters and tools');
    assert.dom(items[0]).containsText('Left');
    assert.dom(items[1]).hasClass('euiSearchBar__searchHolder');
    assert.dom(items[2]).hasClass('euiSearchBar__filtersHolder');
    assert.dom(items[3]).containsText('Right');

    assert
      .dom('input[type="search"]')
      .hasValue('is:open status:done')
      .hasAttribute('placeholder', 'Search...')
      .hasAttribute(
        'aria-label',
        'This is a search bar. After typing your query, hit enter to filter the results lower in the page.'
      )
      .doesNotHaveAttribute('aria-invalid');
    // upstream: min-inline-size is half the form max width (400px)
    assert.strictEqual(getComputedStyle(items[1] as HTMLElement).minWidth, '200px');
    assert.strictEqual(getComputedStyle(items[1] as HTMLElement).flexGrow, '1');
    assert.strictEqual(getComputedStyle(items[2] as HTMLElement).flexGrow, '0');
    assert.dom('.euiFilterGroup .euiFilterButton').hasText('Open').hasAttribute('aria-pressed', 'true');
  });

  test('parses typed queries, reports parse errors and keeps the field text', async function (assert) {
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiSearchBar @onChange={{state.onChange}} />
        </EuiEmotionProvider>
      </template>
    );

    await fillIn('input', 'john -tag:old count>5');
    assert.strictEqual(state.changes.length, 1);
    const [first] = state.changes;
    assert.strictEqual(first?.queryText, 'john -tag:old count>5');
    assert.strictEqual(first?.error, null);
    assert.ok(first?.query instanceof Query);
    assert.deepEqual(
      first?.query?.ast.clauses.map((clause) => clause.type),
      ['term', 'field', 'field']
    );
    assert.strictEqual(first?.query?.ast.getFieldClauses('count')?.[0]?.operator, 'gt');

    await fillIn('input', 'name:(a or');
    const second = state.changes[1];
    assert.strictEqual(second?.query, null);
    assert.strictEqual(second?.queryText, 'name:(a or');
    assert.ok(second?.error?.message, 'the parse error message');
    assert.dom('input').hasAttribute('aria-invalid', 'true').hasValue('name:(a or');

    await triggerEvent('.euiToolTipAnchor', 'mouseover');
    assert.dom('.euiToolTip', document.body).hasText(second!.error!.message, 'the error tooltip');
    await triggerEvent('.euiToolTipAnchor', 'mouseout');

    await fillIn('input', 'name:(a or b)');
    assert.strictEqual(state.changes[2]?.error, null);
    assert.dom('input').doesNotHaveAttribute('aria-invalid');
    assert.true(state.changes[2]?.query?.hasOrFieldClause('name', 'b'));
  });

  test('a controlled @query resets the field when its text changes', async function (assert) {
    const state = new State();
    state.query = 'a';
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiSearchBar @query={{state.query}} @onChange={{state.onChange}} />
        </EuiEmotionProvider>
      </template>
    );
    const input = el('input[type="search"]');
    assert.dom(input).hasValue('a');

    state.query = Query.parse('is:open b');
    await settled();
    assert.dom(input).hasValue('is:open b');
    assert.strictEqual(el('input'), input, 'same input element');

    // an equal text keeps the field
    state.query = 'is:open b';
    await settled();
    assert.dom(input).hasValue('is:open b');
    assert.strictEqual(state.changes.length, 0, 'controlled updates do not call @onChange');
  });

  test('incremental search, schema validation and @showErrorTooltip', async function (assert) {
    const state = new State();
    const box = {
      incremental: true,
      placeholder: 'Find users',
      schema: { strict: true, fields: { age: { type: 'number' } } }
    };
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiSearchBar @box={{box}} @onChange={{state.onChange}} @showErrorTooltip={{false}} @compressed={{true}} />
        </EuiEmotionProvider>
      </template>
    );
    assert
      .dom('input')
      .hasAttribute('placeholder', 'Find users')
      .hasAttribute(
        'aria-label',
        'This is a search bar. As you type, the results lower in the page will automatically filter.'
      );
    assert.dom('.euiToolTipAnchor').doesNotExist('no error tooltip');
    // compressed field height (upstream form compressed height)
    assert.strictEqual(getComputedStyle(el('input[type="search"]')).blockSize, '32px');

    const input = el('input[type="search"]') as HTMLInputElement;
    input.value = 'age:abc';
    await triggerKeyEvent(input, 'keyup', 'C');
    assert.strictEqual(state.changes[0]?.queryText, 'age:abc');
    assert.ok(
      state.changes[0]?.error?.message.includes('Expected a number value for field `age`'),
      state.changes[0]?.error?.message
    );
    input.value = 'age:12';
    await triggerKeyEvent(input, 'keyup', '2');
    assert.strictEqual(state.changes[1]?.query?.ast.getFieldClauses('age')?.[0]?.value, 12);
  });

  test('is, toggle and toggle group filters edit the query', async function (assert) {
    const state = new State();
    state.query = '';
    const filters: SearchFilterConfig[] = [
      { type: 'is', field: 'open', name: 'Open', negatedName: 'Closed' },
      { type: 'field_value_toggle', field: 'owner', value: 'me', name: 'Mine' },
      {
        type: 'field_value_toggle_group',
        field: 'status',
        items: [
          { value: 'todo', name: 'To do' },
          { value: 'done', name: 'Done' }
        ]
      },
      { type: 'is', field: 'hidden', name: 'Hidden', available: () => false }
    ];
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiSearchBar @query={{state.query}} @onChange={{state.onChange}} @filters={{filters}} />
        </EuiEmotionProvider>
      </template>
    );
    const buttons = () => [...document.querySelectorAll<HTMLElement>('.euiFilterButton')];
    assert.deepEqual(
      buttons().map((button) => button.textContent?.trim()),
      ['Open', 'Mine', 'To do', 'Done'],
      'unavailable filters are left out'
    );
    assert.true(buttons().every((button) => button.getAttribute('aria-pressed') === 'false'));

    await click(buttons()[0]!);
    assert.dom('input').hasValue('is:open');
    assert.strictEqual(state.changes.at(-1)?.queryText, 'is:open');
    assert.dom(buttons()[0]).hasAttribute('aria-pressed', 'true');

    await fillIn('input', '-is:open');
    assert.dom(buttons()[0]).hasText('Closed', 'negated name');
    await click(buttons()[0]!);
    assert.dom('input').hasValue('');

    await click(buttons()[1]!);
    assert.dom('input').hasValue('owner:me');
    await click(buttons()[2]!);
    assert.dom('input').hasValue('owner:me status:todo');
    await click(buttons()[3]!);
    assert.dom('input').hasValue('owner:me status:done', 'one group value at a time');
    assert.dom(buttons()[3]).hasAttribute('aria-pressed', 'true');
    assert.dom(buttons()[2]).hasAttribute('aria-pressed', 'false');
    await click(buttons()[3]!);
    assert.dom('input').hasValue('owner:me');
    await click(buttons()[1]!);
    assert.dom('input').hasValue('');
  });

  test('field value selection filter: popover list, multi/or/single select and async options', async function (assert) {
    const state = new State();
    state.query = 'tag:a';
    let loads = 0;
    const filters: SearchFilterConfig[] = [
      {
        type: 'field_value_selection',
        field: 'tag',
        name: 'Tags',
        options: [
          { value: 'a', name: 'Alpha' },
          { value: 'b', name: 'Beta' },
          { value: 'c', view: 'Gamma view' }
        ]
      },
      {
        type: 'field_value_selection',
        field: 'owner',
        name: 'Owner',
        multiSelect: 'or',
        cache: 10000,
        options: () => {
          loads++;
          return Promise.resolve([{ value: 'ann' }, { value: 'bob' }]);
        }
      },
      {
        type: 'field_value_selection',
        field: 'level',
        name: 'Level',
        multiSelect: false,
        options: [{ value: 'high' }, { value: 'low' }]
      }
    ];
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiSearchBar @query={{state.query}} @onChange={{state.onChange}} @filters={{filters}} />
        </EuiEmotionProvider>
      </template>
    );
    
    const tags = '.euiFilterButton[aria-label="Tags Selection"]';
    assert.dom(tags).hasAttribute('aria-expanded', 'false');
    assert.dom(`${tags} .euiNotificationBadge`).hasText('1', 'one active value');

    await click(tags);
    assert.dom(tags).hasAttribute('aria-expanded', 'true');
    const options = () =>
      [...document.querySelectorAll<HTMLElement>('.euiSelectableListItem')].map((option) => [
        option.textContent?.trim(),
        option.getAttribute('aria-checked')
      ]);
    assert.deepEqual(options(), [
      ['Alpha', 'true'],
      ['Beta', 'false'],
      ['Gamma view', 'false']
    ]);
    await click(document.querySelectorAll('.euiSelectableListItem')[1]!);
    assert.dom('input[type="search"]').hasValue('tag:a tag:b', 'multi select adds and clauses');
    assert.dom('.euiSelectableListItem', document.body).exists({ count: 3 }, 'multi select keeps the popover open');
    await click(document.querySelectorAll('.euiSelectableListItem')[0]!);
    assert.dom('input[type="search"]').hasValue('tag:b');
    // checked options are sorted first
    assert.strictEqual(options()[0]?.[0], 'Beta');
    await click(tags);
    

    const owner = '.euiFilterButton[aria-label="Owner Selection"]';
    await click(owner);
    assert.strictEqual(loads, 1);
    await click(document.querySelectorAll('.euiSelectableListItem')[0]!);
    await click(document.querySelectorAll('.euiSelectableListItem')[1]!);
    assert.dom('input[type="search"]').hasValue('tag:b owner:(ann or bob)', 'or clause');
    await click(owner);
    await click(owner);
    assert.strictEqual(loads, 1, 'cached async options');
    await click(owner);
    

    const level = '.euiFilterButton[aria-label="Level Selection"]';
    await click(level);
    await click(document.querySelectorAll('.euiSelectableListItem')[1]!);
    assert.dom('input[type="search"]').hasValue('tag:b owner:(ann or bob) level:low');
    assert.dom('.euiSelectableListItem', document.body).doesNotExist('single select closes the popover');
    await click(level);
    assert.deepEqual(options(), [
      ['low', null],
      ['high', null]
    ], 'single select: the checked option first, without check boxes');
    assert.dom(document.querySelectorAll('.euiSelectableListItem')[0]).hasAttribute('aria-selected', 'true');
    await click(document.querySelectorAll('.euiSelectableListItem')[1]!);
    assert.dom('input[type="search"]').hasValue('tag:b owner:(ann or bob) level:high', 'replaces the value');
  });

  test('field value selection filter shows a search above the threshold', async function (assert) {
    const query = Query.parse('');
    const options = Array.from({ length: 12 }, (_, i) => ({ value: `v${i}` }));
    const filters: SearchFilterConfig[] = [
      { type: 'field_value_selection', field: 'v', name: 'Values', options, autoSortOptions: false }
    ];
    const noop = () => {};
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiSearchBarFilters @query={{query}} @onChange={{noop}} @filters={{filters}} @compressed={{true}} />
        </EuiEmotionProvider>
      </template>
    );
    await click('.euiFilterButton');
    assert.dom('.euiPopoverTitle input[type="search"]', document.body).exists('search in the popover title');
    await fillIn(el('.euiPopoverTitle input[type="search"]'), 'v1');
    assert.dom('.euiSelectableListItem', document.body).exists({ count: 3 }, 'v1, v10, v11');
  });

  test('custom component filters and the hint popover', async function (assert) {
    class OnlyMine extends Component<{ Args: CustomComponentProps }> {
      toggle = () => this.args.onChange?.(this.args.query.addSimpleFieldValue('owner', 'me'));
      <template>
        <button type="button" data-custom {{on "click" this.toggle}}>{{@query.text}}|mine</button>
      </template>
    }
    const state = new State();
    const filters: SearchFilterConfig[] = [{ type: 'custom_component', component: OnlyMine }];
    const hint = { popoverProps: { panelPaddingSize: 's' as const } };
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiSearchBar @defaultQuery="x" @onChange={{state.onChange}} @filters={{filters}} @hint={{hint}}>
            <:hint><span data-hint>Try <code>is:open</code></span></:hint>
          </EuiSearchBar>
        </EuiEmotionProvider>
      </template>
    );
    assert.dom('[data-custom]').hasText('x|mine');
    await click('[data-custom]');
    assert.dom('input[type="search"]').hasValue('x owner:me');
    assert.dom('[data-custom]').hasText('x owner:me|mine');

    assert.dom('[data-hint]').doesNotExist();
    assert.dom('input[type="search"]').doesNotHaveAttribute('aria-describedby');
    await focus('input[type="search"]');
    assert.dom('[data-hint]', document.body).exists('hint shown on focus');
    const describedBy = el('input[type="search"]').getAttribute('aria-describedby');
    assert.ok(describedBy, 'the field is described by the hint');
    assert.dom(`#${describedBy}`, document.body).containsText('Try is:open');
  });

  test('filter buttons follow the nearest provider colors', async function (assert) {
    const query = Query.parse('is:open');
    const filters: SearchFilterConfig[] = [{ type: 'is', field: 'open', name: 'Open' }];
    const noop = () => {};
    await render(
      <template>
        <EuiEmotionProvider @colorMode="light">
          <div class="light"><EuiSearchBarFilters @query={{query}} @onChange={{noop}} @filters={{filters}} /></div>
          <EuiEmotionProvider @colorMode="dark">
            <div class="dark"><EuiSearchBarFilters @query={{query}} @onChange={{noop}} @filters={{filters}} /></div>
          </EuiEmotionProvider>
        </EuiEmotionProvider>
      </template>
    );
    const dark = resolveBorealisTheme('dark').euiTheme;
    assert.notStrictEqual(
      getComputedStyle(el('.light .euiFilterGroup')).backgroundColor,
      getComputedStyle(el('.dark .euiFilterGroup')).backgroundColor,
      'each group uses its own provider'
    );
    assert.strictEqual(
      getComputedStyle(el('.dark .euiFilterGroup')).backgroundColor,
      rgb(dark.components.forms.background),
      'dark form background'
    );
    assert.strictEqual(
      getComputedStyle(el('.light .euiFilterGroup')).backgroundColor,
      rgb(light.components.forms.background)
    );
  });
});
