import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  fillIn,
  render,
  settled,
  triggerEvent,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiBadge from '#src/components/eui-badge.gts';
import EuiComboBox from '#src/components/eui-combo-box.gts';
import EuiComboBoxPill from '#src/components/eui-combo-box-pill.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import {
  euiFontSize,
  euiFormVariables
} from '#src/utils/eui/styles.generated.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';
import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type { EuiBorealisOverrides } from '#src/utils/eui/theme.ts';

const lightContext = resolveBorealisTheme('light');
const darkContext = resolveBorealisTheme('dark');
const light = lightContext.euiTheme;
const dark = darkContext.euiTheme;
const lightForm = euiFormVariables(lightContext);
const darkForm = euiFormVariables(darkContext);

/** Normalize any CSS color to the browser's computed `rgb()` form. */
function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

/** The computed px value of a CSS length (e.g. rem based). */
function px(value: string) {
  const probe = document.createElement('span');
  probe.style.fontSize = value;
  document.body.appendChild(probe);
  const size = getComputedStyle(probe).fontSize;
  probe.remove();
  return size;
}

const inset = (color: string) => `${rgb(color)} 0px 0px 0px 1px inset`;

function q<T extends Element = HTMLElement>(
  selector: string,
  root: ParentNode = document
) {
  const element = root.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

const css = (element: Element, pseudo?: string) =>
  getComputedStyle(element, pseudo);

/**
 * Rendered size in CSS px. The test container is scaled; the options list
 * renders in the dropdown wormhole outside it, at its real size.
 */
function box(element: Element) {
  const container = document.querySelector<HTMLElement>('#ember-testing')!;
  const scale = container.contains(element)
    ? container.getBoundingClientRect().width / container.offsetWidth
    : 1;
  const rect = element.getBoundingClientRect();
  return {
    width: Math.round((rect.width / scale) * 100) / 100,
    height: Math.round((rect.height / scale) * 100) / 100,
    top: rect.top / scale,
    bottom: rect.bottom / scale,
    left: rect.left / scale
  };
}

const FRUITS = ['Apple', 'Banana', 'Cherry', 'Durian'];
const ROW = '.euiComboBoxOptionsList .euiComboBoxOption[role="option"]';
const INPUT =
  'input.euiComboBox__input:not(.fake-input-for-html-form-validity)';
const noop = () => {};

const inputOf = (scope: string) => q<HTMLInputElement>(`${scope} ${INPUT}`);
const wrapOf = (scope: string) => q(`${scope} .euiComboBox__inputWrap`);
const rows = () => [...document.querySelectorAll<HTMLElement>(ROW)];
const panel = () => q('.ember-basic-dropdown-content');

async function open(scope = '') {
  await click(scope ? `${scope} ${INPUT}` : INPUT);
  await waitUntil(() => document.querySelector('.ember-basic-dropdown-content'));
  await settled();
}

function finishAnimations() {
  document.getAnimations().forEach((animation) => animation.finish());
}

class Selection {
  @tracked selected: unknown[] = [];
  onChange = (selected: unknown[]) => {
    this.selected = selected;
  };
}

module('Integration | Component | Borealis combo box family', function (hooks) {
  setupRenderingTest(hooks);

  test('root and input wrap: form width, upstream control box, pills and icons', async function (assert) {
    const selected = ['Apple', 'Banana'];
    const many = ['Apple', 'Banana', 'Cherry', 'Durian', 'Apple pie', 'Banana bread', 'Cherry tart', 'Durian ice'];

    await render(
      <template>
        <div style="width: 800px">
          <div data-c="multi"><EuiComboBox @options={{FRUITS}} @selectedOptions={{selected}} @onChange={{noop}} as |o|>{{o}}</EuiComboBox></div>
          <div data-c="compressed"><EuiComboBox @compressed={{true}} @options={{FRUITS}} @selectedOptions={{selected}} @onChange={{noop}} as |o|>{{o}}</EuiComboBox></div>
          <div data-c="full"><EuiComboBox @fullWidth={{true}} @options={{FRUITS}} @onChange={{noop}} as |o|>{{o}}</EuiComboBox></div>
          <div data-c="single"><EuiComboBox @singleSelection={{true}} @options={{FRUITS}} @selectedOptions={{selected}} @onChange={{noop}} as |o|>{{o}}</EuiComboBox></div>
          <div data-c="many"><EuiComboBox @options={{many}} @selectedOptions={{many}} @onChange={{noop}} as |o|>{{o}}</EuiComboBox></div>
        </div>
      </template>
    );

    const root = q('[data-c="multi"] .euiComboBox');
    assert.strictEqual(css(root).position, 'relative');
    assert.strictEqual(css(root).maxWidth, '400px', 'upstream form max width');
    assert.strictEqual(box(root).width, 400);
    assert.strictEqual(box(q('[data-c="full"] .euiComboBox')).width, 800, '@fullWidth');

    const wrap = wrapOf('[data-c="multi"]');
    assert.strictEqual(wrap.tagName, 'DIV', 'a div like upstream (was a <ul>)');
    const w = css(wrap);
    assert.strictEqual(w.display, 'flex');
    assert.strictEqual(w.flexWrap, 'wrap', 'multi selection wraps pills');
    assert.strictEqual(box(wrap).height, 40, 'size.xxl control height');
    assert.strictEqual(w.paddingTop, '8px');
    assert.strictEqual(w.paddingBottom, '8px');
    assert.strictEqual(w.paddingLeft, '12px');
    assert.strictEqual(w.paddingRight, '60px', '12px + 24px for the clear button and the arrow');
    assert.strictEqual(w.columnGap, '8px');
    assert.strictEqual(w.rowGap, '4px');
    assert.strictEqual(w.boxShadow, inset(lightForm.borderColor));
    assert.strictEqual(w.backgroundColor, rgb(lightForm.backgroundColor));
    assert.strictEqual(w.marginTop, '0px');
    assert.strictEqual(w.listStyleType, 'none');

    const compressed = css(wrapOf('[data-c="compressed"]'));
    assert.strictEqual(box(wrapOf('[data-c="compressed"]')).height, 32, 'size.xl compressed height');
    assert.strictEqual(compressed.paddingTop, '4px');
    assert.strictEqual(compressed.paddingLeft, '4px');
    assert.strictEqual(compressed.columnGap, '4px');
    assert.strictEqual(compressed.rowGap, '2px');

    assert.strictEqual(css(wrapOf('[data-c="single"]')).flexWrap, 'nowrap', 'single selection does not wrap');
    assert.true(box(wrapOf('[data-c="many"]')).height > 40, 'rows of pills grow the control');
    assert.strictEqual(
      css(q('[data-c="many"] .euiFormControlLayout')).height,
      `${box(q('[data-c="many"] .euiFormControlLayout')).height}px`,
      'the layout grows with it (height auto)'
    );

    // icons via the migrated form control layout
    assert.dom('[data-c="multi"] .euiFormControlLayoutClearButton').hasAttribute('aria-label', 'Clear input');
    assert.dom('[data-c="multi"] [data-icon-type="chevronSingleDown"]').exists('dropdown arrow');
    assert.dom('[data-c="full"] .euiFormControlLayoutClearButton').doesNotExist('no clear button without a selection');
    assert.strictEqual(css(wrapOf('[data-c="full"]')).paddingRight, '36px', 'only the arrow');
  });

  test('pills: upstream hollow badges, sizes, removal and labels', async function (assert) {
    const state = new Selection();
    state.selected = ['Apple', { label: 'Banana', color: 'primary' }];
    const options = ['Apple', { label: 'Banana', color: 'primary' }, 'Cherry'];

    await render(
      <template>
        <EuiBadge @color="hollow" data-c="hollow">Ref</EuiBadge>
        <EuiBadge @color="primary" data-c="primary">Ref</EuiBadge>
        <div data-c="combo">
          <EuiComboBox @options={{options}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} as |o|>{{if o.label o.label o}}</EuiComboBox>
        </div>
        <div data-c="disabled">
          <EuiComboBox @isDisabled={{true}} @options={{FRUITS}} @selectedOptions={{FRUITS}} @onChange={{noop}} as |o|>{{o}}</EuiComboBox>
        </div>
      </template>
    );

    const [apple, banana] = [...document.querySelectorAll<HTMLElement>('[data-c="combo"] .euiComboBoxPill')];
    assert.dom(apple).hasClass('euiBadge').hasAttribute('data-test-subj', 'euiComboBoxPill');
    assert.strictEqual(css(apple!).backgroundColor, css(q('[data-c="hollow"]')).backgroundColor, 'hollow by default (upstream)');
    assert.strictEqual(css(banana!).backgroundColor, css(q('[data-c="primary"]')).backgroundColor, 'option color');
    assert.strictEqual(box(apple!).height, 22, 'size.l - 2px');
    assert.strictEqual(css(apple!).lineHeight, '20px');
    assert.strictEqual(css(apple!).marginTop, '1px');
    assert.strictEqual(css(apple!).marginBottom, '1px');
    assert.strictEqual(css(apple!).maxWidth, 'calc(100% - 18px)', 'size.xxs + size.base left for the input');
    assert.strictEqual(css(banana!).marginLeft, '0px');

    assert.dom('[data-c="combo"] [data-selected-index="0"]').hasAttribute('aria-label', 'Remove Apple from selection in this group');
    assert.dom('[data-c="combo"] [data-selected-index="1"]').hasAttribute('aria-label', 'Remove Banana from selection in this group');

    await triggerEvent('[data-c="combo"] [data-selected-index="0"]', 'mousedown');
    assert.deepEqual(state.selected, [{ label: 'Banana', color: 'primary' }]);
    assert.dom('[data-c="combo"] .euiComboBoxPill').exists({ count: 1 });

    assert.dom('[data-c="disabled"] .euiComboBoxPill').exists({ count: 4 });
    assert.dom('[data-c="disabled"] .euiBadge__iconButton').doesNotExist('disabled pills cannot be removed');
  });

  test('EuiComboBoxPill on its own: explicit labels, plain text and default color', async function (assert) {
    const closed: unknown[] = [];
    const onClose = (option: unknown) => closed.push(option);

    await render(
      <template>
        <EuiComboBoxPill @option="Kiwi" @onClose={{onClose}} data-c="close">Kiwi</EuiComboBoxPill>
        <EuiComboBoxPill @option="Kiwi" @onClose={{onClose}} @iconOnClickAriaLabel="Drop it" data-c="label">Kiwi</EuiComboBoxPill>
        <EuiComboBoxPill @option={{42}} data-c="plain-badge">42</EuiComboBoxPill>
        <EuiComboBoxPill @asPlainText={{true}}>Plain</EuiComboBoxPill>
        <EuiBadge @color="hollow" data-c="hollow">Ref</EuiBadge>
      </template>
    );

    assert.dom('[data-c="close"] .euiBadge__iconButton').hasAttribute('aria-label', 'Remove Kiwi from selection in this group');
    assert.dom('[data-c="label"] .euiBadge__iconButton').hasAttribute('aria-label', 'Drop it');
    await click('[data-c="close"] .euiBadge__iconButton');
    assert.deepEqual(closed, ['Kiwi']);
    assert.strictEqual(css(q('[data-c="plain-badge"]')).backgroundColor, css(q('[data-c="hollow"]')).backgroundColor);

    const plain = q('span.euiComboBoxPill--plainText');
    assert.dom(plain).doesNotHaveClass('euiBadge');
    assert.strictEqual(css(plain).fontSize, px(euiFontSize(lightContext, 's', undefined).fontSize as string));
    assert.strictEqual(css(plain).color, rgb(lightForm.textColor));
    assert.strictEqual(css(plain).textOverflow, 'ellipsis');
  });

  test('single selection: pill, plain text and the check indicator in the list', async function (assert) {
    const state = new Selection();
    state.selected = ['Banana'];
    const plain = { asPlainText: true };

    await render(
      <template>
        <div style="width: 600px">
          <div data-c="pill"><EuiComboBox @singleSelection={{true}} @options={{FRUITS}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} as |o|>{{o}}</EuiComboBox></div>
          <div data-c="plain"><EuiComboBox @singleSelection={{plain}} @options={{FRUITS}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} as |o|>{{o}}</EuiComboBox></div>
        </div>
      </template>
    );

    assert.dom('[data-c="pill"] .euiComboBoxPill.euiBadge').hasText('Banana');
    assert.dom('[data-c="pill"] .euiComboBoxPill .euiBadge__iconButton').doesNotExist('no remove button in single selection');
    assert.dom('[data-c="plain"] .euiComboBoxPill--plainText').hasText('Banana');
    assert.dom('[data-c="plain"] .euiComboBox__inputWrap').hasClass('euiComboBox__inputWrap--plainText');
    const plainWrap = css(wrapOf('[data-c="plain"]'));
    assert.strictEqual(plainWrap.alignItems, 'center', 'upstream plain text alignment');
    assert.strictEqual(plainWrap.cursor, 'text');

    await open('[data-c="pill"]');
    const [apple, banana] = rows();
    assert.dom(banana!.querySelector('.euiListItemLayout__icon')).hasAttribute('data-icon-type', 'check');
    assert.dom(apple!.querySelector('.euiListItemLayout__icon')).hasAttribute('data-icon-type', 'empty');
    assert.strictEqual(css(banana!).color, rgb(light.colors.textPrimary), 'selected option color');
    // upstream: opening by click highlights the selected option
    assert.strictEqual(css(banana!).backgroundColor, rgb(light.colors.backgroundBaseInteractiveSelectHover));
    assert.dom(banana).hasAttribute('aria-selected', 'true');
    assert.dom(apple).hasAttribute('aria-selected', 'false');

    await triggerEvent(apple!, 'mouseup');
    assert.deepEqual(state.selected, ['Apple'], 'replaces the selection');
  });

  test('search input: upstream input styles, native placeholder and accessible names', async function (assert) {
    const state = new Selection();

    await render(
      <template>
        <div style="width: 600px" data-c="combo">
          <EuiComboBox @options={{FRUITS}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} @placeholder="Pick fruit" @ariaLabel="Fruits" as |o|>{{o}}</EuiComboBox>
        </div>
      </template>
    );

    const input = inputOf('[data-c="combo"]');
    assert.dom(input).hasAttribute('placeholder', 'Pick fruit').hasAttribute('aria-label', 'Fruits');
    assert.dom('.euiComboBoxPlaceholder').doesNotExist('no placeholder paragraph');
    const i = css(input);
    assert.strictEqual(i.height, '24px', 'size.l');
    assert.strictEqual(i.borderTopStyle, 'none');
    assert.strictEqual(i.boxShadow, 'none');
    assert.strictEqual(i.backgroundColor, 'rgba(0, 0, 0, 0)');
    assert.strictEqual(i.fontSize, px(euiFontSize(lightContext, 's', undefined).fontSize as string));
    assert.strictEqual(i.color, rgb(lightForm.textColor));
    assert.strictEqual(css(input, '::placeholder').color, rgb(lightForm.controlPlaceholderText));
    const wrap = wrapOf('[data-c="combo"]');
    assert.strictEqual(css(wrap).cursor, 'text', 'placeholder uses the plain text layout');
    assert.true(box(input).width > box(wrap).width - 12 - 36 - 4, 'the input fills the row while the placeholder shows');

    state.selected = ['Apple'];
    await settled();
    assert.dom(input).hasAttribute('placeholder', '');
    assert.strictEqual(css(wrap).cursor, 'auto');
    const pill = q('[data-c="combo"] .euiComboBoxPill');
    assert.true(box(input).left >= box(pill).left + box(pill).width, 'the input follows the pill on the same row');
    assert.true(Math.abs(box(input).top + 12 - (box(pill).top + 11)) <= 1, 'on the same row, centered');
  });

  test('states: open, invalid and disabled', async function (assert) {
    class State {
      @tracked invalid = true;
      @tracked disabled = false;
    }
    const state = new State();
    const selected = ['Apple'];

    await render(
      <template>
        <div data-c="combo">
          <EuiComboBox @isInvalid={{state.invalid}} @isDisabled={{state.disabled}} @options={{FRUITS}} @selectedOptions={{selected}} @onChange={{noop}} as |o|>{{o}}</EuiComboBox>
        </div>
      </template>
    );

    const wrap = wrapOf('[data-c="combo"]');
    const input = inputOf('[data-c="combo"]');
    assert.strictEqual(css(wrap).outlineColor, rgb(lightForm.borderInvalid));
    assert.strictEqual(css(wrap).outlineWidth, '1px');
    assert.dom(input).hasAttribute('aria-invalid', 'true');
    assert.dom('[data-c="combo"] .euiComboBox').hasClass('euiComboBox-isInvalid');
    assert.dom('[data-c="combo"] [data-icon-type="warning"]').exists('upstream invalid warning icon');

    await open('[data-c="combo"]');
    assert.dom('[data-c="combo"] .euiComboBox').hasClass('euiComboBox-isOpen');
    assert.strictEqual(css(wrap).outlineColor, rgb(lightForm.borderFocused), 'open wins over invalid');
    assert.strictEqual(css(wrap).outlineWidth, '2px');
    await triggerKeyEvent(input, 'keydown', 'Escape');

    state.invalid = false;
    state.disabled = true;
    await settled();
    assert.strictEqual(wrapOf('[data-c="combo"]'), wrap, 'no element replacement');
    assert.dom(input).isDisabled().doesNotHaveAttribute('aria-invalid');
    assert.strictEqual(css(wrap).backgroundColor, rgb(lightForm.backgroundDisabledColor));
    assert.strictEqual(css(wrap).color, rgb(lightForm.textColorDisabled));
    assert.dom('[data-c="combo"] [data-icon-type="chevronSingleDown"]').doesNotExist('no arrow while disabled (upstream)');
    assert.dom('[data-c="combo"] .euiFormControlLayoutClearButton').doesNotExist();
    assert.dom('[data-c="combo"] .euiComboBox').hasClass('euiComboBox-isDisabled');
  });

  test('options list panel: attached input popover, width, z-index and shadows', async function (assert) {
    await render(
      <template>
        <div style="width: 800px">
          <div data-c="below"><EuiComboBox @options={{FRUITS}} @onChange={{noop}} as |o|>{{o}}</EuiComboBox></div>
        </div>
      </template>
    );
    await open('[data-c="below"]');

    const content = panel();
    assert.dom(content).hasClass('euiPopover__panel').hasClass('euiPanel').doesNotHaveClass('euiPopover__panel-isAttached');
    const p = css(content);
    // ember-basic-dropdown copies the trigger's rendered width; the test
    // container is scaled, the wormhole is not
    assert.strictEqual(
      content.getBoundingClientRect().width,
      q('[data-c="below"] .euiComboBox').getBoundingClientRect().width,
      'as wide as the input'
    );
    assert.strictEqual(p.paddingTop, '8px', 'panelPaddingSize s');
    assert.strictEqual(p.paddingLeft, '8px');
    assert.strictEqual(p.borderTopLeftRadius, px(String(light.border.radius.panel)), 'EuiPanel radius m (panel)');
    assert.strictEqual(p.backgroundColor, rgb(light.components.popoverPanelBackground));
    assert.strictEqual(p.color, rgb(light.colors.textParagraph));
    assert.strictEqual(p.zIndex, '99999', 'above modals (8000) and their masks');
    assert.strictEqual(p.position, 'absolute');
    finishAnimations();
    assert.strictEqual(css(content).opacity, '1');
    assert.notStrictEqual(p.boxShadow, 'none', 'attached bottom shadow');
    assert.true(
      content.getBoundingClientRect().top >=
        q('[data-c="below"] .euiComboBox').getBoundingClientRect().bottom - 1,
      'below the input'
    );

    const status = q('.ember-power-select-visually-hidden[role="status"]', content);
    assert.strictEqual(css(status).position, 'absolute');
    assert.strictEqual(css(status).clipPath, 'inset(50%)', 'upstream screen reader only');

    const list = q('[role="listbox"]', content);
    assert.dom(list).hasClass('euiComboBoxOptionsList');
    assert.strictEqual(css(list).maxHeight, '200px', 'upstream LIST_MAX_HEIGHT');
    assert.strictEqual(css(list).overflowY, 'auto');
  });

  test('a list opened above gets the top attached shadow', async function (assert) {
    await render(
      <template>
        <div style="padding-top: 300px">
          <EuiComboBox @verticalPosition="above" @options={{FRUITS}} @onChange={{noop}} as |o|>{{o}}</EuiComboBox>
        </div>
      </template>
    );
    await open();
    const content = panel();
    assert.dom(content).hasClass('ember-basic-dropdown-content--above');
    assert.notStrictEqual(css(content).boxShadow, 'none');
    const above = css(content).boxShadow;
    // ember-basic-dropdown positions with scaled rects in the test
    // container, so compare the shadows rather than the geometry
    content.classList.remove('ember-basic-dropdown-content--above');
    const below = css(content).boxShadow;
    content.classList.add('ember-basic-dropdown-content--above');
    assert.notStrictEqual(above, below, 'upstream isAttached.top vs bottom shadow');
    assert.notStrictEqual(below, 'none');
  });

  test('options: upstream list item rows, states and option semantics', async function (assert) {
    const state = new Selection();
    state.selected = ['Cherry'];
    const options = ['Apple', 'Banana', 'Cherry', { label: 'Durian', disabled: true }];

    await render(
      <template>
        <EuiComboBox @options={{options}} @selectedOptions={{state.selected}} @onChange={{state.onChange}} as |o|>{{if o.label o.label o}}</EuiComboBox>
      </template>
    );
    await open();

    const list = q('[role="listbox"]', panel());
    assert.dom(list).hasAttribute('aria-multiselectable', 'true');
    // upstream: the selected Cherry is not listed in multiple selection
    const [apple, banana, durian] = rows();
    assert.strictEqual(rows().length, 3);

    const a = css(apple!);
    assert.strictEqual(box(apple!).height, 29, 'upstream default rowHeight');
    assert.strictEqual(a.paddingLeft, '8px');
    assert.strictEqual(a.paddingRight, '8px');
    assert.strictEqual(a.borderTopLeftRadius, px(String(light.border.radius.control)));
    assert.strictEqual(a.color, rgb(light.colors.textParagraph));
    assert.strictEqual(a.cursor, 'pointer');
    assert.strictEqual(a.fontSize, px(euiFontSize(lightContext, 's', undefined).fontSize as string));
    assert.strictEqual(css(q('.euiListItemLayout__text', apple!)).textOverflow, 'ellipsis', 'truncates');
    assert.dom(q('.euiListItemLayout__text', apple!)).hasAttribute('title', 'Apple');

    // upstream: nothing is highlighted when the list opens
    assert.strictEqual(a.backgroundColor, 'rgba(0, 0, 0, 0)', 'not focused');
    assert.dom('.euiComboBoxOption__enterBadge', panel()).doesNotExist('no enter badge without @onFocusBadge');
    assert.strictEqual(css(banana!).backgroundColor, 'rgba(0, 0, 0, 0)');

    assert.dom(apple).hasAttribute('aria-selected', 'false');

    assert.strictEqual(css(durian!).color, rgb(light.colors.textDisabled), 'disabled');
    assert.strictEqual(css(durian!).cursor, 'not-allowed');
    assert.dom(durian).hasAttribute('aria-disabled', 'true');

    assert.dom(apple).hasAttribute('aria-setsize', '3').hasAttribute('aria-posinset', '1');
    assert.dom(durian).hasAttribute('aria-posinset', '3');
    assert.dom('[tabindex]', list).doesNotExist('options are not tab stops; focus stays in the input');

    // keyboard: aria-activedescendant follows the highlighted option
    const input = q(INPUT);
    assert.false(input.hasAttribute('aria-activedescendant'), 'no active option on open (upstream)');
    await triggerKeyEvent(input, 'keydown', 'ArrowDown');
    assert.strictEqual(input.getAttribute('aria-activedescendant'), apple!.id);
    assert.strictEqual(css(rows()[0]!).backgroundColor, rgb(light.colors.backgroundBaseInteractiveHover), 'focused');
    await triggerKeyEvent(input, 'keydown', 'ArrowDown');
    assert.strictEqual(input.getAttribute('aria-activedescendant'), rows()[1]!.id);
    assert.strictEqual(css(rows()[1]!).backgroundColor, rgb(light.colors.backgroundBaseInteractiveHover));
    assert.strictEqual(css(rows()[0]!).backgroundColor, 'rgba(0, 0, 0, 0)');
    await triggerKeyEvent(input, 'keydown', 'Enter');
    assert.deepEqual(state.selected, ['Cherry', 'Banana'], 'Enter selects the highlighted option');
  });

  test('groups: upstream group labels with dividers and taller rows', async function (assert) {
    const grouped = [
      { groupName: 'Fruits', options: ['Apple', 'Banana'] },
      { groupName: 'Veggies', options: ['Carrot'] }
    ];

    await render(
      <template><EuiComboBox @options={{grouped}} @onChange={{noop}} as |o|>{{o}}</EuiComboBox></template>
    );
    await open();

    const [fruits, veggies] = [...panel().querySelectorAll<HTMLElement>('.euiComboBoxTitle')];
    assert.dom(fruits).hasAttribute('role', 'presentation').hasText('Fruits');
    const f = css(fruits!);
    assert.strictEqual(f.color, rgb(light.colors.textHeading));
    assert.strictEqual(f.fontWeight, String(light.font.weight[light.font.title.weight as 'bold']));
    assert.strictEqual(f.fontSize, px(euiFontSize(lightContext, 'xs', undefined).fontSize as string));
    assert.strictEqual(f.paddingLeft, '4px');
    assert.strictEqual(box(fruits!).height, 29);
    assert.strictEqual(css(fruits!, '::before').content, 'none', 'the first group has no divider');
    assert.strictEqual(box(veggies!).height, 45, 'rowHeight + 16 (upstream getListItemSize)');
    assert.strictEqual(css(veggies!).paddingTop, '24px');
    assert.strictEqual(css(veggies!, '::before').borderTopColor, rgb(light.components.selectableListItemBorderColor));

    const ids = rows().map((row) => row.id.split('-').pop());
    assert.deepEqual(ids, ['0.0', '0.1', '1.0'], 'ids follow ember-power-select index paths');
    assert.deepEqual(rows().map((row) => row.getAttribute('aria-posinset')), ['1', '2', '3']);
  });

  test('without a block, options show their label with the search highlighted', async function (assert) {
    const options = [{ label: 'Banana' }, { label: 'Ananas' }, { label: 'Cherry' }];
    const selected = [options[2]];

    await render(
      <template><EuiComboBox @options={{options}} @searchField="label" @selectedOptions={{selected}} @onChange={{noop}} /></template>
    );
    assert.dom('.euiComboBoxPill').hasText('Cherry', 'pills show the label');

    await open();
    // upstream: the selected Cherry is not listed
    assert.deepEqual(rows().map((row) => row.textContent!.trim()), ['Banana', 'Ananas']);
    await fillIn(INPUT, 'nan');
    
    const banana = rows()[0]!;
    assert.dom('mark.euiMark', banana).hasText('nan', 'EuiHighlight marks the match');
    assert.dom(q('.euiListItemLayout__text', banana)).doesNotHaveAttribute('title', 'no title while searching');
  });

  test('messages: no matches, search, loading and the create option', async function (assert) {
    class State {
      @tracked options: unknown = FRUITS;
      created: string[] = [];
      onCreate = (text: string) => {
        this.created.push(text);
      };
    }
    const state = new State();
    const search = (term: string) => FRUITS.filter((f) => f.includes(term));

    await render(
      <template>
        <div data-c="plain"><EuiComboBox @options={{FRUITS}} @onChange={{noop}} as |o|>{{o}}</EuiComboBox></div>
        <div data-c="search"><EuiComboBox @search={{search}} @onChange={{noop}} as |o|>{{o}}</EuiComboBox></div>
        <div data-c="create"><EuiComboBox @options={{FRUITS}} @onCreateOption={{state.onCreate}} @onChange={{noop}} as |o|>{{o}}</EuiComboBox></div>
        <div data-c="always"><EuiComboBox @options={{FRUITS}} @alwaysShowCreateOption={{true}} @onCreateOption={{state.onCreate}} @onChange={{noop}} as |o|>{{o}}</EuiComboBox></div>
      </template>
    );

    await open('[data-c="plain"]');
    await fillIn('[data-c="plain"] ' + INPUT, 'zzz');
    let message = q('.euiComboBoxOptionsList', panel());
    assert.dom('.euiComboBoxOptionsList__empty', message).hasText("zzz doesn't match any options", 'upstream message');
    assert.strictEqual(css(message).paddingTop, '8px', 'upstream empty state padding');
    assert.strictEqual(css(message).textAlign, 'center');
    assert.strictEqual(css(q('.euiComboBoxOptionsList__empty', message)).fontSize, px(euiFontSize(lightContext, 'xs', undefined).fontSize as string), 'xs text');
    await triggerKeyEvent('[data-c="plain"] ' + INPUT, 'keydown', 'Escape');

    await open('[data-c="search"]');
    message = q('.euiComboBoxOptionsList', panel());
    assert.dom(message).hasText('Type to search');
    assert.strictEqual(css(message).textAlign, 'center');
    await triggerKeyEvent('[data-c="search"] ' + INPUT, 'keydown', 'Escape');

    await open('[data-c="create"]');
    await fillIn('[data-c="create"] ' + INPUT, 'Kiwi');
    const create = q('[data-test-subj="comboBoxCreateOption"]', panel());
    assert.dom('.euiComboBoxOption__emptyStateText', create).includesText('Kiwi');
    assert.strictEqual(css(q('.euiComboBoxOption__contentWrapper', create)).display, 'flex');
    assert.strictEqual(css(q('.euiComboBoxOption__emptyStateText', create)).textAlign, 'start');
    assert.strictEqual(css(q('.euiComboBoxOption__emptyStateText', create)).marginBottom, '0px');
    assert.dom('.euiComboBoxOption__enterBadge [data-icon-type="return"]', create).exists();
    assert.strictEqual(css(q('.euiComboBoxOption__enterBadge', create)).marginLeft, '4px');
    await triggerKeyEvent('[data-c="create"] ' + INPUT, 'keydown', 'Enter');
    assert.deepEqual(state.created, ['Kiwi']);

    await open('[data-c="always"]');
    await fillIn('[data-c="always"] ' + INPUT, 'App');
    assert.strictEqual(rows().length, 1, 'matches stay listed');
    const always = q('[data-test-subj="comboBoxCreateOption"]', panel());
    assert.dom('.euiComboBoxOption__enterBadge', always).hasText('Create');
    assert.strictEqual(css(always).textAlign, 'start', 'a row, not the centered empty state');
    assert.strictEqual(css(always).cursor, 'pointer');
    await triggerEvent(always, 'pointerup');
    assert.deepEqual(state.created, ['Kiwi', 'App']);
  });

  test('loading options show the upstream spinner empty state', async function (assert) {
    let resolve!: (value: string[]) => void;
    const options = new Promise<string[]>((r) => (resolve = r));

    await render(
      <template><EuiComboBox @options={{options}} @onChange={{noop}} as |o|>{{o}}</EuiComboBox></template>
    );
    await click(INPUT);
    await waitUntil(() => document.querySelector('.euiComboBoxOptionsList .euiFlexGroup'));
    const message = q('.euiComboBoxOptionsList', panel());
    assert.dom(message).includesText('Loading options...');
    assert.strictEqual(css(message).paddingTop, '8px');
    resolve(FRUITS);
    await settled();
    assert.strictEqual(rows().length, 4);
  });

  test('reactive args update in place', async function (assert) {
    class State {
      @tracked compressed = false;
      @tracked fullWidth = false;
      @tracked invalid = false;
    }
    const state = new State();
    const selected = ['Apple'];

    await render(
      <template>
        <div style="width: 800px">
          <EuiComboBox @compressed={{state.compressed}} @fullWidth={{state.fullWidth}} @isInvalid={{state.invalid}} @options={{FRUITS}} @selectedOptions={{selected}} @onChange={{noop}} as |o|>{{o}}</EuiComboBox>
        </div>
      </template>
    );

    const root = q('.euiComboBox');
    const wrap = q('.euiComboBox__inputWrap');
    const pill = q('.euiComboBoxPill');
    assert.strictEqual(box(wrap).height, 40);

    state.compressed = true;
    state.fullWidth = true;
    state.invalid = true;
    await settled();
    assert.strictEqual(q('.euiComboBox'), root, 'same root');
    assert.strictEqual(q('.euiComboBox__inputWrap'), wrap, 'same wrap');
    assert.strictEqual(q('.euiComboBoxPill'), pill, 'same pill');
    assert.strictEqual(box(wrap).height, 32);
    assert.strictEqual(box(root).width, 800);
    assert.strictEqual(css(wrap).outlineColor, rgb(lightForm.borderInvalid));

    state.compressed = false;
    state.fullWidth = false;
    state.invalid = false;
    await settled();
    assert.strictEqual(box(wrap).height, 40);
    assert.strictEqual(box(root).width, 400);
    assert.strictEqual(css(wrap).outlineStyle, 'none');
  });

  test('nearest provider light/dark, sibling isolation and JS-object overrides', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'light';
      @tracked overrides: EuiBorealisOverrides = {};
    }
    const state = new State();
    const own: EuiBorealisOverrides = { border: { radius: { control: '13px' } } };
    const selected = ['Apple'];

    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}} @borealisOverrides={{state.overrides}}>
          <div data-c="parent"><EuiComboBox @options={{FRUITS}} @selectedOptions={{selected}} @onChange={{noop}} as |o|>{{o}}</EuiComboBox></div>
          <EuiEmotionProvider @borealisOverrides={{own}}>
            <div data-c="child"><EuiComboBox @options={{FRUITS}} @onChange={{noop}} as |o|>{{o}}</EuiComboBox></div>
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <div data-c="sibling"><EuiComboBox @options={{FRUITS}} @onChange={{noop}} as |o|>{{o}}</EuiComboBox></div>
        </EuiEmotionProvider>
      </template>
    );

    const wrap = wrapOf('[data-c="parent"]');
    assert.strictEqual(css(wrap).backgroundColor, rgb(lightForm.backgroundColor));
    assert.strictEqual(css(wrapOf('[data-c="child"]')).borderTopLeftRadius, '13px', 'override');

    state.mode = 'dark';
    await settled();
    assert.strictEqual(wrapOf('[data-c="parent"]'), wrap, 'no replacement');
    assert.strictEqual(css(wrap).backgroundColor, rgb(darkForm.backgroundColor));
    assert.strictEqual(css(wrap).boxShadow, inset(darkForm.borderColor));
    assert.strictEqual(css(wrapOf('[data-c="child"]')).backgroundColor, rgb(darkForm.backgroundColor), 'child inherits the mode');
    assert.strictEqual(css(wrapOf('[data-c="sibling"]')).backgroundColor, rgb(lightForm.backgroundColor), 'sibling isolated');

    await open('[data-c="parent"]');
    const content = panel();
    assert.strictEqual(css(content).backgroundColor, rgb(dark.components.popoverPanelBackground), 'portaled panel keeps its mode');
    assert.strictEqual(css(content).color, rgb(dark.colors.textParagraph));
    assert.strictEqual(css(rows()[1]!).color, rgb(dark.colors.textParagraph));
    // upstream: the selected Apple is not listed
    assert.strictEqual(css(rows()[0]!).color, rgb(dark.colors.textParagraph));
    await triggerKeyEvent('[data-c="parent"] ' + INPUT, 'keydown', 'Escape');

    state.overrides = { border: { radius: { control: '4px' } } };
    await settled();
    assert.strictEqual(css(wrap).borderTopLeftRadius, '4px');
    assert.strictEqual(css(wrapOf('[data-c="child"]')).borderTopLeftRadius, '13px', 'nearest override wins');
    assert.strictEqual(css(wrapOf('[data-c="sibling"]')).borderTopLeftRadius, px(String(light.border.radius.control)));
  });

  test('RTL: logical paddings and icon side', async function (assert) {
    const selected = ['Apple'];
    await render(
      <template>
        <div dir="rtl" style="width: 600px">
          <EuiComboBox @options={{FRUITS}} @selectedOptions={{selected}} @onChange={{noop}} as |o|>{{o}}</EuiComboBox>
        </div>
      </template>
    );
    const wrap = q('.euiComboBox__inputWrap');
    assert.strictEqual(css(wrap).paddingRight, '12px', 'start padding on the right');
    assert.strictEqual(css(wrap).paddingLeft, '60px', 'icon affordance on the left');
    const icons = q('.euiFormControlLayoutIcons');
    assert.true(box(icons).left < box(wrap).left + 60, 'icons sit at the inline end (left)');
    const pill = q('.euiComboBoxPill');
    assert.true(box(pill).left + box(pill).width > box(wrap).left + box(wrap).width - 60, 'pills start on the right');
  });

  test('high contrast: real borders and underlined focused options', async function (assert) {
    const selected = ['Apple'];
    await render(
      <template>
        <EuiEmotionProvider @highContrastMode="preferred">
          <div data-c="hc"><EuiComboBox @options={{FRUITS}} @selectedOptions={{selected}} @onChange={{noop}} as |o|>{{o}}</EuiComboBox></div>
        </EuiEmotionProvider>
        <div data-c="std"><EuiComboBox @options={{FRUITS}} @onChange={{noop}} as |o|>{{o}}</EuiComboBox></div>
      </template>
    );
    const hc = css(wrapOf('[data-c="hc"]'));
    assert.strictEqual(hc.borderTopStyle, 'solid');
    assert.strictEqual(hc.borderTopColor, rgb(light.border.color));
    assert.strictEqual(css(wrapOf('[data-c="std"]')).borderTopStyle, 'none', 'standard contrast isolated');

    await open('[data-c="hc"]');
    // upstream: options are focused with the arrow keys, not on open
    await triggerKeyEvent('[data-c="hc"] ' + INPUT, 'keydown', 'ArrowDown');
    assert.strictEqual(css(rows()[0]!).textDecorationLine, 'underline', 'focused option');
    assert.strictEqual(css(panel()).borderTopStyle, 'solid', 'panel border instead of a shadow');
  });
});
