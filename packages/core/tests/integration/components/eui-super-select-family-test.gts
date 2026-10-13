import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  focus,
  render,
  settled,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiFormRow from '#src/components/eui-form-row.gts';
import EuiSuperSelect from '#src/components/eui-super-select.gts';
import EuiSuperSelectControl from '#src/components/eui-super-select-control.gts';
import { euiFormControlStyles } from '#src/utils/eui/styles.generated.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiSuperSelectOption } from '#src/components/eui-super-select.gts';
import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type { EuiBorealisOverrides } from '#src/utils/eui/theme.ts';

const lightContext = resolveBorealisTheme('light');
const light = lightContext.euiTheme;
// High contrast replaces border tokens (upstream useHighContrastModifications).
const lightHc = resolveBorealisTheme('light', {}, 'preferred').euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;
const forms = (theme: typeof light) =>
  theme.components.forms as unknown as Record<string, string>;

/** Normalize any CSS color to the browser's computed `rgb()` form. */
function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

/** The computed px value of a CSS font-size expression (e.g. rem-based). */
function fontSizePx(value: string) {
  const probe = document.createElement('span');
  probe.style.fontSize = value;
  document.body.appendChild(probe);
  const size = getComputedStyle(probe).fontSize;
  probe.remove();
  return size;
}

const controlFontSize = /font-size: ([^;]+);/.exec(
  euiFormControlStyles(lightContext).shared
)![1]!;

const inset = (color: string, width = '1px') =>
  `${rgb(color)} 0px 0px 0px ${width} inset`;

/** Measured box in CSS pixels (the ember-qunit container is scaled). */
function box(element: Element) {
  const container = document.querySelector<HTMLElement>('#ember-testing')!;
  const scale = container.getBoundingClientRect().width / container.offsetWidth;
  const rect = element.getBoundingClientRect();
  return {
    width: Math.round((rect.width / scale) * 100) / 100,
    height: Math.round((rect.height / scale) * 100) / 100,
    left: rect.left / scale,
    right: rect.right / scale
  };
}

