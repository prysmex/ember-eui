import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  fillIn,
  focus,
  render,
  rerender,
  triggerEvent,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';

import EuiButton from '#src/components/eui-button.gts';
import EuiInputPopover from '#src/components/eui-input-popover.gts';
import EuiSelectable from '#src/components/eui-selectable.gts';

import type {
  EuiSelectableOption,
  EuiSelectableOptionMatcher
} from '#src/components/eui-selectable.gts';

const LONG =
  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore';
const noop = () => {};

function q<T extends Element = HTMLElement>(selector: string, root: ParentNode = document) {
  const element = root.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

/** The option `<li>` whose text includes `label`. */
function option(label: string, root: ParentNode = document) {
  const item = [...root.querySelectorAll<HTMLElement>('li.euiSelectableListItem')].find((li) =>
    li.textContent!.includes(label)
  );
  if (!item) throw new Error(`Missing option ${label}`);
  return item;
}

/** The labels shown, without the screen reader texts. */
const visibleLabels = (root: ParentNode = document) =>
  [...root.querySelectorAll('li.euiSelectableListItem .euiSelectableListItem__text')].map((text) => {
    const clone = text.cloneNode(true) as HTMLElement;
    clone.querySelectorAll('.euiScreenReaderOnly').forEach((sr) => sr.remove());
    return clone.textContent!.trim();
  });

function moons(): EuiSelectableOption[] {
  return [
    { label: 'Titan' },
    { label: 'Enceladus', disabled: true },
    { label: 'Mimas', checked: 'on' },
    { label: 'Pandora' }
  ];
}

class State {
  @tracked options: EuiSelectableOption[];
  changes: { options: EuiSelectableOption[]; event: Event | undefined; changed: EuiSelectableOption }[] = [];

  constructor(options: EuiSelectableOption[] = moons()) {
    this.options = options;
  }

  onChange = (options: EuiSelectableOption[], event: Event | undefined, changed: EuiSelectableOption) => {
    this.changes.push({ options, event, changed });
    this.options = options;
  };

  get checked() {
    return this.options.filter((o) => o.checked).map((o) => `${o.label}:${o.checked}`);
  }
}

function deepFreeze(options: EuiSelectableOption[]) {
  return Object.freeze(options.map((o) => Object.freeze({ ...o }))) as unknown as EuiSelectableOption[];
}

module('Integration | Component | eui-selectable upstream props', function (hooks) {
  setupRenderingTest(hooks);

  test('errorMessage replaces the list (before loading) and null keeps it', async function (assert) {
    const state = new (class {
      @tracked error: string | null = null;
      @tracked isLoading = true;
    })();
    const options = moons();

    await render(
      <template>
        <EuiSelectable @options={{options}} @errorMessage={{state.error}} @isLoading={{state.isLoading}} @listProps={{hash bordered=true}} />
      </template>
    );
    assert.dom('.euiSelectableMessage').includesText('Loading options', 'null: no error message');

    state.error = 'Error!';
    await rerender();
    assert.dom('.euiSelectableMessage p').hasText('Error!', 'the error wins over loading');
    assert.dom('.euiSelectableMessage .euiBorealisLoadingSpinner').doesNotExist();
    assert.dom('ul[role="listbox"]').doesNotExist();
    assert.strictEqual(getComputedStyle(q('.euiSelectableMessage')).borderTopStyle, 'solid', 'bordered like the list');

    state.error = null;
    state.isLoading = false;
    await rerender();
    assert.dom('.euiSelectableMessage').doesNotExist();
    assert.dom('li.euiSelectableListItem').exists({ count: 4 });
  });

  test('option toolTipContent / toolTipProps: described, shown on hover and while current', async function (assert) {
    const options: EuiSelectableOption[] = [
      { label: 'Titan', toolTipContent: 'The largest moon of Saturn' },
      { label: 'Pandora' },
      { label: 'Iapetus', toolTipContent: 'The outermost large moon', toolTipProps: { position: 'bottom', title: 'Iapetus' } },
      { label: 'Disabled', disabled: true, toolTipContent: 'never shown' }
    ];

    await render(<template><EuiSelectable aria-label="Moons" @options={{options}} @onChange={{noop}} /></template>);

    const titan = option('Titan');
    const tooltipId = titan.getAttribute('aria-describedby')!;
    assert.ok(tooltipId, 'the option is described by its tooltip');
    assert.dom(option('Pandora')).doesNotHaveAttribute('aria-describedby');
    assert.dom(option('Disabled')).doesNotHaveAttribute('aria-describedby', 'no tooltip on disabled options');
    assert.dom('.euiSelectableListItem__text', titan).doesNotHaveAttribute('title', 'no title with a tooltip');
    assert.dom('.euiSelectableListItem__text', option('Pandora')).hasAttribute('title', 'Pandora');

    await triggerEvent(q('.euiListItemLayout__content', titan).parentElement!, 'mouseover');
    await waitUntil(() => document.getElementById(tooltipId), { timeout: 2000 });
    assert.dom(document.getElementById(tooltipId)).hasAttribute('role', 'tooltip').hasText('The largest moon of Saturn');
    await triggerEvent(q('.euiListItemLayout__content', titan).parentElement!, 'mouseout');
    await waitUntil(() => !document.getElementById(tooltipId), { timeout: 2000 });

    const iapetusTip = option('Iapetus').getAttribute('aria-describedby')!;
    await focus('ul[role="listbox"]');
    await triggerKeyEvent('ul[role="listbox"]', 'keydown', 'ArrowDown');
    await triggerKeyEvent('ul[role="listbox"]', 'keydown', 'ArrowDown');
    assert.dom(option('Iapetus')).hasClass('euiSelectableListItem-isFocused');
    await waitUntil(() => document.getElementById(iapetusTip), { timeout: 2000 });
    assert.dom(document.getElementById(iapetusTip)).includesText('Iapetus').includesText('The outermost large moon');
    const tip = document.getElementById(iapetusTip)!.getBoundingClientRect();
    assert.true(tip.top >= option('Iapetus').getBoundingClientRect().bottom - 1, 'toolTipProps.position bottom');

    await triggerKeyEvent('ul[role="listbox"]', 'keydown', 'ArrowDown');
    await waitUntil(() => !document.getElementById(iapetusTip), { timeout: 2000 });
    assert.notOk(document.getElementById(iapetusTip), 'hidden when another option is current');
  });

  test('option hasAriaDisabled: navigable, aria-disabled, not selectable, tooltip while current', async function (assert) {
    const state = new State([
      { label: 'Titan' },
      { label: 'Enceladus', disabled: true, hasAriaDisabled: true, toolTipContent: 'Currently unavailable' },
      { label: 'Mimas', disabled: true },
      { label: 'Dione' }
    ]);

    await render(<template><EuiSelectable aria-label="Moons" @options={{state.options}} @onChange={{state.onChange}} @listProps={{hash onFocusBadge=true}} /></template>);

    const enceladus = option('Enceladus');
    assert.dom(enceladus).hasAria('disabled', 'true');
    assert.dom(enceladus).doesNotHaveAttribute('disabled');
    assert.dom(enceladus).hasAttribute('aria-describedby');

    await focus('ul[role="listbox"]');
    assert.dom(option('Titan')).hasClass('euiSelectableListItem-isFocused');
    await triggerKeyEvent('ul[role="listbox"]', 'keydown', 'ArrowDown');
    assert.dom(enceladus).hasClass('euiSelectableListItem-isFocused', 'hasAriaDisabled options are navigable');
    assert.dom('.euiSelectableListItem__onFocusBadge', enceladus).exists('focus badge shows');
    assert.strictEqual(getComputedStyle(enceladus).cursor, 'not-allowed', 'still looks disabled');
    const tipId = enceladus.getAttribute('aria-describedby')!;
    await waitUntil(() => document.getElementById(tipId), { timeout: 2000 });
    assert.dom(document.getElementById(tipId)).hasText('Currently unavailable');

    await triggerKeyEvent('ul[role="listbox"]', 'keydown', 'Enter');
    await click(enceladus);
    assert.deepEqual(state.changes, [], 'Enter and click do not select it');

    await triggerKeyEvent('ul[role="listbox"]', 'keydown', 'ArrowDown');
    assert.dom(option('Dione')).hasClass('euiSelectableListItem-isFocused', 'native disabled options are skipped');
  });

  test('option searchableLabel: matched instead of the label and used as the title', async function (assert) {
    const options: EuiSelectableOption[] = [
      { label: 'Netherlands', searchableLabel: 'Netherlands NL secondary' },
      { label: 'Norway', searchableLabel: 'Norway NO' }
    ];

    await render(<template><EuiSelectable @options={{options}} @onChange={{noop}} @searchable={{true}} /></template>);

    assert.dom('.euiSelectableListItem__text', option('Netherlands')).hasAttribute('title', 'Netherlands NL secondary');
    await fillIn('input.euiSelectableSearch', 'secondary');
    assert.deepEqual(visibleLabels(), ['Netherlands'], 'the searchable label matches');
    await fillIn('input.euiSelectableSearch', 'Nor');
    assert.deepEqual(visibleLabels(), ['Norway']);
  });

  test('listProps.isVirtualized: fixed rows and a computed height, or rows that fit their content', async function (assert) {
    const state = new (class {
      @tracked isVirtualized = true;
    })();
    const options: EuiSelectableOption[] = Array.from({ length: 10 }, (_, i) => ({ label: `Option ${i}` }));
    const groups: EuiSelectableOption[] = [{ label: 'Group', isGroupLabel: true }, ...options.slice(0, 2), { label: 'Second', isGroupLabel: true }];

    await render(
      <template>
        <div class="a"><EuiSelectable @options={{options}} @onChange={{noop}} @listProps={{hash isVirtualized=state.isVirtualized}} /></div>
        <div class="b"><EuiSelectable @options={{options}} @onChange={{noop}} @height={{100}} @listProps={{hash isVirtualized=false}} /></div>
        <div class="c"><EuiSelectable @options={{groups}} @onChange={{noop}} @listProps={{hash isVirtualized=state.isVirtualized}} /></div>
      </template>
    );

    const list = () => q('.a .euiSelectableList__list');
    assert.strictEqual(list().style.height, '208px', 'virtualized: 6.5 rows of 32px');
    assert.strictEqual(q('.a li.euiSelectableListItem').style.height, '32px');
    assert.strictEqual(q('.c .euiSelectableList__groupLabel:not(:first-child)').style.height, '48px');

    state.isVirtualized = false;
    await rerender();
    assert.strictEqual(list().style.height, '', 'not virtualized: no computed height');
    assert.strictEqual(q('.a li.euiSelectableListItem').style.height, '', 'rows fit their content');
    assert.true(list().scrollHeight <= list().clientHeight + 1, 'all rows visible without scrolling');
    assert.strictEqual(q('.c .euiSelectableList__groupLabel:not(:first-child)').style.height, '');
    assert.strictEqual(q('.b .euiSelectableList__list').style.height, '100px', 'a numeric height is kept');
  });

  test('listProps.textWrap (and option textWrap) wrap only without virtualization', async function (assert) {
    const state = new (class {
      @tracked isVirtualized = false;
    })();
    const options: EuiSelectableOption[] = [
      { label: LONG },
      { label: `Truncated ${LONG}`, textWrap: 'truncate' }
    ];

    await render(
      <template>
        <div style="width: 300px">
          <EuiSelectable @options={{options}} @onChange={{noop}} @listProps={{hash isVirtualized=state.isVirtualized textWrap="wrap"}} />
        </div>
      </template>
    );

    const [wrapped, truncated] = [...document.querySelectorAll<HTMLElement>('.euiSelectableListItem__text')];
    assert.strictEqual(getComputedStyle(wrapped!).whiteSpace, 'normal', 'wraps');
    assert.true(wrapped!.closest('li')!.offsetHeight > 40, 'the row grows');
    assert.strictEqual(getComputedStyle(truncated!).whiteSpace, 'nowrap', 'the option textWrap wins');
    assert.strictEqual(getComputedStyle(truncated!).textOverflow, 'ellipsis');

    state.isVirtualized = true;
    await rerender();
    assert.strictEqual(getComputedStyle(q('.euiSelectableListItem__text')).whiteSpace, 'nowrap', 'virtualized lists always truncate');
  });

  test('listProps.truncationProps: EuiTextTruncate, overridden per option, no title', async function (assert) {
    const options: EuiSelectableOption[] = [
      { label: LONG },
      { label: `Start ${LONG}`, truncationProps: { truncation: 'start' } },
      { label: 'Short' }
    ];

    await render(
      <template>
        <div style="width: 300px">
          <EuiSelectable @options={{options}} @onChange={{noop}} @listProps={{hash truncationProps=(hash truncation="middle")}} />
        </div>
      </template>
    );
    await waitUntil(() => document.querySelectorAll('[data-test-subj="truncatedText"]').length === 2, { timeout: 2000 });

    const truncated = (label: string) => q('[data-test-subj="truncatedText"]', option(label.slice(0, 5))).textContent!.trim();
    const middle = truncated(LONG);
    assert.ok(middle.includes('…') && !middle.startsWith('…') && !middle.endsWith('…'), `middle: ${middle}`);
    assert.ok(truncated('Start').startsWith('…'), 'the option truncationProps win');
    assert.dom('[data-test-subj="truncatedText"]', option('Short')).doesNotExist('short texts are not truncated');
    assert.dom('.euiSelectableListItem__text', option('Lorem')).doesNotHaveAttribute('title', 'no title with EuiTextTruncate');
  });

  test('searching keeps the match visible in long labels (startEnd) and isPreFiltered.highlightSearch', async function (assert) {
    const state = new (class {
      @tracked isPreFiltered: boolean | { highlightSearch: boolean } = false;
    })();
    const options: EuiSelectableOption[] = [{ label: LONG }, { label: 'Labore short' }];

    await render(
      <template>
        <div style="width: 300px">
          <EuiSelectable @options={{options}} @onChange={{noop}} @searchable={{true}} @isPreFiltered={{state.isPreFiltered}} />
        </div>
      </template>
    );

    await fillIn('input.euiSelectableSearch', 'consectetur');
    await waitUntil(() => document.querySelector('[data-test-subj="truncatedText"]'), { timeout: 2000 });
    const shown = q('[data-test-subj="truncatedText"]').textContent!.trim();
    assert.ok(shown.startsWith('…') && shown.endsWith('…') && shown.includes('consectetur'), `around the match: ${shown}`);
    assert.dom('[data-test-subj="truncatedText"] mark').hasText('consectetur');

    state.isPreFiltered = { highlightSearch: false };
    await rerender();
    assert.dom('li.euiSelectableListItem').exists({ count: 2 }, 'pre-filtered: every option shows');
    assert.dom('mark').doesNotExist('no highlighting');

    state.isPreFiltered = true;
    await rerender();
    await fillIn('input.euiSelectableSearch', 'short');
    assert.dom('li.euiSelectableListItem mark').hasText('short', 'highlights by default');
  });

  test('optionMatcher replaces the default matching', async function (assert) {
    const options: EuiSelectableOption[] = [{ label: 'Titan' }, { label: 'Pandora is a titan' }, { label: 'titanic' }];
    const startsWith: EuiSelectableOptionMatcher = ({ option: o, searchValue }) => o.label.startsWith(searchValue);
    const calls: string[] = [];
    const exact: EuiSelectableOptionMatcher = ({ option: o, searchValue, normalizedSearchValue }) => {
      calls.push(`${searchValue}/${normalizedSearchValue}`);
      return o.label.toLowerCase() === normalizedSearchValue;
    };

    await render(
      <template>
        <div class="starts"><EuiSelectable @options={{options}} @onChange={{noop}} @searchable={{true}} @optionMatcher={{startsWith}} /></div>
        <div class="exact"><EuiSelectable @options={{options}} @onChange={{noop}} @searchable={{true}} @optionMatcher={{exact}} /></div>
        <div class="default"><EuiSelectable @options={{options}} @onChange={{noop}} @searchable={{true}} /></div>
      </template>
    );

    await fillIn('.starts input', 'Titan');
    assert.deepEqual(visibleLabels(q('.starts')), ['Titan'], 'case sensitive starts with');
    await fillIn('.exact input', 'TITANIC');
    assert.deepEqual(visibleLabels(q('.exact')), ['titanic']);
    assert.ok(calls.includes('TITANIC/titanic'), 'gets the search and the normalized search');
    await fillIn('.default input', 'titan');
    assert.deepEqual(visibleLabels(q('.default')), ['Titan', 'Pandora is a titan', 'titanic'], 'default: contains, ignoring case');
  });

  test('searchProps.value / onChange: controlled search, reported on render and on typing', async function (assert) {
    const state = new (class {
      @tracked value = 'pan';
      calls: [string, string[]][] = [];
      get searchProps() {
        return { value: this.value, onChange: this.onChange, 'data-test-subj': 'searchInput' };
      }
      onChange = (value: string, matching: EuiSelectableOption[]) => {
        this.calls.push([value, matching.map((o) => o.label)]);
        this.value = value;
      };
    })();
    const options = moons();

    await render(
      <template>
        <EuiSelectable @options={{options}} @onChange={{noop}} @searchable={{true}} @searchProps={{state.searchProps}} />
      </template>
    );

    assert.dom('[data-test-subj="searchInput"]').hasValue('pan');
    assert.deepEqual(visibleLabels(), ['Pandora']);
    assert.deepEqual(state.calls, [['pan', ['Pandora']]], 'called once after the first render');

    state.value = 'Mi';
    await rerender();
    assert.dom('input.euiSelectableSearch').hasValue('Mi', 'the field follows the value');
    assert.deepEqual(visibleLabels(), ['Mimas']);

    state.value = 'not in the list';
    await rerender();
    assert.dom('ul[role="listbox"]').doesNotExist();
    assert.dom('.euiSelectableMessage').includesText("doesn't match any options");

    state.value = '';
    await rerender();
    assert.dom('li.euiSelectableListItem').exists({ count: 4 });

    await fillIn('input.euiSelectableSearch', 'ti');
    assert.deepEqual(state.calls.at(-1), ['ti', ['Titan']], 'typing reports the matching options');
    assert.deepEqual(visibleLabels(), ['Titan']);
  });

  test('searchProps.onKeyDown / onClick / onFocus / onBlur / inputRef / isLoading', async function (assert) {
    const events: string[] = [];
    const props = {
      onKeyDown: (e: KeyboardEvent) => events.push(`keydown:${e.key}`),
      onClick: () => events.push('click'),
      onFocus: () => events.push('focus'),
      onBlur: () => events.push('blur'),
      inputRef: (input: HTMLInputElement) => events.push(`ref:${input.tagName}`),
      isLoading: true
    };
    const options = moons();

    await render(<template><EuiSelectable @options={{options}} @onChange={{noop}} @searchable={{true}} @searchProps={{props}} /></template>);

    assert.deepEqual(events, ['ref:INPUT']);
    await click('input.euiSelectableSearch');
    await triggerKeyEvent('input.euiSelectableSearch', 'keydown', 'ArrowDown');
    await triggerEvent('input.euiSelectableSearch', 'blur');
    assert.deepEqual(events, ['ref:INPUT', 'focus', 'click', 'keydown:ArrowDown', 'blur']);
    assert.dom('.euiSelectable .euiLoadingSpinner, .euiSelectable .euiBorealisLoadingSpinner').exists('isLoading spinner');
  });

  test('upstream "EuiInputPopover with selectable" example: controlled search drives the popover', async function (assert) {
    const state = new (class {
      @tracked options: EuiSelectableOption[] = moons().map(({ label }) => ({ label }));
      @tracked isOpen = false;
      @tracked inputValue = '';
      @tracked isSearching = true;

      get isPreFiltered() {
        return this.isSearching ? false : { highlightSearch: false };
      }

      onChange = (options: EuiSelectableOption[], _event: Event | undefined, changed: EuiSelectableOption) => {
        this.options = options;
        this.isOpen = false;
        if (changed.checked === 'on') {
          this.inputValue = changed.label;
          this.isSearching = false;
        } else {
          this.inputValue = '';
        }
      };

      searchProps = {
        onChange: (value: string) => {
          this.inputValue = value;
          this.isSearching = true;
        },
        onKeyDown: (event: KeyboardEvent) => {
          if (event.key === 'Tab') return (this.isOpen = false);
          if (event.key !== 'Escape') return (this.isOpen = true);
        },
        onClick: () => (this.isOpen = true),
        onFocus: () => (this.isOpen = true)
      };

      get props() {
        return { ...this.searchProps, value: this.inputValue };
      }

      close = () => (this.isOpen = false);
    })();

    await render(
      <template>
        <EuiSelectable
          aria-label="Selectable + input popover example"
          @options={{state.options}}
          @onChange={{state.onChange}}
          @singleSelection={{true}}
          @searchable={{true}}
          @searchProps={{state.props}}
          @isPreFiltered={{state.isPreFiltered}}
          as |parts|
        >
          <EuiInputPopover @isOpen={{state.isOpen}} @closePopover={{state.close}} @disableFocusTrap={{true}} @panelPaddingSize="none">
            <:input><parts.search /></:input>
            <:content><parts.list /></:content>
          </EuiInputPopover>
        </EuiSelectable>
      </template>
    );

    assert.dom('li.euiSelectableListItem').doesNotExist('closed');
    await click('input.euiSelectableSearch');
    await waitUntil(() => document.querySelector('li.euiSelectableListItem'));
    assert.strictEqual(document.querySelectorAll('li.euiSelectableListItem').length, 4, 'open with all options');

    await fillIn('input.euiSelectableSearch', 'pan');
    assert.deepEqual(visibleLabels(), ['Pandora'], 'typing filters');
    assert.dom(document.querySelector('li.euiSelectableListItem mark')).hasText('Pan', 'portaled list highlights');

    await click(option('Pandora'));
    
    assert.dom('input.euiSelectableSearch').hasValue('Pandora', 'the selection fills the field');
    assert.deepEqual(state.options.filter((o) => o.checked).map((o) => o.label), ['Pandora']);
    assert.false(state.isOpen, 'closes');

    await triggerKeyEvent('input.euiSelectableSearch', 'keydown', 'ArrowDown');
    await waitUntil(() => document.querySelector('li.euiSelectableListItem'));
    assert.strictEqual(document.querySelectorAll('li.euiSelectableListItem').length, 4, 'not searching: the full list');
    assert.notOk(document.querySelector('li.euiSelectableListItem mark'), 'no highlight of the selected value');

    // deselecting clears the field (controlled value back to '')
    await click(option('Pandora'));
    
    assert.dom('input.euiSelectableSearch').hasValue('');
    assert.deepEqual(state.options.filter((o) => o.checked), []);
  });

  test('frozen options: replaced by the caller (async results), never mutated', async function (assert) {
    const state = new State(deepFreeze(moons()));
    const original = state.options;

    await render(<template><EuiSelectable aria-label="Moons" @options={{state.options}} @onChange={{state.onChange}} @searchable={{true}} /></template>);

    await click(option('Titan'));
    assert.deepEqual(state.checked, ['Titan:on', 'Mimas:on']);
    assert.notStrictEqual(state.options, original, 'a new array');
    assert.deepEqual(original.map((o) => o.checked), [undefined, undefined, 'on', undefined], 'the frozen input is untouched');

    // async results replace the options while searching
    await fillIn('input.euiSelectableSearch', 'a');
    state.options = deepFreeze([{ label: 'Callisto' }, { label: 'Ganymede', checked: 'on' }, { label: 'Europa' }]);
    await rerender();
    assert.deepEqual(visibleLabels(), ['Callisto', 'Ganymede', 'Europa']);
    await triggerKeyEvent('input.euiSelectableSearch', 'keydown', 'ArrowDown');
    await triggerKeyEvent('input.euiSelectableSearch', 'keydown', 'Enter');
    const { changed, options: next } = state.changes.at(-1)!;
    assert.true(next.includes(changed), 'the keyboard toggles an option of the new results');
    assert.true(Object.isFrozen(state.changes[0]!.options) === false, 'onChange arrays are new, unfrozen arrays');

    state.options = deepFreeze([{ label: 'Io' }]);
    await rerender();
    assert.deepEqual(visibleLabels(), [], "'a' does not match Io");
    assert.dom('.euiSelectableMessage').includesText("doesn't match");
    assert.dom('input.euiSelectableSearch').doesNotHaveAria('activedescendant', 'a stale current option is dropped');
    await fillIn('input.euiSelectableSearch', '');
    assert.deepEqual(visibleLabels(), ['Io']);
  });

  test('onChange gets the event and the changed option (click and keyboard)', async function (assert) {
    const state = new State();

    await render(<template><EuiSelectable aria-label="Moons" @options={{state.options}} @onChange={{state.onChange}} /></template>);

    await click(option('Titan'));
    let change = state.changes.at(-1)!;
    assert.strictEqual(change.event?.type, 'click');
    assert.deepEqual(change.changed, { label: 'Titan', checked: 'on' });
    assert.strictEqual(change.options[0], change.changed, 'the changed option is the one in the array');

    await triggerKeyEvent('ul[role="listbox"]', 'keydown', 'Enter');
    change = state.changes.at(-1)!;
    assert.strictEqual(change.event?.type, 'keydown');
    assert.deepEqual(change.changed, { label: 'Titan' }, 'unchecked by Enter');
  });

  test('onActiveOptionChange reports the current option', async function (assert) {
    const seen: (string | null)[] = [];
    const report = (o: EuiSelectableOption | null) => seen.push(o ? o.label : null);
    const options = moons();

    await render(
      <template>
        <div class="plain"><EuiSelectable aria-label="Moons" @options={{options}} @onActiveOptionChange={{report}} /></div>
        <div class="search"><EuiSelectable @options={{options}} @searchable={{true}} @searchProps={{hash value="pandora"}} @onActiveOptionChange={{report}} /></div>
      </template>
    );

    await triggerKeyEvent('.plain .euiSelectableList__list', 'keydown', 'ArrowDown');
    assert.deepEqual(seen, ['Titan']);
    await triggerKeyEvent('.plain .euiSelectableList__list', 'keydown', 'ArrowUp');
    assert.deepEqual(seen, ['Titan', 'Pandora'], 'disabled options are skipped, wraps');

    await triggerKeyEvent('.search input', 'keydown', 'ArrowDown');
    assert.deepEqual(seen.at(-1), 'Pandora', 'the searched option');
  });

  test('keys pressed on other content inside do not navigate or select (upstream)', async function (assert) {
    const state = new State();
    const seen: unknown[] = [];
    const report = (o: unknown) => seen.push(o);

    await render(
      <template>
        <EuiSelectable aria-label="Moons" @options={{state.options}} @onChange={{state.onChange}} @onActiveOptionChange={{report}} as |parts|>
          <parts.list />
          <EuiButton id="footer-button" {{on "click" noop}}>Manage</EuiButton>
        </EuiSelectable>
      </template>
    );

    await triggerKeyEvent('#footer-button', 'keydown', 'ArrowDown');
    await triggerKeyEvent('#footer-button', 'keydown', 'Enter');
    assert.deepEqual(state.changes, [], 'no change');
    assert.deepEqual(seen, [], 'no current option');
    await triggerKeyEvent('.euiSelectableList__list', 'keydown', 'ArrowDown');
    await triggerKeyEvent('.euiSelectableList__list', 'keydown', 'Enter');
    assert.deepEqual(state.checked, ['Titan:on', 'Mimas:on'], 'keys on the list still work');
  });

  test('a11y: listbox activedescendant, live results region and selectableScreenReaderText', async function (assert) {
    const options = moons();

    await render(
      <template>
        <div class="plain"><EuiSelectable aria-label="Moons" @options={{options}} @onChange={{noop}} /></div>
        <div class="search"><EuiSelectable @options={{options}} @onChange={{noop}} @searchable={{true}} @selectableScreenReaderText="Custom screenreader instructions." /></div>
      </template>
    );

    const ul = q('.plain ul[role="listbox"]');
    assert.dom(ul).doesNotHaveAttribute('aria-activedescendant');
    await triggerKeyEvent(ul, 'keydown', 'ArrowDown');
    assert.dom(ul).hasAria('activedescendant', option('Titan', q('.plain')).id, 'non-searchable listbox points at the current option');
    assert.dom('.plain [role="status"]').doesNotExist('no live region without search');

    const input = q('.search input');
    assert.dom(`#${input.getAttribute('aria-describedby')}`).hasText(
      'Custom screenreader instructions. Use the Up and Down arrow keys to move focus over options. Press Enter to select. Press Escape to collapse options.'
    );
    assert.dom('.search ul[role="listbox"]').doesNotHaveAttribute('aria-activedescendant', 'searchable: on the input');

    const live = () =>
      [...document.querySelectorAll('.search [role="status"]')].map((region) => region.textContent!.trim()).join('');
    assert.strictEqual(live(), '', 'inactive until an option is current');
    await triggerKeyEvent(input, 'keydown', 'ArrowDown');
    await waitUntil(() => live() === '3 results available', { timeout: 2000 });
    assert.strictEqual(live(), '3 results available', 'disabled options are not counted');
    await fillIn(input, 'tita');
    await triggerKeyEvent(input, 'keydown', 'ArrowDown');
    await waitUntil(() => live() === '1 result available', { timeout: 2000 });
    assert.strictEqual(live(), '1 result available');
    await fillIn(input, 'zzz');
    await waitUntil(() => live().includes('zzz'), { timeout: 2000 });
    assert.strictEqual(live(), "zzz doesn't match any options", 'messages are announced');
  });

  test('option data-test-subj and listProps.css', async function (assert) {
    const options: EuiSelectableOption[] = [{ label: 'Titan', 'data-test-subj': 'titanOption' }, { label: 'Mimas' }];
    const css = { '.euiSelectableList__list': { maxBlockSize: '20px' } };

    await render(<template><EuiSelectable aria-label="Moons" @options={{options}} @onChange={{noop}} @listProps={{hash css=css}} /></template>);

    assert.dom('[data-test-subj="titanOption"]').hasText(/Titan/);
    assert.dom(option('Mimas')).hasAttribute('data-test-subj', 'euiListItemLayout', 'upstream default');
    assert.strictEqual(getComputedStyle(q('.euiSelectableList__list')).maxHeight, '20px', 'listProps.css composed into the list root');
  });
  test('upstream list ports: aria set attributes follow option changes; non-virtualized lists scroll the current option into view', async function (assert) {
    const state = new State([
      { label: 'Group A', isGroupLabel: true },
      { label: 'One' },
      { label: 'Two' },
      { label: 'Group B', isGroupLabel: true },
      { label: 'Three' }
    ]);
    const many: EuiSelectableOption[] = Array.from({ length: 30 }, (_, i) => ({ label: `Option ${i}` }));

    await render(
      <template>
        <div class="groups"><EuiSelectable aria-label="Groups" @options={{state.options}} @onChange={{state.onChange}} /></div>
        <div class="many"><EuiSelectable aria-label="Many" @options={{many}} @onChange={{noop}} @height={{100}} @listProps={{hash isVirtualized=false}} /></div>
      </template>
    );

    const aria = () =>
      [...document.querySelectorAll('.groups li.euiSelectableListItem')].map(
        (li) => `${li.getAttribute('aria-posinset')}/${li.getAttribute('aria-setsize')}`
      );
    assert.deepEqual(aria(), ['1/3', '2/3', '3/3'], 'group labels are not counted');
    state.options = [{ label: 'Group B', isGroupLabel: true }, { label: 'Three' }, { label: 'Four' }];
    await rerender();
    assert.deepEqual(aria(), ['1/2', '2/2']);

    const list = q('.many .euiSelectableList__list');
    for (let i = 0; i < 12; i++) await triggerKeyEvent(list, 'keydown', 'ArrowDown');
    const current = q('.many .euiSelectableListItem-isFocused');
    assert.dom(current).includesText('Option 11');
    assert.true(list.scrollTop > 0, 'the list scrolled');
    assert.true(current.getBoundingClientRect().bottom <= list.getBoundingClientRect().bottom + 1, 'the option is visible');
  });
});
