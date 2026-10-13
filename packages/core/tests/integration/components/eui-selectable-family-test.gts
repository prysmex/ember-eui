import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import {
  click,
  fillIn,
  focus,
  render,
  settled,
  triggerEvent,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';

import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiSelectable from '#src/components/eui-selectable.gts';
import EuiSelectableList from '#src/components/eui-selectable-list.gts';
import EuiSelectableListItem from '#src/components/eui-selectable-list-item.gts';
import EuiSelectableMessage from '#src/components/eui-selectable-message.gts';
import EuiSelectableTemplateSitewide from '#src/components/eui-selectable-template-sitewide.gts';
import EuiSuggest from '#src/components/eui-suggest.gts';
import EuiSuggestItem from '#src/components/eui-suggest-item.gts';
import { euiSelectableTemplateSitewideStyles } from '#src/utils/eui/selectable.ts';
import { suggestTypeColors } from '#src/utils/eui/suggest.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiSelectableOption } from '#src/components/eui-selectable.gts';
import type { EuiSelectableTemplateSitewideOption } from '#src/components/eui-selectable-template-sitewide.gts';
import type { EuiSuggestion } from '#src/components/eui-suggest.gts';
import type {
  EuiBorealisHighContrastMode,
  EuiBorealisOverrides
} from '#src/utils/eui/theme.ts';

const lightContext = resolveBorealisTheme('light');
const light = lightContext.euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;
const TRANSPARENT = 'rgba(0, 0, 0, 0)';

function el(root: Element | Document, selector: string) {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function style(root: Element | Document, selector: string, pseudo?: string) {
  return getComputedStyle(el(root, selector), pseudo);
}

/** Normalize any CSS color to the browser's computed `rgb()` form. */
function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

/** Upstream font sizes are rem based; EUI apps set a 14px root (`s`). */
function remPx(px: number) {
  return (px / 14) * parseFloat(getComputedStyle(document.documentElement).fontSize);
}

function finishTransitions() {
  document.getAnimations().forEach((animation) => animation.finish());
}

function close(assert: Assert, actual: number, expected: number, label: string) {
  assert.true(Math.abs(actual - expected) < 0.6, `${label}: ${actual} ≈ ${expected}`);
}

/** The option `<li>` whose label (text `title`) is `label`. */
function option(root: Element | Document, label: string) {
  return el(root, `li.euiSelectableListItem:has(> .euiListItemLayout__content > [title="${label}"])`);
}

function options(): EuiSelectableOption[] {
  return [
    { label: 'Fruits', isGroupLabel: true },
    { label: 'Apple', checked: 'on' },
    { label: 'Banana' },
    { label: 'Cherry', disabled: true },
    { label: 'Vegetables', isGroupLabel: true },
    { label: 'Carrot', checked: 'off' },
    { label: 'Leek', checked: 'mixed' }
  ];
}

class Options {
  @tracked options: EuiSelectableOption[] = options();
  onChange = (next: EuiSelectableOption[]) => (this.options = next);
  get checked() {
    return this.options.filter((o) => o.checked).map((o) => `${o.label}:${o.checked}`);
  }
}

module('Borealis selectable and suggest', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiSelectable/List: flex column root, scroll container, border, padding and heights', async function (assert) {
    class State {
      @tracked bordered = false;
      @tracked paddingSize: 'none' | 's' = 'none';
      @tracked rowHeight = 32;
    }
    const state = new State();
    const opts = new Options();
    const many = Array.from({ length: 10 }, (_, i) => ({ label: `Option ${i}` }));
    await render(
      <template>
        <EuiSelectable
          class="main"
          @options={{opts.options}}
          @onChange={{opts.onChange}}
          @listProps={{hash bordered=state.bordered paddingSize=state.paddingSize rowHeight=state.rowHeight}}
        />
        <EuiSelectable class="many" @options={{many}} />
        <EuiSelectable class="fixed" @options={{many}} @height={{100}} />
        <div style="display:flex;flex-direction:column;height:300px" class="full-wrap">
          <EuiSelectable class="full" @options={{many}} @height="full" />
        </div>
      </template>
    );
    const root = this.element;
    const selectable = style(root, '.main');
    assert.strictEqual(selectable.display, 'flex');
    assert.strictEqual(selectable.flexDirection, 'column');

    const list = el(root, '.main .euiSelectableList');
    const scroller = el(root, '.main .euiSelectableList__list');
    const ul = el(root, '.main ul');
    assert.strictEqual(getComputedStyle(scroller).overflowY, 'auto', 'upstream euiYScroll');
    assert.strictEqual(getComputedStyle(scroller).overflowX, 'hidden');
    assert.strictEqual(getComputedStyle(ul).listStyleType, 'none', 'scoped list reset');
    assert.strictEqual(getComputedStyle(ul).paddingLeft, '0px');
    assert.strictEqual(getComputedStyle(ul).marginTop, '0px');
    assert.strictEqual(getComputedStyle(list).borderTopStyle, 'none');
    // 7 rows: 5 options + 2 group labels (the second one +16px)
    close(assert, scroller.offsetHeight, 7 * 32, 'list height = rows × rowHeight');
    close(assert, option(root, 'Apple').offsetHeight, 32, 'rowHeight 32');
    close(assert, el(root, '.main .euiSelectableList__groupLabel:not(:first-child)').offsetHeight, 48, 'group labels after the first are 16px taller');

    close(assert, el(root, '.many .euiSelectableList__list').offsetHeight, 6.5 * 32, 'shows 6.5 rows of longer lists');
    close(assert, el(root, '.fixed .euiSelectableList__list').offsetHeight, 100, 'numeric height');
    const full = el(root, '.full');
    close(assert, full.offsetHeight, 300, 'full height fills the container');
    assert.strictEqual(getComputedStyle(el(root, '.full .euiSelectableList')).flexGrow, '1');

    state.bordered = true;
    state.paddingSize = 's';
    state.rowHeight = 40;
    await settled();
    assert.strictEqual(el(root, '.main .euiSelectableList'), list, 'root kept');
    assert.strictEqual(el(root, '.main .euiSelectableList__list'), scroller, 'scroller kept');
    const bordered = getComputedStyle(list);
    assert.strictEqual(bordered.borderTopStyle, 'solid');
    assert.strictEqual(bordered.borderTopWidth, light.border.width.thin);
    assert.strictEqual(bordered.borderTopColor, rgb(light.border.color));
    assert.strictEqual(bordered.borderTopLeftRadius, light.border.radius.panel);
    assert.strictEqual(bordered.overflow, 'hidden');
    assert.strictEqual(bordered.paddingTop, light.size.s, 'paddingSize s');
    close(assert, option(root, 'Apple').offsetHeight, 40, 'reactive rowHeight');
  });

  test('EuiSelectableListItem: measured layout, truncation, prepend/append and the indicator', async function (assert) {
    const long = 'A very long option label that certainly does not fit in two hundred pixels';
    await render(
      <template>
        <div style="width:200px">
          <ul role="listbox" aria-label="Items" style="margin:0;padding:0">
            <EuiSelectableListItem class="plain" @title="Plain">Plain</EuiSelectableListItem>
            <EuiSelectableListItem class="long" @title={{long}}>{{long}}</EuiSelectableListItem>
            <EuiSelectableListItem class="decorated" @prepend="#" @append="12">Decorated</EuiSelectableListItem>
            <EuiSelectableListItem class="no-icons" @showIcons={{false}}>No icons</EuiSelectableListItem>
          </ul>
        </div>
      </template>
    );
    const root = this.element;
    const plain = el(root, '.plain');
    const item = getComputedStyle(plain);
    assert.strictEqual(item.display, 'inline-flex');
    assert.strictEqual(item.alignItems, 'center');
    assert.strictEqual(item.width, '200px', 'full width');
    assert.strictEqual(item.paddingLeft, light.size.s);
    assert.strictEqual(item.paddingRight, light.size.s);
    assert.strictEqual(item.borderTopLeftRadius, light.border.radius.control);
    assert.strictEqual(item.color, rgb(light.colors.textParagraph));
    assert.strictEqual(item.listStyleType, 'none');
    assert.strictEqual(item.marginTop, '0px');
    assert.strictEqual(item.backgroundColor, TRANSPARENT);
    assert.strictEqual(item.cursor, 'auto', 'not interactive on its own');
    assert.strictEqual(plain.getAttribute('role'), 'option');

    const content = style(root, '.plain .euiSelectableListItem__content');
    assert.strictEqual(content.display, 'flex');
    assert.strictEqual(content.columnGap, light.size.s);
    const text = style(root, '.plain .euiSelectableListItem__text');
    close(assert, parseFloat(text.fontSize), remPx(14), 'font size s');
    assert.strictEqual(text.paddingTop, '6px', 'xs + xxs text padding');
    assert.strictEqual(text.paddingBottom, '6px');
    assert.strictEqual(text.flexGrow, '1');
    assert.dom('.plain .euiSelectableListItem__text').hasAttribute('title', 'Plain', 'title on the text (upstream)');
    assert.dom('.plain').doesNotHaveAttribute('title');

    const longText = el(root, '.long .euiSelectableListItem__text');
    assert.strictEqual(getComputedStyle(longText).whiteSpace, 'nowrap');
    assert.strictEqual(getComputedStyle(longText).textOverflow, 'ellipsis');
    assert.true(longText.scrollWidth > longText.clientWidth, 'long labels truncate');

    assert.dom('.plain .euiListItemLayout__icon').hasAttribute('data-icon-type', 'empty', 'single selection icon indicator');
    assert.dom('.plain .euiListItemLayout__icon').hasClass('euiSelectableListItem__icon');
    assert.dom('.decorated .euiSelectableListItem__prepend').hasText('#');
    assert.dom('.decorated .euiSelectableListItem__append').hasText('12');
    assert.strictEqual(style(root, '.decorated .euiSelectableListItem__prepend').display, 'flex');
    assert.strictEqual(style(root, '.decorated .euiSelectableListItem__append').columnGap, light.size.s);
    assert.dom('.no-icons .euiSelectableListItem__icon').doesNotExist();
    assert.dom('.plain .euiSelectableListItem__prepend').doesNotExist();
  });

  test('EuiSelectableListItem: checked on/off/mixed, focused, disabled states (single and multiple)', async function (assert) {
    class State {
      @tracked checked: 'on' | 'off' | 'mixed' | undefined = undefined;
      @tracked isFocused = false;
      @tracked disabled = false;
      @tracked single: boolean = true;
    }
    const state = new State();
    await render(
      <template>
        <ul role="listbox" aria-label="Items">
          <EuiSelectableListItem
            class="item"
            @checked={{state.checked}}
            @isFocused={{state.isFocused}}
            @disabled={{state.disabled}}
            @singleSelection={{state.single}}
            @isInteractive={{true}}
          >Item</EuiSelectableListItem>
          <EuiSelectableListItem class="selected-focused" @checked="on" @isFocused={{true}}>Both</EuiSelectableListItem>
          <EuiSelectableListItem class="hidden-icons" @checked="on" @singleSelection={{false}} @showIcons={{false}}>Hidden</EuiSelectableListItem>
        </ul>
      </template>
    );
    const root = this.element;
    const li = el(root, '.item');
    const css = () => getComputedStyle(li);
    const icon = () => el(root, '.item .euiSelectableListItem__icon');
    assert.strictEqual(css().cursor, 'pointer', 'interactive');
    assert.dom(li).hasAria('selected', 'false').doesNotHaveAttribute('aria-checked');
    assert.strictEqual(icon().getAttribute('data-icon-type'), 'empty');

    state.checked = 'on';
    await settled();
    assert.strictEqual(el(root, '.item'), li, 'same element');
    assert.dom(li).hasAria('selected', 'true');
    assert.strictEqual(css().backgroundColor, rgb(light.colors.backgroundBaseInteractiveSelect), 'selected background');
    assert.strictEqual(css().color, rgb(light.colors.textPrimary));
    assert.strictEqual(icon().getAttribute('data-icon-type'), 'check');

    state.checked = 'off';
    await settled();
    assert.strictEqual(icon().getAttribute('data-icon-type'), 'cross');
    assert.dom(li).hasAria('selected', 'true', 'excluded is still a selection');
    assert.dom('.item .euiScreenReaderOnly').includesText('Excluded option.').includesText('To uncheck this option, press Enter.');

    state.checked = 'mixed';
    await settled();
    assert.strictEqual(icon().getAttribute('data-icon-type'), 'minus');
    assert.dom(li).hasAria('checked', 'mixed', 'mixed uses aria-checked').doesNotHaveAttribute('aria-selected');
    assert.dom('.item .euiScreenReaderOnly').includesText('Mixed (indeterminate) option.').includesText('press Enter twice');

    state.checked = undefined;
    state.isFocused = true;
    await settled();
    assert.dom(li).hasClass('euiSelectableListItem-isFocused');
    assert.strictEqual(css().backgroundColor, rgb(light.colors.backgroundBaseInteractiveHover), 'focused background');
    assert.strictEqual(
      style(root, '.selected-focused').backgroundColor,
      rgb(light.colors.backgroundBaseInteractiveSelectHover),
      'selected + focused'
    );

    state.disabled = true;
    await settled();
    assert.dom(li).hasAria('disabled', 'true');
    assert.strictEqual(css().color, rgb(light.colors.textDisabled));
    assert.strictEqual(css().cursor, 'not-allowed');
    assert.strictEqual(css().backgroundColor, TRANSPARENT, 'no focus background while disabled');
    assert.dom('.item .euiSelectableListItem__onFocusBadge').doesNotExist();

    // multiple selection: check box indicator, aria-checked, no selected background
    state.disabled = false;
    state.isFocused = false;
    state.single = false;
    state.checked = 'on';
    await settled();
    assert.strictEqual(el(root, '.item'), li, 'same element across selection modes');
    assert.dom(li).hasAria('checked', 'true').doesNotHaveAttribute('aria-selected');
    const box = el(root, '.item .euiCheckboxControl');
    assert.dom(box).hasClass('euiListItemLayout__checkbox');
    assert.strictEqual(getComputedStyle(box).backgroundColor, rgb(light.colors.primary), 'checked box');
    assert.strictEqual(getComputedStyle(box).width, light.size.base);
    assert.strictEqual(getComputedStyle(box).borderTopLeftRadius, light.border.radius.inline);
    assert.strictEqual(css().backgroundColor, TRANSPARENT, 'the box shows the selection');
    assert.dom('.item .euiCheckboxControl .euiIcon').hasAttribute('data-icon-type', 'check');

    state.checked = 'off';
    await settled();
    finishTransitions();
    assert.strictEqual(getComputedStyle(box).backgroundColor, rgb(light.colors.backgroundFilledDanger), 'excluded box');
    assert.dom('.item .euiCheckboxControl .euiIcon').hasAttribute('data-icon-type', 'cross');
    assert.dom(li).hasAria('checked', 'true');

    state.checked = 'mixed';
    await settled();
    assert.dom('.item .euiCheckboxControl .euiIcon').hasAttribute('data-icon-type', 'stopFill');
    assert.dom(li).hasAria('checked', 'mixed');

    state.checked = undefined;
    await settled();
    finishTransitions();
    assert.strictEqual(getComputedStyle(box).backgroundColor, rgb(light.components.forms.controlBackgroundUnselected), 'unchecked box');
    assert.dom(li).hasAria('checked', 'false');

    state.disabled = true;
    state.checked = 'on';
    await settled();
    assert.strictEqual(getComputedStyle(box).cursor, 'not-allowed', 'disabled box');

    assert.strictEqual(
      style(root, '.hidden-icons').backgroundColor,
      rgb(light.colors.backgroundBaseInteractiveSelect),
      'without indicators, multiple selection shows the selected background'
    );
  });

  test('EuiSelectable: multiple vs single selection semantics and clicks', async function (assert) {
    const multi = new Options();
    const single = new Options();
    const always = new Options();
    const exclusions = new Options();
    const bare = new Options();
    await render(
      <template>
        <EuiSelectable class="multi" @options={{multi.options}} @onChange={{multi.onChange}} />
        <EuiSelectable class="single" @options={{single.options}} @onChange={{single.onChange}} @singleSelection={{true}} />
        <EuiSelectable class="always" @options={{always.options}} @onChange={{always.onChange}} @singleSelection="always" />
        <EuiSelectable class="exclusions" @options={{exclusions.options}} @onChange={{exclusions.onChange}} @allowExclusions={{true}} />
        <EuiSelectableList class="bare" @options={{bare.options}} @onOptionClick={{bare.onChange}} />
      </template>
    );
    const root = this.element;
    const m = el(root, '.multi');
    assert.dom('ul', m).hasAttribute('role', 'listbox').hasAttribute('aria-multiselectable', 'true').hasAttribute('tabindex', '0');
    assert.dom(option(m, 'Apple')).hasAria('checked', 'true').hasAria('posinset', '1').hasAria('setsize', '5');
    assert.dom(option(m, 'Banana')).hasAria('checked', 'false').hasAria('posinset', '2');
    assert.dom(option(m, 'Carrot')).hasAria('posinset', '4', 'group labels are not counted');
    assert.dom(option(m, 'Leek')).hasAria('checked', 'mixed');
    assert.dom('.euiSelectableListItem[aria-selected]', m).doesNotExist();
    assert.dom('.euiCheckboxControl', m).exists({ count: 5 });
    assert.dom('.euiSelectableList__groupLabel', m).hasAttribute('role', 'presentation');

    await click(option(m, 'Banana'));
    assert.deepEqual(multi.checked, ['Apple:on', 'Banana:on', 'Carrot:off', 'Leek:mixed']);
    await click(option(m, 'Leek'));
    assert.deepEqual(multi.checked, ['Apple:on', 'Banana:on', 'Carrot:off', 'Leek:on'], 'mixed → on');
    await click(option(m, 'Carrot'));
    assert.deepEqual(multi.checked, ['Apple:on', 'Banana:on', 'Leek:on'], 'off → unchecked');
    await click(option(m, 'Cherry'));
    assert.deepEqual(multi.checked, ['Apple:on', 'Banana:on', 'Leek:on'], 'disabled does nothing');

    const s = el(root, '.single');
    assert.dom('ul', s).doesNotHaveAttribute('aria-multiselectable');
    assert.dom(option(s, 'Apple')).hasAria('selected', 'true').doesNotHaveAttribute('aria-checked');
    assert.dom(option(s, 'Banana')).hasAria('selected', 'false');
    assert.dom('.euiCheckboxControl', s).doesNotExist();
    assert.dom('.euiListItemLayout__icon', s).exists({ count: 5 });
    assert.strictEqual(getComputedStyle(option(s, 'Apple')).backgroundColor, rgb(light.colors.backgroundBaseInteractiveSelect));
    await click(option(s, 'Banana'));
    assert.deepEqual(single.checked, ['Banana:on'], 'single selection unchecks the others');
    await click(option(s, 'Banana'));
    assert.deepEqual(single.checked, [], 'and can uncheck');

    const a = el(root, '.always');
    await click(option(a, 'Banana'));
    await click(option(a, 'Banana'));
    assert.deepEqual(always.checked, ['Banana:on'], "'always' keeps one");

    // upstream EuiSelectableList on its own: undefined singleSelection renders
    // single-style options in a multiselectable listbox
    const b = el(root, '.bare');
    assert.dom('ul', b).hasAttribute('aria-multiselectable', 'true');
    assert.dom(option(b, 'Apple')).hasAria('selected', 'true');
    await click(option(b, 'Banana'));
    assert.deepEqual(bare.checked, ['Apple:on', 'Banana:on', 'Carrot:off', 'Leek:mixed']);

    const x = el(root, '.exclusions');
    await click(option(x, 'Apple'));
    assert.deepEqual(exclusions.checked, ['Apple:off', 'Carrot:off', 'Leek:mixed'], 'on → off with exclusions');
    assert.dom(option(x, 'Banana').querySelector('.euiScreenReaderOnly')!).includesText('To check this option, press Enter.');
    assert.dom(option(x, 'Leek').querySelector('.euiScreenReaderOnly')!).includesText('To exclude this option for all, press Enter twice.');
  });

  test('EuiSelectable keyboard: arrows skip labels/disabled, Enter and Space toggle, focus picks the checked option', async function (assert) {
    const plain = new Options();
    const search = new Options();
    await render(
      <template>
        <EuiSelectable class="plain" @options={{plain.options}} @onChange={{plain.onChange}} />
        <EuiSelectable class="search" @options={{search.options}} @onChange={{search.onChange}} @searchable={{true}} />
      </template>
    );
    const root = this.element;
    const p = el(root, '.plain');
    await focus(el(p, 'ul'));
    assert.dom(option(p, 'Apple')).hasClass('euiSelectableListItem-isFocused', 'focus starts on the first checked option');
    await triggerKeyEvent(el(p, 'ul'), 'keydown', 'ArrowDown');
    assert.dom(option(p, 'Banana')).hasClass('euiSelectableListItem-isFocused');
    await triggerKeyEvent(el(p, 'ul'), 'keydown', 'ArrowDown');
    assert.dom(option(p, 'Carrot')).hasClass('euiSelectableListItem-isFocused', 'disabled and group labels are skipped');
    await triggerKeyEvent(el(p, 'ul'), 'keydown', 'Shift');
    assert.dom(option(p, 'Carrot')).hasClass('euiSelectableListItem-isFocused', 'modifier keys keep the current option');
    await triggerKeyEvent(el(p, 'ul'), 'keydown', ' ');
    assert.deepEqual(plain.checked, ['Apple:on', 'Leek:mixed'], 'Space toggles in a plain list');
    await triggerKeyEvent(el(p, 'ul'), 'keydown', 'ArrowDown');
    await triggerKeyEvent(el(p, 'ul'), 'keydown', 'ArrowDown');
    assert.dom(option(p, 'Apple')).hasClass('euiSelectableListItem-isFocused', 'wraps around');
    await triggerKeyEvent(el(p, 'ul'), 'keydown', 'ArrowUp');
    assert.dom(option(p, 'Leek')).hasClass('euiSelectableListItem-isFocused', 'and back');
    await triggerKeyEvent(el(p, 'ul'), 'keydown', 'Enter');
    assert.deepEqual(plain.checked, ['Apple:on', 'Leek:on'], 'Enter toggles');

    const s = el(root, '.search');
    const input = el(s, 'input');
    await focus(input);
    // upstream: focusing the search makes no option current
    assert.dom('.euiSelectableListItem-isFocused', s).doesNotExist('focusing the search picks nothing');
    assert.dom(input).doesNotHaveAria('activedescendant');
    await triggerKeyEvent(input, 'keydown', 'ArrowDown');
    assert.dom(option(s, 'Apple')).hasClass('euiSelectableListItem-isFocused', 'the first arrow starts at the top');
    await triggerKeyEvent(input, 'keydown', 'ArrowDown');
    const active = el(s, '.euiSelectableListItem-isFocused');
    assert.dom(input).hasAria('activedescendant', active.id);
    await triggerKeyEvent(input, 'keydown', ' ');
    assert.deepEqual(search.checked, ['Apple:on', 'Carrot:off', 'Leek:mixed'], 'Space types in the search');
    await triggerKeyEvent(input, 'keydown', 'Enter');
    assert.deepEqual(search.checked, ['Apple:on', 'Banana:on', 'Carrot:off', 'Leek:mixed'], 'Enter toggles the current option');
  });

  test('EuiSelectable search: filtering, EuiHighlight marks, compressed field and aria', async function (assert) {
    const opts = new Options();
    const searches: string[] = [];
    const onSearch = (value: string) => searches.push(value);
    await render(
      <template>
        <EuiSelectable @options={{opts.options}} @onChange={{opts.onChange}} @searchable={{true}} @searchProps={{hash onSearch=onSearch}} />
      </template>
    );
    const root = this.element;
    const input = el(root, 'input.euiSelectableSearch');
    const listId = el(root, 'ul').id;
    assert.dom(input).hasAttribute('role', 'combobox').hasAria('controls', listId).hasAria('owns', listId).hasAria('autocomplete', 'list').hasAria('haspopup', 'listbox');
    const describedBy = input.getAttribute('aria-describedby')!;
    assert.dom(`#${describedBy}`).includesText('Use the Up and Down arrow keys');
    assert.strictEqual(getComputedStyle(el(root, `#${describedBy}`).parentElement!).position, 'absolute', 'instructions are screen reader only');
    assert.dom('ul').hasAria('label', 'Filter options').doesNotHaveAttribute('aria-multiselectable');
    assert.strictEqual(getComputedStyle(input).height, '32px', 'compressed search by default (upstream)');

    await fillIn(input, 'an');
    assert.deepEqual(searches, ['an']);
    assert.dom('.euiSelectableListItem').exists({ count: 1 });
    assert.dom('.euiSelectableListItem mark').hasText('an');
    assert.dom('.euiSelectableListItem .euiSelectableListItem__text').hasText(/Banana/);
    assert.notStrictEqual(style(root, '.euiSelectableListItem mark').backgroundColor, TRANSPARENT, 'upstream mark styles');
    assert.dom('.euiSelectableListItem .euiScreenReaderOnly').includesText('To check this option, press Enter.', 'searchable instructions');

    await fillIn(input, 'zzz');
    assert.dom('.euiSelectableMessage').hasText("zzz doesn't match any options");
    assert.dom('.euiSelectableMessage strong').hasText('zzz');
    assert.dom(input).doesNotHaveAria('controls', 'no list to control');
  });

  test('EuiSelectableMessage: upstream EuiText xs subdued + message styles; loading/empty/no matches', async function (assert) {
    class State {
      @tracked bordered = false;
    }
    const state = new State();
    const none: EuiSelectableOption[] = [];
    await render(
      <template>
        <EuiSelectableMessage class="standalone" @bordered={{state.bordered}}><p>Message</p></EuiSelectableMessage>
        <EuiSelectable class="loading" @options={{none}} @isLoading={{true}} />
        <EuiSelectable class="empty" @options={{none}} @listProps={{hash bordered=true}} />
        <EuiSelectable class="custom" @options={{none}} @emptyMessage="Nothing here" />
      </template>
    );
    const root = this.element;
    const message = el(root, '.standalone');
    const css = getComputedStyle(message);
    assert.strictEqual(css.display, 'flex');
    assert.strictEqual(css.flexDirection, 'column');
    assert.strictEqual(css.justifyContent, 'center');
    assert.strictEqual(css.alignItems, 'center');
    assert.strictEqual(css.textAlign, 'center');
    assert.strictEqual(css.paddingTop, light.size.s);
    assert.strictEqual(css.overflowWrap, 'break-word');
    assert.strictEqual(css.color, rgb(light.colors.textSubdued));
    close(assert, parseFloat(css.fontSize), remPx(12), 'xs text');
    assert.strictEqual(css.borderTopStyle, 'none');
    assert.strictEqual(getComputedStyle(el(root, '.standalone p')).marginBottom, '0px');

    state.bordered = true;
    await settled();
    assert.strictEqual(el(root, '.standalone'), message, 'same element');
    assert.strictEqual(getComputedStyle(message).borderTopStyle, 'solid');
    assert.strictEqual(getComputedStyle(message).borderTopColor, rgb(light.border.color));
    assert.strictEqual(getComputedStyle(message).overflow, 'hidden');

    assert.dom('.loading .euiSelectableMessage').includesText('Loading options');
    assert.dom('.loading .euiSelectableMessage .euiBorealisLoadingSpinner').exists();
    assert.dom('.loading .euiSelectableMessage').hasAttribute('id', /_messageContent$/);
    assert.dom('.empty .euiSelectableMessage').hasText('No options available');
    assert.strictEqual(style(root, '.empty .euiSelectableMessage').borderTopStyle, 'solid', 'bordered list → bordered message');
    assert.dom('.custom .euiSelectableMessage').hasText('Nothing here');
  });

  test('group labels and focus badges', async function (assert) {
    class State {
      @tracked badge: boolean | { text?: string; iconSide?: 'left' | 'right' } = false;
    }
    const state = new State();
    const opts = new Options();
    await render(
      <template>
        <EuiSelectable @options={{opts.options}} @onChange={{opts.onChange}} @singleSelection={{true}} @listProps={{hash onFocusBadge=state.badge}} />
      </template>
    );
    const root = this.element;
    const [first, second] = [...root.querySelectorAll<HTMLElement>('.euiSelectableList__groupLabel')];
    const label = getComputedStyle(first!);
    assert.strictEqual(label.display, 'flex');
    assert.strictEqual(label.paddingLeft, light.size.xs);
    assert.strictEqual(label.paddingTop, light.size.s);
    assert.strictEqual(label.fontWeight, String(light.font.weight.bold), 'euiTitle xxxs');
    assert.strictEqual(label.color, rgb(light.colors.textHeading));
    const next = getComputedStyle(second!);
    assert.strictEqual(next.paddingTop, '24px', 'later labels leave room for the divider');
    const divider = getComputedStyle(second!, '::before');
    assert.strictEqual(divider.borderTopStyle, 'solid');
    assert.strictEqual(divider.borderTopColor, rgb(light.components.selectableListItemBorderColor));
    assert.strictEqual(getComputedStyle(first!, '::before').content, 'none', 'no divider before the first');

    await focus(el(root, 'ul'));
    assert.dom('.euiSelectableListItem__onFocusBadge').doesNotExist('no badge by default (upstream)');
    state.badge = true;
    await settled();
    assert.dom('.euiSelectableListItem-isFocused .euiSelectableListItem__onFocusBadge').exists().hasAria('hidden', 'true');
    state.badge = { text: 'Go to', iconSide: 'right' };
    await settled();
    assert.dom('.euiSelectableListItem__onFocusBadge').hasText('Go to');
    assert.strictEqual(
      el(root, '.euiSelectableListItem__onFocusBadge').lastElementChild?.getAttribute('data-icon-type') ??
        el(root, '.euiSelectableListItem__onFocusBadge .euiIcon').getAttribute('data-icon-type'),
      'return'
    );
  });

  test('EuiSelectableTemplateSitewide: popover, row height, meta styles, footer and messages', async function (assert) {
    const items: EuiSelectableTemplateSitewideOption[] = [
      {
        label: 'Dashboards',
        icon: { type: 'dashboardApp' },
        meta: [{ text: 'Analytics', type: 'application' }, { text: 'Space', type: 'custom' }]
      },
      { label: 'Revenue', avatar: { name: 'Sales' }, meta: [{ text: 'Article', type: 'article' }] }
    ];
    class State {
      @tracked options = items;
      @tracked isLoading = false;
    }
    const state = new State();
    await render(
      <template>
        <EuiSelectableTemplateSitewide @options={{state.options}} @isLoading={{state.isLoading}}>
          <:popoverFooter><span class="footer">Tip</span></:popoverFooter>
        </EuiSelectableTemplateSitewide>
      </template>
    );
    const root = this.element;
    assert.strictEqual(style(root, '.euiSelectableTemplateSitewide').display, 'block', 'upstream root composed through @css');
    await focus('input.euiSelectableTemplateSitewide__search');
    await waitUntil(() => document.querySelector('.euiSelectableTemplateSitewide__listItem'));
    const body = document.body;
    const panel = el(body, '.euiPopover__panel');
    assert.strictEqual(getComputedStyle(panel).paddingTop, light.size.s, 'panel padding s');
    const input = el(root, 'input.euiSelectableTemplateSitewide__search');
    const inputBox = input.getBoundingClientRect();
    const panelBox = panel.getBoundingClientRect();
    assert.true(panelBox.top >= inputBox.bottom, 'below the search');
    close(assert, panelBox.left + panelBox.width / 2, inputBox.left + inputBox.width / 2, 'centered (downCenter)');
    close(assert, el(body, '.euiSelectableTemplateSitewide__popover').offsetWidth, Math.min(600, panel.offsetWidth - 16), 'popover width 600');

    const item = el(body, '.euiSelectableTemplateSitewide__listItem');
    close(assert, item.offsetHeight, 52, 'rowHeight 52');
    assert.dom(item).hasAria('selected', 'false', 'single selection');
    assert.dom('.euiSelectableTemplateSitewide__listItem .euiListItemLayout__icon', body).doesNotExist('showIcons false');
    assert.dom('.euiSelectableListItem__text', item).hasAttribute('title', 'Dashboards • Analytics Space');

    const metas = getComputedStyle(el(body, '.euiSelectableTemplateSitewide__optionMetasList'));
    assert.strictEqual(metas.display, 'block');
    assert.strictEqual(metas.color, rgb(light.colors.textSubdued));
    close(assert, parseFloat(metas.fontSize), remPx(12), 'meta xs');
    const app = el(body, '.euiSelectableTemplateSitewide__optionMeta--application');
    const expected = euiSelectableTemplateSitewideStyles({ ...lightContext, colorMode: 'LIGHT' } as never).metaTypes.application.styles;
    const color = /color:([^;]+);/.exec(expected)![1]!;
    assert.strictEqual(getComputedStyle(app).color, rgb(color), 'application color (high contrast vis 1)');
    assert.strictEqual(getComputedStyle(app).fontWeight, String(light.font.weight.medium));
    const bullet = getComputedStyle(app, '::after');
    assert.strictEqual(bullet.content, '"•"', 'bullet between metas');
    assert.strictEqual(bullet.marginLeft, light.size.xs);
    assert.strictEqual(bullet.color, rgb(light.colors.textSubdued));
    const custom = el(body, '.euiSelectableTemplateSitewide__optionMeta--custom');
    assert.strictEqual(getComputedStyle(custom).fontWeight, '400', 'custom types are plain');
    assert.strictEqual(getComputedStyle(custom, '::after').content, 'none', 'no bullet after the last');

    assert.dom('.euiPopoverFooter .footer', body).exists();
    assert.strictEqual(style(body, '.euiPopoverFooter').paddingTop, light.size.s, 'footer padding s');

    state.options = [];
    await settled();
    const empty = el(body, '.euiSelectableTemplateSitewide__popover .euiSelectableMessage');
    assert.dom(empty).hasText('No results available');
    close(assert, empty.offsetHeight, 300, 'empty message min height');

    state.isLoading = true;
    await settled();
    const loading = el(body, '.euiSelectableTemplateSitewide__popover .euiSelectableMessage');
    assert.dom(loading).includesText('Loading results');
    assert.dom('.euiBorealisLoadingSpinner', loading).exists();
    assert.true(loading.offsetHeight >= 299, 'loading message min height');
  });

  test('EuiSuggestItem: measured type, label widths, description truncation and wrapping', async function (assert) {
    class State {
      @tracked labelWidth: '30' | '50' | '70' = '30';
      @tracked descriptionDisplay: 'truncate' | 'wrap' = 'truncate';
      @tracked color = 'tint4';
    }
    const state = new State();
    const type = { iconType: 'kqlValue', color: 'tint2' };
    const longDescription = 'A long description that will not fit into the remaining space of the row';
    await render(
      <template>
        <div style="width:400px">
          <EuiSuggestItem class="plain" @type={{type}} @label="Label only" />
          <EuiSuggestItem
            class="full"
            @type={{hash iconType="kqlField" color=state.color}}
            @label="field.name"
            @description={{longDescription}}
            @labelWidth={{state.labelWidth}}
            @descriptionDisplay={{state.descriptionDisplay}}
          />
        </div>
      </template>
    );
    const root = this.element;
    const plain = getComputedStyle(el(root, '.plain'));
    assert.strictEqual(plain.display, 'flex');
    assert.strictEqual(plain.alignItems, 'flex-start');
    close(assert, parseFloat(plain.fontSize), remPx(12), 'xs');
    assert.strictEqual(plain.lineHeight, light.size.base);
    assert.strictEqual(plain.color, rgb(light.colors.textParagraph));
    const typeCss = style(root, '.plain .euiSuggestItem__type');
    assert.strictEqual(typeCss.width, light.size.xl);
    assert.strictEqual(typeCss.minHeight, light.size.xl);
    assert.strictEqual(typeCss.paddingTop, light.size.s);
    assert.strictEqual(typeCss.justifyContent, 'center');
    const tint2 = suggestTypeColors({ ...lightContext, colorMode: 'LIGHT' } as never, 'tint2');
    assert.strictEqual(typeCss.backgroundColor, rgb(tint2.backgroundColor));
    assert.strictEqual(typeCss.color, rgb(tint2.color));
    const label = style(root, '.plain .euiSuggestItem__label');
    assert.true(label.fontFamily.includes('Roboto Mono'), 'code font');
    assert.strictEqual(label.paddingLeft, light.size.s);
    assert.strictEqual(label.flexBasis, 'auto', 'no description: the label expands');

    const full = el(root, '.full');
    const width = full.offsetWidth;
    const fullLabel = el(root, '.full .euiSuggestItem__label');
    close(assert, fullLabel.offsetWidth, width * 0.3 - 16, 'labelWidth 30');
    const description = el(root, '.full .euiSuggestItem__description');
    assert.strictEqual(getComputedStyle(description).color, rgb(light.colors.textSubdued));
    assert.strictEqual(getComputedStyle(description).paddingTop, '9px', 's + 1px');
    assert.strictEqual(getComputedStyle(description).whiteSpace, 'nowrap');
    assert.strictEqual(getComputedStyle(description).textOverflow, 'ellipsis');
    assert.true(description.scrollWidth > description.clientWidth, 'truncated');
    assert.dom(description).hasAttribute('title', longDescription);
    const tint4 = suggestTypeColors({ ...lightContext, colorMode: 'LIGHT' } as never, 'tint4');
    assert.strictEqual(style(root, '.full .euiSuggestItem__type').backgroundColor, rgb(tint4.backgroundColor));

    state.labelWidth = '70';
    state.descriptionDisplay = 'wrap';
    state.color = 'tint10';
    await settled();
    assert.strictEqual(el(root, '.full'), full, 'same element');
    close(assert, el(root, '.full .euiSuggestItem__label').offsetWidth, width * 0.7 - 16, 'reactive labelWidth');
    assert.strictEqual(getComputedStyle(description).whiteSpace, 'normal', 'wrap');
    assert.dom(description).hasClass('euiSuggestItem__description--wrap');
    const tint10 = suggestTypeColors({ ...lightContext, colorMode: 'LIGHT' } as never, 'tint10');
    assert.strictEqual(style(root, '.full .euiSuggestItem__type').backgroundColor, rgb(tint10.backgroundColor), 'tint10 = dark shade');
    assert.true(description.offsetHeight > 20, 'wrapped onto several lines');
  });

  test('EuiSuggest: statuses with icons/tooltips/spinner, clickable items and the popover', async function (assert) {
    class State {
      @tracked status: 'unsaved' | 'saved' | 'loading' | 'unchanged' = 'unsaved';
    }
    const state = new State();
    const suggestions: EuiSuggestion[] = [
      { type: { iconType: 'kqlField', color: 'tint4' }, label: 'Field sample', description: 'This is the description' },
      { type: { iconType: 'search', color: 'tint10' }, label: 'Saved query' }
    ];
    const clicked: string[] = [];
    const onItemClick = (item: EuiSuggestion) => clicked.push(item.label);
    await render(
      <template>
        <EuiSuggest @suggestions={{suggestions}} @status={{state.status}} @onItemClick={{onItemClick}} aria-label="Search" />
      </template>
    );
    const root = this.element;
    const input = el(root, 'input');
    assert.dom('.euiSuggest').exists();
    assert.dom('.euiSuggestInput__statusIcon').hasAttribute('data-icon-type', 'dot');
    await triggerEvent(el(root, '.euiSuggestInput__statusIcon').closest('.euiToolTipAnchor')!, 'mouseover');
    await waitUntil(() => document.querySelector('.euiToolTipPopover'), { timeout: 3000 });
    assert.dom('.euiToolTipPopover', document.body).hasText('Changes have not been saved.');

    state.status = 'saved';
    await settled();
    assert.strictEqual(el(root, 'input'), input, 'same input');
    assert.dom('.euiSuggestInput__statusIcon').hasAttribute('data-icon-type', 'checkCircleFill');

    state.status = 'loading';
    await settled();
    assert.dom('.euiSuggestInput__statusIcon').doesNotExist();
    assert.dom('.euiBorealisLoadingSpinner').exists();

    state.status = 'unchanged';
    await settled();
    assert.dom('.euiSuggestInput__statusIcon').doesNotExist();
    assert.dom('.euiBorealisLoadingSpinner').doesNotExist();

    await fillIn(el(root, 'input'), 'sa');
    await waitUntil(() => document.querySelector('.euiSuggestItem'));
    const button = el(document.body, 'button.euiSuggestItem');
    assert.dom(button).hasAttribute('type', 'button');
    const css = getComputedStyle(button);
    assert.strictEqual(css.textAlign, 'start');
    assert.strictEqual(css.borderTopStyle, 'none', 'button reset');
    assert.strictEqual(css.backgroundColor, TRANSPARENT);
    assert.strictEqual(button.offsetWidth, button.parentElement!.clientWidth, 'full width');
    await focus(button);
    assert.strictEqual(getComputedStyle(button).backgroundColor, rgb(light.colors.backgroundBaseInteractiveHover), 'focus background');
    assert.strictEqual(getComputedStyle(el(button, '.euiSuggestItem__label')).textDecorationLine, 'underline');
    await click(button);
    assert.deepEqual(clicked, ['Field sample']);
  });

  test('light/dark follow the nearest provider with sibling isolation', async function (assert) {
    class State {
      @tracked mode: 'light' | 'dark' = 'dark';
    }
    const state = new State();
    const opts = new Options();
    const type = { iconType: 'kqlField', color: 'tint4' };
    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}}>
          <EuiSelectable class="dark-select" @options={{opts.options}} @singleSelection={{true}} />
          <EuiSelectableMessage class="dark-message">Message</EuiSelectableMessage>
          <EuiSuggestItem class="dark-suggest" @type={{type}} @label="Label" />
          <EuiEmotionProvider @colorMode="light">
            <EuiSelectableMessage class="nested-message">Nested</EuiSelectableMessage>
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <EuiSelectable class="light-select" @options={{opts.options}} @singleSelection={{true}} />
        </EuiEmotionProvider>
      </template>
    );
    const root = this.element;
    const darkApple = option(el(root, '.dark-select'), 'Apple');
    assert.strictEqual(getComputedStyle(darkApple).backgroundColor, rgb(dark.colors.backgroundBaseInteractiveSelect));
    assert.strictEqual(getComputedStyle(darkApple).color, rgb(dark.colors.textPrimary));
    assert.strictEqual(getComputedStyle(option(el(root, '.dark-select'), 'Banana')).color, rgb(dark.colors.textParagraph));
    assert.strictEqual(style(root, '.dark-message').color, rgb(dark.colors.textSubdued));
    const darkTint = suggestTypeColors({ ...resolveBorealisTheme('dark'), colorMode: 'DARK' } as never, 'tint4');
    assert.strictEqual(style(root, '.dark-suggest .euiSuggestItem__type').backgroundColor, rgb(darkTint.backgroundColor), 'dark shade of the tint');
    assert.strictEqual(style(root, '.nested-message').color, rgb(light.colors.textSubdued), 'nested light');
    assert.strictEqual(
      getComputedStyle(option(el(root, '.light-select'), 'Apple')).backgroundColor,
      rgb(light.colors.backgroundBaseInteractiveSelect),
      'sibling light'
    );
    assert.notStrictEqual(rgb(dark.colors.backgroundBaseInteractiveSelect), rgb(light.colors.backgroundBaseInteractiveSelect));

    state.mode = 'light';
    await settled();
    assert.strictEqual(option(el(root, '.dark-select'), 'Apple'), darkApple, 'same element');
    assert.strictEqual(getComputedStyle(darkApple).backgroundColor, rgb(light.colors.backgroundBaseInteractiveSelect), 'switched to light');
    const lightTint = suggestTypeColors({ ...lightContext, colorMode: 'LIGHT' } as never, 'tint4');
    assert.strictEqual(style(root, '.dark-suggest .euiSuggestItem__type').backgroundColor, rgb(lightTint.backgroundColor));
  });

  test('native token overrides (JS objects) and high contrast', async function (assert) {
    class State {
      @tracked overrides: EuiBorealisOverrides = {};
      @tracked contrast: EuiBorealisHighContrastMode = false;
    }
    const state = new State();
    const opts = new Options();
    await render(
      <template>
        <EuiEmotionProvider @borealisOverrides={{state.overrides}} @highContrastMode={{state.contrast}}>
          <EuiSelectable class="inside" @options={{opts.options}} @singleSelection={{true}} @listProps={{hash bordered=true}} />
        </EuiEmotionProvider>
        <EuiSelectable class="outside" @options={{opts.options}} @singleSelection={{true}} />
      </template>
    );
    const root = this.element;
    state.overrides = {
      colors: { LIGHT: { backgroundBaseInteractiveSelect: '#ffeecc', textPrimary: '#663399' } },
      size: { s: '10px' }
    };
    await settled();
    const overridden = resolveBorealisTheme('light', state.overrides).euiTheme;
    const apple = option(el(root, '.inside'), 'Apple');
    assert.strictEqual(getComputedStyle(apple).backgroundColor, rgb('#ffeecc'), 'selected background override');
    assert.strictEqual(getComputedStyle(apple).color, rgb(overridden.colors.textPrimary));
    assert.strictEqual(getComputedStyle(apple).paddingLeft, '10px', 'size override');
    assert.strictEqual(style(root, '.inside .euiSelectableList__groupLabel').paddingTop, '10px');
    assert.strictEqual(getComputedStyle(option(el(root, '.outside'), 'Apple')).backgroundColor, rgb(light.colors.backgroundBaseInteractiveSelect), 'outside is isolated');

    state.overrides = {};
    state.contrast = 'preferred';
    await settled();
    const hc = resolveBorealisTheme('light', {}, 'preferred').euiTheme;
    const selected = getComputedStyle(option(el(root, '.inside'), 'Apple'));
    assert.strictEqual(selected.outlineStyle, 'solid', 'high contrast selected outline');
    assert.strictEqual(selected.outlineColor, rgb(hc.colors.borderStrongPrimary));
    assert.strictEqual(selected.outlineWidth, hc.border.width.thin);
    assert.strictEqual(getComputedStyle(option(el(root, '.inside'), 'Banana')).outlineStyle, 'none');
    await focus(el(root, '.inside ul'));
    await triggerKeyEvent(el(root, '.inside ul'), 'keydown', 'ArrowDown');
    const focused = getComputedStyle(option(el(root, '.inside'), 'Banana'));
    assert.strictEqual(focused.textDecorationLine, 'underline', 'high contrast focused underline');
  });

  test('RTL: indicator, prepend and append order, label padding and suggest layout are logical', async function (assert) {
    const prepended: EuiSelectableOption[] = [{ label: 'פריט', prepend: '#', append: '12', checked: 'on' }];
    const type = { iconType: 'kqlField', color: 'tint1' };
    await render(
      <template>
        <div dir="rtl" style="width:300px">
          <EuiSelectable class="list" @options={{prepended}} />
          <EuiSuggestItem class="suggest" @type={{type}} @label="label" @description="description" />
        </div>
      </template>
    );
    const root = this.element;
    const box = (selector: string) => el(root, selector).getBoundingClientRect();
    const indicator = box('.list .euiCheckboxControl');
    const prepend = box('.list .euiSelectableListItem__prepend');
    const text = box('.list .euiSelectableListItem__text');
    const append = box('.list .euiSelectableListItem__append');
    assert.true(indicator.left > prepend.left, 'indicator at the inline start (right)');
    assert.true(prepend.left > text.left, 'prepend before the text');
    assert.true(append.right <= text.left + 0.5, 'append at the inline end (left)');
    const typeBox = box('.suggest .euiSuggestItem__type');
    const labelBox = box('.suggest .euiSuggestItem__label');
    assert.true(typeBox.left > labelBox.left, 'suggest type icon at the inline start');
    assert.strictEqual(style(root, '.suggest .euiSuggestItem__label').textAlign, 'start');
  });
});