function q<T extends Element = HTMLElement>(selector: string, root: ParentNode = document) {
  const element = root.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

const css = (element: Element, pseudo?: string) => getComputedStyle(element, pseudo);
const control = (key: string) => q<HTMLButtonElement>(`[data-c="${key}"]`);
const layoutOf = (element: Element) => element.closest('.euiFormControlLayout')!;
const items = () => Array.from(document.querySelectorAll<HTMLButtonElement>('.euiSuperSelect__item'));
const listbox = () => document.querySelector<HTMLElement>('.euiSuperSelect__listbox');

async function open(selector: string) {
  await click(selector);
  await waitUntil(() => listbox() && document.activeElement?.classList.contains('euiSuperSelect__item'));
}

const OPTIONS: EuiSuperSelectOption[] = [
  { value: 'warning', inputDisplay: 'Warning', dropdownDisplay: 'Warning: something may be wrong' },
  { value: 'minor', inputDisplay: 'Minor' },
  { value: 'critical', inputDisplay: 'Critical', disabled: true },
  { value: 'info', inputDisplay: 'Info' }
];

const FIRST_DISABLED: EuiSuperSelectOption[] = [
  { value: 'off', inputDisplay: 'Off', disabled: true },
  ...OPTIONS
];

module('Integration | Component | Borealis super select', function (hooks) {
  setupRenderingTest(hooks);

  test('control: upstream form-control box, typography, border and dropdown arrow (normal and compressed)', async function (assert) {
    await render(
      <template>
        <div style="width: 800px">
          <EuiSuperSelect @options={{OPTIONS}} @valueOfSelected="minor" data-c="m" />
          <EuiSuperSelect @options={{OPTIONS}} @valueOfSelected="minor" @compressed={{true}} data-c="s" />
        </div>
      </template>
    );

    const m = control('m');
    const s = control('s');
    const mc = css(m);

    assert.strictEqual(m.tagName, 'BUTTON');
    assert.strictEqual(m.type, 'button');
    assert.strictEqual(box(m).height, 40, 'control height');
    assert.strictEqual(box(s).height, 32, 'compressed height');
    assert.strictEqual(mc.lineHeight, '40px', 'line height matches the input height');
    assert.strictEqual(css(s).lineHeight, '32px');
    assert.strictEqual(mc.paddingTop, '0px');
    assert.strictEqual(mc.paddingBottom, '0px');
    assert.strictEqual(mc.paddingLeft, '12px');
    assert.strictEqual(mc.paddingRight, '36px', '12px + one icon affordance (the arrow)');
    assert.strictEqual(css(s).paddingLeft, '8px');
    assert.strictEqual(css(s).paddingRight, '32px', '8px + 24px compressed affordance');
    assert.strictEqual(mc.boxSizing, 'border-box');
    assert.strictEqual(mc.marginTop, '0px');
    assert.strictEqual(mc.display, 'block');
    assert.strictEqual(mc.textAlign, 'start');
    assert.strictEqual(mc.whiteSpace, 'nowrap', 'truncated');
    assert.strictEqual(mc.overflow, 'hidden');
    assert.strictEqual(mc.textOverflow, 'ellipsis');
    assert.strictEqual(mc.borderTopLeftRadius, light.border.radius.control);
    assert.strictEqual(mc.borderTopStyle, 'none');
    assert.strictEqual(mc.boxShadow, inset(forms(light)['border']!), 'inset border');
    assert.strictEqual(mc.backgroundColor, rgb(forms(light)['background']!));
    assert.strictEqual(mc.color, rgb(light.colors.textParagraph));
    assert.strictEqual(mc.fontSize, fontSizePx(controlFontSize));
    assert.true(mc.fontFamily.includes('Inter'));
    assert.strictEqual(mc.maxWidth, '400px', 'form width');
    assert.strictEqual(box(m).width, 400);
    assert.strictEqual(mc.cursor, 'pointer');

    const arrow = layoutOf(m).querySelector('.euiFormControlLayoutIcons [data-icon-type="chevronSingleDown"]');
    assert.ok(arrow, 'the layout renders the dropdown arrow');
    assert.true(
      box(arrow!).right <= box(m).right && box(arrow!).left > box(m).left + 300,
      'the arrow sits at the end'
    );
    assert.strictEqual(
      (layoutOf(m).querySelector('.euiFormControlLayout__childrenWrapper') as HTMLElement).style.getPropertyValue('--euiFormControlRightIconsCount'),
      '1'
    );
    assert.dom(m).hasText('Minor');
    assert.dom(m).hasClass('euiSuperSelectControl');
  });

  test('control radius (both sizes), full width and group layouts', async function (assert) {
    await render(
      <template>
        <div style="width: 800px">
          <EuiSuperSelect @options={{OPTIONS}} data-c="m" />
          <EuiSuperSelect @options={{OPTIONS}} @compressed={{true}} data-c="s" />
          <EuiSuperSelect @options={{OPTIONS}} @fullWidth={{true}} data-c="full" />
          <EuiSuperSelect @options={{OPTIONS}} data-c="group">
            <:prepend as |className|><span class={{className}}>Pre</span></:prepend>
          </EuiSuperSelect>
        </div>
      </template>
    );

    assert.strictEqual(css(control('m')).borderTopLeftRadius, light.border.radius.control);
    assert.strictEqual(css(control('s')).borderTopLeftRadius, light.border.radius.control);

    assert.strictEqual(css(control('full')).maxWidth, '100%');
    assert.strictEqual(box(control('full')).width, 800);
    assert.notStrictEqual(css(q('.euiSuperSelect:has([data-c="full"])')).maxWidth, '400px', 'the popover root is not capped');

    const group = control('group');
    assert.dom(layoutOf(group)).hasClass('euiFormControlLayout--group');
    assert.dom(layoutOf(group).querySelector('.euiFormControlLayout__prepend')).hasText('Pre');
    assert.strictEqual(css(group).boxShadow, 'none', 'in a group the layout draws the border');
    assert.strictEqual(box(group).height, box(layoutOf(group)).height, 'fills the group (height: 100%)');
    assert.dom(layoutOf(control('m')).querySelector('.euiFormControlLayout__prepend')).doesNotExist('no empty side wrapper');
  });

  test('states: invalid, focus, open, disabled, read-only and loading', async function (assert) {
    await render(
      <template>
        <EuiSuperSelect @options={{OPTIONS}} @isInvalid={{true}} data-c="invalid" />
        <EuiSuperSelect @options={{OPTIONS}} data-c="focus" />
        <EuiSuperSelect @options={{OPTIONS}} @valueOfSelected="minor" @disabled={{true}} data-c="disabled" />
        <EuiSuperSelect @options={{OPTIONS}} @valueOfSelected="minor" @readOnly={{true}} @name="ro" data-c="readonly" />
        <EuiSuperSelect @options={{OPTIONS}} @isLoading={{true}} data-c="loading" />
      </template>
    );

    const invalid = control('invalid');
    assert.dom(invalid).hasClass('euiSuperSelectControl-isInvalid');
    assert.strictEqual(css(invalid).outlineColor, rgb(forms(light)['borderInvalid']!));
    assert.strictEqual(css(invalid).outlineStyle, 'solid');
    assert.strictEqual(css(invalid).outlineWidth, '1px');
    assert.ok(layoutOf(invalid).querySelector('[data-icon-type="warning"]'), 'warning icon');
    assert.strictEqual(css(invalid).paddingRight, '60px', 'two icon affordances');

    await focus(control('focus'));
    assert.strictEqual(css(control('focus')).outlineColor, rgb(forms(light)['borderFocused']!));
    assert.strictEqual(css(control('focus')).outlineWidth, '2px');

    const disabled = control('disabled');
    assert.dom(disabled).isDisabled();
    assert.strictEqual(css(disabled).backgroundColor, rgb(forms(light)['backgroundDisabled']!));
    assert.strictEqual(css(disabled).color, rgb(forms(light)['colorDisabled']!));
    assert.strictEqual(css(disabled).cursor, 'not-allowed');
    assert.dom(layoutOf(disabled)).hasClass('euiFormControlLayout-isDisabled');
    assert.notOk(layoutOf(disabled).querySelector('[data-icon-type="chevronSingleDown"]'), 'no arrow while disabled');

    const readonly = control('readonly');
    assert.dom(readonly).isDisabled('a read-only control cannot be opened');
    assert.dom(readonly).hasText('Minor');
    assert.strictEqual(css(readonly).backgroundColor, rgb(forms(light)['backgroundReadOnly']!));
    assert.strictEqual(css(readonly).cursor, 'default');
    assert.dom(layoutOf(readonly)).hasClass('euiFormControlLayout-readOnly');
    assert.notOk(layoutOf(readonly).querySelector('[data-icon-type="chevronSingleDown"]'), 'no arrow while read-only');
    assert.dom('input[type="hidden"][name="ro"]').hasValue('minor').hasAttribute('readonly');

    const loading = control('loading');
    assert.dom(loading).hasClass('euiSuperSelectControl-isLoading');
    assert.ok(layoutOf(loading).querySelector('[role="progressbar"]'), 'spinner');

    control('disabled').click();
    control('readonly').click();
    control('readonly').dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowDown', bubbles: true }));
    await settled();
    assert.notOk(listbox(), 'disabled and read-only never open');

    await open('[data-c="focus"]');
    assert.strictEqual(css(control('focus')).outlineWidth, '2px', 'open keeps the focus styles while focus is in the list');
    assert.strictEqual(css(control('focus')).outlineColor, rgb(forms(light)['borderFocused']!));
    assert.notStrictEqual(document.activeElement, control('focus'));
  });

  test('placeholder: shown while nothing is selected, in the placeholder color', async function (assert) {
    class State {
      @tracked value?: string = undefined;
    }
    const state = new State();
    await render(
      <template>
        <EuiSuperSelect
          @options={{OPTIONS}}
          @valueOfSelected={{state.value}}
          @placeholder="Pick a severity"
          @name="sev"
          data-c="p"
        />
        <EuiEmotionProvider @colorMode="dark">
          <EuiSuperSelect @options={{OPTIONS}} @placeholder="Dark" data-c="dark" />
        </EuiEmotionProvider>
      </template>
    );

    const button = control('p');
    const placeholder = q('.euiSuperSelectControl__placeholder', button);
    assert.dom(placeholder).hasText('Pick a severity');
    assert.strictEqual(css(placeholder).color, rgb(forms(light)['colorDisabled']!));
    assert.strictEqual(
      css(q('.euiSuperSelectControl__placeholder', control('dark'))).color,
      rgb(forms(dark)['colorDisabled']!)
    );
    assert.dom('input[name="sev"]').hasValue('');

    state.value = 'info';
    await settled();
    assert.strictEqual(control('p'), button, 'no element replacement');
    assert.dom(button).hasText('Info');
    assert.dom('.euiSuperSelectControl__placeholder', button).doesNotExist();
    assert.dom('input[name="sev"]').hasValue('info');

    state.value = 'nope';
    await settled();
    assert.dom(button).hasText('Pick a severity', 'an unknown value shows the placeholder');
  });

  test('open/close: listbox panel matches the control width, upstream listbox styles, z-index and focus return', async function (assert) {
    const events: string[] = [];
    const onFocus = () => events.push('focus');
    const onBlur = () => events.push('blur');
    await render(
      <template>
        <div style="width: 600px">
          <EuiSuperSelect @options={{OPTIONS}} @onFocus={{onFocus}} @onBlur={{onBlur}} data-c="o" />
          <button type="button" data-c="outside">outside</button>
        </div>
      </template>
    );

    const trigger = control('o');
    assert.dom(trigger).hasAria('haspopup', 'listbox');
    await open('[data-c="o"]');
    assert.deepEqual(events, ['focus']);

    const panel = trigger.ownerDocument.querySelector<HTMLElement>('.euiPopover__panel')!;
    assert.ok(panel.contains(listbox()));
    // the panel is portaled out of the scaled test container: compare on screen
    assert.strictEqual(
      Math.round(panel.getBoundingClientRect().width),
      Math.round(trigger.getBoundingClientRect().width),
      'panel as wide as the control'
    );
    assert.strictEqual(css(panel).paddingTop, '0px', 'panelPaddingSize none');
    assert.true(Number(css(panel).zIndex) >= 2000, 'popover z-index above the page');

    const lb = listbox()!;
    assert.dom(lb).hasClass('eui-scrollBar');
    assert.strictEqual(css(lb).maxHeight, '300px');
    assert.strictEqual(css(lb).overflowY, 'auto');
    assert.strictEqual(css(lb).overflowX, 'hidden');
    assert.strictEqual(css(lb).paddingTop, '8px');
    assert.strictEqual(css(lb).paddingLeft, '8px');
    assert.strictEqual(css(lb).scrollbarWidth, 'thin', 'eui-scrollBar styles');

    await triggerKeyEvent(document.activeElement!, 'keydown', 'Escape');
    assert.notOk(listbox(), 'Escape closes');
    assert.deepEqual(events, ['focus', 'blur']);
    await waitUntil(() => document.activeElement === trigger);
    assert.strictEqual(document.activeElement, trigger, 'focus returns to the control');

    await click(trigger);
    await waitUntil(() => listbox());
    await click(trigger);
    assert.notOk(listbox(), 'clicking the control again closes');

    await open('[data-c="o"]');
    await click('[data-c="outside"]');
    assert.notOk(listbox(), 'an outside click closes');
    await new Promise((resolve) => requestAnimationFrame(resolve));
    assert.notStrictEqual(document.activeElement, trigger, 'an outside click keeps its own focus');
  });

  test('options: list item layout, dropdownDisplay vs inputDisplay, selected check, disabled and dividers', async function (assert) {
    await render(
      <template>
        <EuiSuperSelect @options={{OPTIONS}} @valueOfSelected="minor" @hasDividers={{true}} @itemClassName="mine" data-c="o" />
      </template>
    );
    await open('[data-c="o"]');

    const [warning, minor, critical, info] = items();
    assert.strictEqual(items().length, 4);
    assert.dom(warning).hasText('Warning: something may be wrong', 'dropdownDisplay in the list');
    assert.dom(minor).hasText('Minor', 'inputDisplay without dropdownDisplay');
    assert.dom(control('o')).hasText('Minor', 'inputDisplay in the control');
    for (const item of items()) {
      assert.dom(item).hasClass('euiListItemLayout').hasClass('mine').hasAttribute('role', 'option').hasAttribute('type', 'button');
    }

    const ic = css(warning!);
    assert.strictEqual(ic.display, 'inline-flex');
    // the panel is portaled out of the scaled test container: compare layout px
    assert.strictEqual(warning!.offsetWidth, listbox()!.clientWidth - 16, 'full width inside the 8px listbox padding');
    assert.strictEqual(ic.paddingLeft, '8px');
    assert.strictEqual(ic.paddingRight, '8px');
    assert.strictEqual(ic.paddingTop, '0px');
    assert.strictEqual(ic.borderTopLeftRadius, light.border.radius.control);
    assert.strictEqual(ic.color, rgb(light.colors.textParagraph));
    assert.strictEqual(ic.fontSize, fontSizePx(controlFontSize));
    assert.strictEqual(ic.cursor, 'pointer');
    assert.strictEqual(ic.backgroundColor, 'rgba(0, 0, 0, 0)');
    assert.strictEqual(ic.textAlign, 'start');
    const text = q('.euiListItemLayout__text', warning);
    assert.strictEqual(css(text).paddingTop, '6px', 'xs + xxs text padding');
    assert.strictEqual(css(text).whiteSpace, 'normal', 'options wrap');
    assert.strictEqual(css(q('.euiListItemLayout__content', warning)).columnGap, '8px');

    assert.dom(minor).hasAria('selected', 'true');
    assert.dom(warning).hasAria('selected', 'false');
    assert.dom('[data-icon-type="check"]', minor).exists('a check on the selected option');
    assert.dom('[data-icon-type="empty"]', warning).exists('an empty icon keeps the others aligned');
    assert.strictEqual(css(q('.euiListItemLayout__icon', minor)).flexShrink, '0', '@css on EuiIcon');
    assert.strictEqual(css(minor!).color, rgb(light.colors.textPrimary));
    assert.strictEqual(css(q('.euiIcon', minor)).color, rgb(light.colors.textPrimary));

    assert.dom(critical).isDisabled();
    assert.strictEqual(css(critical!).color, rgb(light.colors.textDisabled));
    assert.strictEqual(css(critical!).cursor, 'not-allowed');

    assert.dom(warning).hasClass('euiSuperSelect__item--hasDividers');
    assert.strictEqual(css(warning!).borderBottomWidth, '1px');
    assert.strictEqual(css(warning!).borderBottomStyle, 'solid');
    assert.strictEqual(css(warning!).borderBottomColor, rgb(light.border.color));
    assert.strictEqual(css(info!).borderBottomStyle, 'none', 'no divider after the last option');
    assert.strictEqual(css(minor!, '').outlineStyle, 'none', 'upstream removes the item focus outline');

    critical!.click();
    await settled();
    assert.ok(listbox(), 'a disabled option cannot be chosen');
    assert.dom(control('o')).hasText('Minor');
  });

  test('options without dividers, itemLayoutAlign and options without a value', async function (assert) {
    const options: EuiSuperSelectOption<string | null>[] = [
      { value: 'a', inputDisplay: 'A' },
      { value: null, inputDisplay: 'No value' },
      { value: 'b', inputDisplay: 'B' }
    ];
    await render(
      <template>
        <EuiSuperSelect @options={{options}} @itemLayoutAlign="top" data-c="o" />
      </template>
    );
    await open('[data-c="o"]');

    assert.strictEqual(items().length, 2, 'options without a value are skipped (upstream)');
    assert.strictEqual(css(items()[0]!).borderBottomStyle, 'none');
    assert.dom(items()[0]).doesNotHaveClass('euiSuperSelect__item--hasDividers');
    assert.strictEqual(css(q('.euiListItemLayout__content', items()[0])).alignItems, 'flex-start');
  });

  test('keyboard: open with arrows/Space, skip disabled options without wrapping, highlight, activedescendant, Tab picks', async function (assert) {
    class State {
      @tracked value?: string = undefined;
    }
    const state = new State();
    const onChange = (value: string) => (state.value = value);
    await render(
      <template>
        <EuiSuperSelect @options={{FIRST_DISABLED}} @valueOfSelected={{state.value}} @onChange={{onChange}} data-c="k" />
      </template>
    );

    await triggerKeyEvent('[data-c="k"]', 'keydown', 'ArrowDown');
    await waitUntil(() => document.activeElement?.classList.contains('euiSuperSelect__item'));
    const [off, warning, minor, critical, info] = items();
    assert.strictEqual(document.activeElement, warning, 'the first enabled option (disabled first skipped)');
    assert.dom(listbox()).hasAria('activedescendant', warning!.id);
    assert.strictEqual(css(warning!).backgroundColor, rgb(light.colors.backgroundBaseInteractiveHover), 'focused option highlight');
    assert.strictEqual(css(minor!).backgroundColor, 'rgba(0, 0, 0, 0)');

    await triggerKeyEvent(warning!, 'keydown', 'ArrowUp');
    assert.strictEqual(document.activeElement, warning, 'no wrapping, disabled skipped going up');

    await triggerKeyEvent(warning!, 'keydown', 'ArrowDown');
    assert.strictEqual(document.activeElement, minor);
    assert.dom(listbox()).hasAria('activedescendant', minor!.id);
    await triggerKeyEvent(minor!, 'keydown', 'ArrowDown');
    assert.strictEqual(document.activeElement, info, 'the disabled option is skipped');
    assert.notStrictEqual(document.activeElement, critical);
    await triggerKeyEvent(info!, 'keydown', 'ArrowDown');
    assert.strictEqual(document.activeElement, info, 'no wrapping at the end');
    assert.strictEqual(css(warning!).backgroundColor, 'rgba(0, 0, 0, 0)', 'highlight follows focus');
    assert.strictEqual(css(info!).backgroundColor, rgb(light.colors.backgroundBaseInteractiveHover));
    assert.ok(off);

    await triggerKeyEvent(info!, 'keydown', 'Tab');
    assert.strictEqual(state.value, 'info', 'Tab picks the focused option (upstream)');
    assert.notOk(listbox());
    await waitUntil(() => document.activeElement === control('k'));

    await triggerKeyEvent('[data-c="k"]', 'keydown', ' ');
    await waitUntil(() => document.activeElement?.classList.contains('euiSuperSelect__item'));
    const selected = items()[4]!;
    assert.strictEqual(document.activeElement, selected, 'Space opens on the selected option');
    assert.strictEqual(css(selected).backgroundColor, rgb(light.colors.backgroundBaseInteractiveSelectHover), 'selected + focused');
    await triggerKeyEvent(selected, 'keydown', 'ArrowUp');
    assert.strictEqual(css(selected).backgroundColor, rgb(light.colors.backgroundBaseInteractiveSelect), 'selected');

    await triggerKeyEvent(document.activeElement!, 'keydown', 'Escape');
    assert.notOk(listbox());
    assert.strictEqual(state.value, 'info', 'Escape does not change the value');
  });

  test('aria: listbox label and description, option semantics, form row labelling', async function (assert) {
    await render(
      <template>
        <EuiFormRow @label="Severity" @id="sev">
          <EuiSuperSelect @options={{OPTIONS}} @valueOfSelected="minor" @id="sev" data-c="row" />
        </EuiFormRow>
        <EuiSuperSelect @options={{OPTIONS}} aria-labelledby="custom" data-c="own" />
        <span id="custom">Custom</span>
      </template>
    );

    const row = control('row');
    assert.dom(row).hasAttribute('id', 'sev-button');
    assert.dom(row).hasAria('labelledby', 'sev-button sev-label', 'value + form row label (upstream)');
    assert.dom('input[type="hidden"]#sev').exists();
    assert.dom(control('own')).hasAria('labelledby', 'custom', "the caller's aria-labelledby is kept");

    await open('[data-c="row"]');
    const lb = listbox()!;
    assert.dom(lb).hasAttribute('role', 'listbox').hasAttribute('tabindex', '0');
    assert.dom(lb).hasAria('label', 'Select listbox');
    const description = document.getElementById(lb.getAttribute('aria-describedby')!)!;
    assert.dom(description).hasText(
      'You are in a form selector and must select a single option. Use the Up and Down arrow keys to navigate or Escape to close.'
    );
    assert.ok(description.closest('.euiScreenReaderOnly'), 'screen reader only');
    assert.strictEqual(new Set(items().map((item) => item.id)).size, 4, 'unique option ids');
    assert.dom(lb).hasAria('activedescendant', items()[1]!.id, 'the selected option is current');
    assert.dom(items()[1]).doesNotHaveAttribute('aria-current');
  });

  test('reactive args update in place without replacing elements', async function (assert) {
    class State {
      @tracked compressed = false;
      @tracked fullWidth = false;
      @tracked invalid = false;
      @tracked loading = false;
      @tracked disabled = false;
      @tracked value = 'minor';
      @tracked options = OPTIONS;
    }
    const state = new State();
    await render(
      <template>
        <div style="width: 800px">
          <EuiSuperSelect
            @options={{state.options}}
            @valueOfSelected={{state.value}}
            @compressed={{state.compressed}}
            @fullWidth={{state.fullWidth}}
            @isInvalid={{state.invalid}}
            @isLoading={{state.loading}}
            @disabled={{state.disabled}}
            data-c="r"
          />
        </div>
      </template>
    );

    const button = control('r');
    const layout = layoutOf(button);
    state.compressed = true;
    state.fullWidth = true;
    state.invalid = true;
    state.loading = true;
    await settled();
    assert.strictEqual(control('r'), button);
    assert.strictEqual(layoutOf(button), layout);
    assert.strictEqual(box(button).height, 32);
    assert.strictEqual(box(button).width, 800);
    assert.dom(button).hasClass('euiSuperSelectControl-isInvalid').hasClass('euiSuperSelectControl-isLoading');
    assert.strictEqual(css(button).outlineColor, rgb(forms(light)['borderInvalid']!));

    state.compressed = false;
    state.invalid = false;
    state.loading = false;
    state.disabled = true;
    state.value = 'info';
    state.options = OPTIONS.map((option) => ({ ...option, inputDisplay: `${option.inputDisplay}!` }));
    await settled();
    assert.strictEqual(control('r'), button);
    assert.strictEqual(box(button).height, 40);
    assert.dom(button).doesNotHaveClass('euiSuperSelectControl-isInvalid').isDisabled().hasText('Info!');
    assert.strictEqual(css(button).cursor, 'not-allowed');
  });

  test('light/dark from the nearest provider, sibling isolation and JS-object token overrides', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'light';
      @tracked overrides: EuiBorealisOverrides = {};
    }
    const state = new State();
    const own: EuiBorealisOverrides = { border: { radius: { control: '13px' } }, size: { xxl: '48px' } };
    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}} @borealisOverrides={{state.overrides}}>
          <EuiSuperSelect @options={{OPTIONS}} @valueOfSelected="minor" data-c="parent" />
          <EuiEmotionProvider @borealisOverrides={{own}}>
            <EuiSuperSelect @options={{OPTIONS}} @valueOfSelected="minor" data-c="child" />
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <EuiSuperSelect @options={{OPTIONS}} data-c="sibling" />
        </EuiEmotionProvider>
      </template>
    );

    const parent = control('parent');
    assert.strictEqual(css(parent).backgroundColor, rgb(forms(light)['background']!));
    const child = control('child');
    assert.strictEqual(box(child).height, 48, 'size override drives the control height');
    assert.strictEqual(css(child).lineHeight, '48px');
    assert.strictEqual(css(child).borderTopLeftRadius, '13px');

    state.mode = 'dark';
    await settled();
    assert.strictEqual(control('parent'), parent, 'no replacement');
    assert.strictEqual(css(parent).backgroundColor, rgb(forms(dark)['background']!));
    assert.strictEqual(css(parent).color, rgb(dark.colors.textParagraph));
    assert.strictEqual(css(parent).boxShadow, inset(forms(dark)['border']!));
    assert.strictEqual(css(child).backgroundColor, rgb(forms(dark)['background']!), 'child inherits the mode');
    assert.strictEqual(css(control('sibling')).backgroundColor, rgb(forms(light)['background']!), 'sibling isolated');

    await open('[data-c="parent"]');
    const [warning, minor] = items();
    assert.strictEqual(css(warning!).color, rgb(dark.colors.textParagraph), 'portaled options keep the dark theme');
    assert.strictEqual(css(minor!).color, rgb(dark.colors.textPrimary));
    await triggerKeyEvent(minor!, 'keydown', 'ArrowUp');
    assert.strictEqual(css(minor!).backgroundColor, rgb(dark.colors.backgroundBaseInteractiveSelect));
    await triggerKeyEvent(document.activeElement!, 'keydown', 'Escape');

    state.overrides = { border: { radius: { control: '4px' } } };
    await settled();
    assert.strictEqual(css(parent).borderTopLeftRadius, '4px');
    assert.strictEqual(css(child).borderTopLeftRadius, '13px', 'nearest override wins');
    assert.strictEqual(css(control('sibling')).borderTopLeftRadius, light.border.radius.control);

    await open('[data-c="child"]');
    assert.strictEqual(css(items()[0]!).borderTopLeftRadius, '13px', 'option radius from the nearest override');
  });

  test('RTL: logical padding, end-side arrow and start alignment flip', async function (assert) {
    await render(
      <template>
        <div dir="rtl" style="width: 600px">
          <EuiSuperSelect @options={{OPTIONS}} @valueOfSelected="minor" data-c="rtl" />
        </div>
      </template>
    );

    const button = control('rtl');
    assert.strictEqual(css(button).paddingLeft, '36px', 'the arrow affordance is on the left');
    assert.strictEqual(css(button).paddingRight, '12px');
    assert.strictEqual(css(button).textAlign, 'start');
    const arrow = layoutOf(button).querySelector('[data-icon-type="chevronSingleDown"]')!;
    assert.true(box(arrow).left < box(button).left + 40, 'the arrow sits on the left');

    // the list is portaled to the body: it follows the document direction
    document.body.dir = 'rtl';
    try {
      await open('[data-c="rtl"]');
      const text = q('.euiListItemLayout__text', items()[0]);
      const icon = q('.euiListItemLayout__icon', items()[0]);
      assert.true(icon.getBoundingClientRect().left > text.getBoundingClientRect().left, 'the check column is on the right');
      assert.strictEqual(css(items()[0]!).textAlign, 'start');
    } finally {
      document.body.dir = '';
    }
  });

  test('high contrast: real control border and selected option outline; standard isolated', async function (assert) {
    await render(
      <template>
        <EuiEmotionProvider @highContrastMode="preferred">
          <EuiSuperSelect @options={{OPTIONS}} @valueOfSelected="minor" data-c="hc" />
        </EuiEmotionProvider>
        <EuiSuperSelect @options={{OPTIONS}} data-c="std" />
      </template>
    );

    const hc = css(control('hc'));
    assert.strictEqual(hc.borderTopStyle, 'solid');
    assert.strictEqual(hc.borderTopWidth, '1px');
    assert.strictEqual(hc.borderTopColor, rgb(lightHc.border.color));
    assert.strictEqual(css(control('std')).borderTopStyle, 'none');
    assert.strictEqual(css(control('std')).boxShadow, inset(forms(light)['border']!));

    await open('[data-c="hc"]');
    const minor = items()[1]!;
    await triggerKeyEvent(minor, 'keydown', 'ArrowUp');
    assert.strictEqual(css(minor).outlineStyle, 'solid');
    assert.strictEqual(css(minor).outlineColor, rgb(lightHc.colors.borderStrongPrimary));
  });

  test('EuiSuperSelectControl standalone: hidden input, inputDisplay block, prepend/append and deprecated screenReaderId', async function (assert) {
    await render(
      <template>
        <EuiSuperSelectControl @options={{OPTIONS}} @value="warning" @name="n" @screenReaderId="sr" data-c="c">
          <:inputDisplay as |option|><b>{{option.value}}</b></:inputDisplay>
          <:append as |className|><span class={{className}}>Unit</span></:append>
        </EuiSuperSelectControl>
      </template>
    );

    assert.dom('[data-c="c"] b').hasText('warning');
    assert.dom('input[type="hidden"][name="n"]').hasValue('warning');
    assert.dom('#sr').doesNotExist('no separate announcement (upstream 123)');
    assert.dom(layoutOf(control('c')).querySelector('.euiFormControlLayout__append')).hasText('Unit');
    assert.strictEqual(css(control('c')).boxShadow, 'none');
  });
});
