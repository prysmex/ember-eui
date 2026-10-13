import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import {
  click,
  fillIn,
  focus,
  render,
  settled,
  triggerEvent,
  triggerKeyEvent
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiFieldNumber from '#src/components/eui-field-number.gts';
import EuiFieldPassword from '#src/components/eui-field-password.gts';
import EuiFieldSearch from '#src/components/eui-field-search.gts';
import EuiFieldText from '#src/components/eui-field-text.gts';
import EuiFormControlLayout from '#src/components/eui-form-control-layout.gts';
import EuiFormControlLayoutDelimited from '#src/components/eui-form-control-layout-delimited.gts';
import EuiSelect from '#src/components/eui-select.gts';
import EuiTextArea from '#src/components/eui-text-area.gts';
import { euiFormControlStyles } from '#src/utils/eui/styles.generated.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';
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

/** Upstream `euiFormControlText` font size (euiFontSize 's'). */
const controlFontSize = /font-size: ([^;]+);/.exec(
  euiFormControlStyles(lightContext).shared
)![1]!;

function el<T extends Element = HTMLElement>(root: Element, selector: string) {
  const element = root.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function style(root: Element, selector: string, pseudo?: string) {
  return getComputedStyle(el(root, selector), pseudo);
}

function layoutOf(element: Element) {
  return element.closest('.euiFormControlLayout')!;
}

/**
 * Measured layout box in CSS pixels. The ember-qunit container is scaled, so
 * client rects are divided by that scale to give real rendered dimensions.
 */
function box(element: Element) {
  const container = document.querySelector<HTMLElement>('#ember-testing')!;
  const scale = container.getBoundingClientRect().width / container.offsetWidth;
  const rect = element.getBoundingClientRect();
  return {
    width: Math.round((rect.width / scale) * 100) / 100,
    height: Math.round((rect.height / scale) * 100) / 100,
    left: rect.left / scale,
    right: rect.right / scale,
    top: rect.top / scale,
    bottom: rect.bottom / scale
  };
}

const inset = (color: string, width = '1px') =>
  `${rgb(color)} 0px 0px 0px ${width} inset`;

const OPTIONS = [
  { value: 'a', text: 'Option A' },
  { value: 'b', text: 'Option B' },
  { value: 'c', text: 'Option C', disabled: true }
];

module('Integration | Component | Borealis form controls', function (hooks) {
  setupRenderingTest(hooks);

  test('every input control: upstream heights, padding, width, typography and default border', async function (assert) {
    const options = OPTIONS;
    const noop = () => {};
    await render(
      <template>
        <div style="width: 800px">
          <EuiFieldText data-c="text" />
          <EuiFieldText @compressed={{true}} data-c="text-s" />
          <EuiFieldNumber data-c="number" />
          <EuiFieldNumber @compressed={{true}} data-c="number-s" />
          <EuiFieldPassword @type="password" data-c="password" />
          <EuiFieldPassword
            @type="password"
            @compressed={{true}}
            data-c="password-s"
          />
          <EuiFieldSearch @onSearch={{noop}} data-c="search" />
          <EuiFieldSearch
            @onSearch={{noop}}
            @compressed={{true}}
            data-c="search-s"
          />
          <EuiSelect @options={{options}} data-c="select" />
          <EuiSelect
            @options={{options}}
            @compressed={{true}}
            data-c="select-s"
          />
        </div>
      </template>
    );
    const f = forms(light);
    const fontSize = fontSizePx(controlFontSize);
    for (const name of ['text', 'number', 'password', 'search', 'select']) {
      for (const compressed of [false, true]) {
        const key = compressed ? `${name}-s` : name;
        const input = el(this.element, `[data-c="${key}"]`);
        const computed = getComputedStyle(input);
        const height = compressed ? 32 : 40;
        const pad = compressed ? 8 : 12;
        assert.strictEqual(box(input).height, height, `${key} height`);
        assert.strictEqual(
          box(layoutOf(input)).height,
          height,
          `${key} layout height`
        );
        assert.strictEqual(computed.boxSizing, 'border-box');
        assert.strictEqual(computed.marginTop, '0px', `${key} reset margin`);
        // Icons: search has a left icon, password a left lock icon, select a
        // right dropdown arrow. Each adds the 24px upstream affordance.
        const left = ['search', 'password'].includes(name) ? 24 : 0;
        const right = name === 'select' ? 24 : 0;
        assert.strictEqual(
          computed.paddingInlineStart,
          `${pad + left}px`,
          `${key} start padding`
        );
        assert.strictEqual(
          computed.paddingInlineEnd,
          `${pad + right}px`,
          `${key} end padding`
        );
        if (name === 'select') {
          assert.strictEqual(computed.paddingTop, '0px', 'select block pad');
          assert.strictEqual(computed.lineHeight, `${height}px`);
          assert.strictEqual(computed.appearance, 'none');
        } else {
          assert.strictEqual(computed.paddingTop, `${pad}px`);
        }
        assert.strictEqual(computed.borderRadius, '8px');
        assert.true(computed.fontFamily.includes('Inter'), `${key} font`);
        assert.strictEqual(computed.fontSize, fontSize, `${key} font size`);
        assert.strictEqual(computed.color, rgb(light.colors.textParagraph));
        assert.strictEqual(computed.backgroundColor, rgb(f['background']!));
        assert.strictEqual(computed.borderTopStyle, 'none');
        assert.strictEqual(computed.boxShadow, inset(f['border']!));
        assert.strictEqual(computed.maxWidth, '400px', `${key} form width`);
        assert.strictEqual(box(input).width, 400);
        assert.strictEqual(getComputedStyle(layoutOf(input)).maxWidth, '400px');
      }
    }
    assert.strictEqual(
      el<HTMLInputElement>(this.element, '[data-c="search"]').type,
      'search',
      'upstream search semantics'
    );
  });

  test('fullWidth stretches the control and its layout', async function (assert) {
    const options = OPTIONS;
    await render(
      <template>
        <div style="width: 640px">
          <EuiFieldText @fullWidth={{true}} data-c="text" />
          <EuiSelect @options={{options}} @fullWidth={{true}} data-c="select" />
          <EuiTextArea @fullWidth={{true}} data-c="area" />
          <EuiFormControlLayoutDelimited @fullWidth={{true}} data-c="delimited">
            <:startControl as |c|><EuiFieldNumber
                @controlOnly={{true}}
                class={{c}}
              /></:startControl>
            <:endControl as |c|><EuiFieldNumber
                @controlOnly={{true}}
                class={{c}}
              /></:endControl>
          </EuiFormControlLayoutDelimited>
        </div>
      </template>
    );
    for (const key of ['text', 'select', 'area', 'delimited']) {
      const element = el(this.element, `[data-c="${key}"]`);
      assert.strictEqual(getComputedStyle(element).maxWidth, '100%', key);
      assert.strictEqual(box(element).width, 640, `${key} fills`);
    }
    assert.strictEqual(
      box(layoutOf(el(this.element, '[data-c="text"]'))).width,
      640
    );
  });

  test('invalid, disabled, read-only and focus states use the upstream state tokens', async function (assert) {
    await render(
      <template>
        <EuiFieldText @isInvalid={{true}} data-c="invalid" />
        <EuiFieldText @isInvalid={{true}} data-c="invalid-focus" />
        <EuiFieldText @disabled={{true}} @placeholder="Off" data-c="disabled" />
        <EuiFieldText @readOnly={{true}} @value="Fixed" data-c="readonly" />
        <EuiFieldText data-c="focus" />
        <EuiFieldText required data-c="native-invalid" />
      </template>
    );
    const f = forms(light);
    const invalid = el<HTMLInputElement>(this.element, '[data-c="invalid"]');
    const iStyle = getComputedStyle(invalid);
    assert.strictEqual(invalid.getAttribute('aria-invalid'), 'true');
    assert.false(invalid.validity.valid, 'native validity');
    assert.strictEqual(iStyle.boxShadow, 'none');
    assert.strictEqual(iStyle.outlineStyle, 'solid');
    assert.strictEqual(iStyle.outlineWidth, '1px');
    assert.strictEqual(iStyle.outlineColor, rgb(f['borderInvalid']!));
    assert.strictEqual(iStyle.outlineOffset, '-1px');
    assert.strictEqual(
      iStyle.paddingInlineEnd,
      '36px',
      'room for the warning icon'
    );
    const icons = layoutOf(invalid).querySelectorAll('.euiFormControlLayoutIcons');
    assert.strictEqual(icons.length, 1, 'one (right) icon group');
    assert.dom(icons[0]!.querySelector('svg')).exists('warning icon');

    // Focus wins over invalid (upstream `:not(:focus)`).
    await focus('[data-c="invalid-focus"]');
    const fStyle = style(this.element, '[data-c="invalid-focus"]');
    assert.strictEqual(fStyle.outlineWidth, '2px');
    assert.strictEqual(fStyle.outlineColor, rgb(f['borderFocused']!));

    await focus('[data-c="focus"]');
    const focused = style(this.element, '[data-c="focus"]');
    assert.strictEqual(focused.outlineStyle, 'solid');
    assert.strictEqual(focused.outlineWidth, '2px');
    assert.strictEqual(focused.outlineOffset, '-2px');
    assert.strictEqual(focused.outlineColor, rgb(f['borderFocused']!));
    assert.strictEqual(focused.boxShadow, 'none');
    assert.strictEqual(focused.zIndex, '1');

    const disabled = style(this.element, '[data-c="disabled"]');
    assert.strictEqual(disabled.backgroundColor, rgb(f['backgroundDisabled']!));
    assert.strictEqual(disabled.color, rgb(f['colorDisabled']!));
    assert.strictEqual(disabled.cursor, 'not-allowed');
    assert.dom('[data-c="disabled"]').isDisabled();
    assert.true(
      layoutOf(el(this.element, '[data-c="disabled"]')).classList.contains(
        'euiFormControlLayout-isDisabled'
      )
    );

    const readOnly = style(this.element, '[data-c="readonly"]');
    assert.dom('[data-c="readonly"]').hasAttribute('readonly');
    assert.strictEqual(readOnly.backgroundColor, rgb(f['backgroundReadOnly']!));
    assert.strictEqual(readOnly.cursor, 'default');
    assert.strictEqual(readOnly.boxShadow, inset(f['border']!));
    assert.strictEqual(readOnly.color, rgb(light.colors.textParagraph));
    assert.true(
      layoutOf(el(this.element, '[data-c="readonly"]')).classList.contains(
        'euiFormControlLayout-readOnly'
      )
    );

    // Native `:invalid` (here `required`) gets the same danger outline.
    const native = style(this.element, '[data-c="native-invalid"]');
    assert.strictEqual(native.outlineColor, rgb(f['borderInvalid']!));
    assert.dom('[data-c="native-invalid"]').doesNotHaveAttribute('aria-invalid');
  });

  test('placeholder color, including disabled', async function (assert) {
    await render(
      <template>
        <EuiFieldText @placeholder="Name" data-c="text" />
        <EuiTextArea placeholder="Notes" data-c="area" />
        <EuiFieldText @placeholder="Off" @disabled={{true}} data-c="disabled" />
        <EuiEmotionProvider @colorMode="dark">
          <EuiFieldText @placeholder="Dark" data-c="dark" />
        </EuiEmotionProvider>
      </template>
    );
    for (const key of ['text', 'area', 'disabled']) {
      const placeholder = style(this.element, `[data-c="${key}"]`, '::placeholder');
      assert.strictEqual(
        placeholder.color,
        rgb(forms(light)['colorDisabled']!),
        `${key} placeholder`
      );
      assert.strictEqual(placeholder.opacity, '1');
    }
    assert.strictEqual(
      style(this.element, '[data-c="dark"]', '::placeholder').color,
      rgb(forms(dark)['colorDisabled']!)
    );
  });

  test('icons: absolute placement, affordance counts, clear button, spinner and RTL', async function (assert) {
    let cleared = 0;
    const clear = () => cleared++;
    await render(
      <template>
        <div style="width: 500px">
          <EuiFormControlLayout
            @icon="user"
            @clear={{clear}}
            @isLoading={{true}}
            data-c="layout"
          >
            <input class="field" data-c="input" />
          </EuiFormControlLayout>
          <EuiFieldText
            @icon="user"
            @compressed={{true}}
            data-c="compressed"
          />
          <EuiFormControlLayout @icon="calendar" @iconSide="right" data-c="right">
            <input data-c="right-input" />
          </EuiFormControlLayout>
          <EuiFormControlLayout
            @clear={{clear}}
            @disabled={{true}}
            data-c="disabled"
          >
            <input disabled />
          </EuiFormControlLayout>
        </div>
        <div dir="rtl" style="width: 500px">
          <EuiFieldText @icon="user" @clear={{clear}} data-c="rtl" />
        </div>
      </template>
    );
    const layout = el(this.element, '[data-c="layout"]');
    const wrapper = el(layout, '.euiFormControlLayout__childrenWrapper');
    assert.strictEqual(getComputedStyle(wrapper).position, 'relative');
    assert.strictEqual(
      wrapper.style.getPropertyValue('--euiFormControlLeftIconsCount').trim(),
      '1'
    );
    assert.strictEqual(
      wrapper.style.getPropertyValue('--euiFormControlRightIconsCount').trim(),
      '2',
      'clear + spinner'
    );
    const [left, right] = layout.querySelectorAll<HTMLElement>(
      '.euiFormControlLayoutIcons'
    );
    assert.ok(left!.querySelector('.euiFormControlLayoutCustomIcon'));
    assert.ok(right!.querySelector('.euiFormControlLayoutClearButton'));
    assert.ok(right!.querySelector('.euiBorealisLoadingSpinner'));
    const leftStyle = getComputedStyle(left!);
    assert.strictEqual(leftStyle.position, 'absolute');
    assert.strictEqual(leftStyle.insetInlineStart, '12px');
    assert.strictEqual(leftStyle.pointerEvents, 'none');
    assert.strictEqual(leftStyle.display, 'flex');
    assert.strictEqual(leftStyle.columnGap, '6px');
    assert.strictEqual(getComputedStyle(right!).insetInlineEnd, '12px');
    assert.strictEqual(
      getComputedStyle(
        el(left!, '.euiFormControlLayoutCustomIcon')
      ).pointerEvents,
      'none',
      'decorative icon lets clicks reach the input'
    );
    const wrapperBox = box(wrapper);
    assert.true(box(left!).left - wrapperBox.left >= 11, 'icon at start');
    assert.true(wrapperBox.right - box(right!).right >= 11, 'icons at end');

    const compressedIcons = el(
      layoutOf(el(this.element, '[data-c="compressed"]')),
      '.euiFormControlLayoutIcons'
    );
    assert.strictEqual(getComputedStyle(compressedIcons).insetInlineStart, '8px');
    assert.strictEqual(getComputedStyle(compressedIcons).columnGap, '4px');

    const rightWrapper = el(
      el(this.element, '[data-c="right"]'),
      '.euiFormControlLayout__childrenWrapper'
    );
    assert.strictEqual(
      rightWrapper.style.getPropertyValue('--euiFormControlRightIconsCount').trim(),
      '1'
    );
    assert.strictEqual(
      rightWrapper.style.getPropertyValue('--euiFormControlLeftIconsCount'),
      '',
      'zero counts are omitted'
    );

    const clearButton = el<HTMLButtonElement>(
      layout,
      '.euiFormControlLayoutClearButton'
    );
    const cStyle = getComputedStyle(clearButton);
    assert.strictEqual(clearButton.type, 'button');
    assert.strictEqual(clearButton.getAttribute('aria-label'), 'Clear input');
    assert.strictEqual(box(clearButton).width, 16);
    assert.strictEqual(box(clearButton).height, 16);
    assert.strictEqual(cStyle.borderTopLeftRadius, '50%');
    assert.strictEqual(
      cStyle.borderTopColor,
      rgb(forms(light)['clearButtonBackground']!)
    );
    assert.strictEqual(cStyle.pointerEvents, 'all');
    assert.strictEqual(
      getComputedStyle(el(clearButton, '.euiFormControlLayoutClearButton__icon'))
        .fill,
      rgb(light.colors.emptyShade)
    );
    await click(clearButton);
    assert.strictEqual(cleared, 1);

    const disabled = el(this.element, '[data-c="disabled"]');
    assert.dom(el(disabled, '.euiFormControlLayoutClearButton')).isDisabled();
    assert.strictEqual(
      getComputedStyle(el(disabled, '.euiFormControlLayoutIcons')).color,
      rgb(forms(light)['controlBackgroundDisabled']!)
    );

    // RTL: logical properties flip the icon sides.
    const rtl = el(this.element, '[data-c="rtl"]');
    const rtlBox = box(rtl);
    const [rtlStart, rtlEnd] = layoutOf(rtl).querySelectorAll(
      '.euiFormControlLayoutIcons'
    );
    assert.true(
      box(rtlStart!).left > rtlBox.left + rtlBox.width / 2,
      'start icon on the right'
    );
    assert.true(
      box(rtlEnd!).right < rtlBox.left + rtlBox.width / 2,
      'clear button on the left'
    );
    assert.strictEqual(getComputedStyle(rtl).paddingRight, '36px');
    assert.strictEqual(getComputedStyle(rtl).paddingLeft, '36px');
  });

  test('prepend/append groups: wrapper, dividers, group border and RTL', async function (assert) {
    await render(
      <template>
        <div style="width: 600px">
          <EuiFieldText data-c="text">
            <:prepend as |classes|><span
                class="euiFormLabel {{classes}}"
                data-pre
              >@</span></:prepend>
            <:append as |classes|><span
                class="euiText {{classes}}"
                data-post
              >.com</span></:append>
          </EuiFieldText>
          <EuiFieldText @compressed={{true}} data-c="compressed">
            <:prepend>Pre</:prepend>
          </EuiFieldText>
          <EuiFieldText @disabled={{true}} data-c="disabled">
            <:append>Post</:append>
          </EuiFieldText>
          <EuiFieldText data-c="plain" />
        </div>
        <div dir="rtl" style="width: 600px">
          <EuiFieldText data-c="rtl">
            <:prepend>Pre</:prepend>
          </EuiFieldText>
        </div>
      </template>
    );
    const f = forms(light);
    const input = el(this.element, '[data-c="text"]');
    const layout = layoutOf(input);
    assert.true(layout.classList.contains('euiFormControlLayout--group'));
    const prepend = el(layout, ':scope > .euiFormControlLayout__prepend');
    const append = el(layout, ':scope > .euiFormControlLayout__append');
    assert.strictEqual(prepend.querySelector('[data-pre]')?.textContent, '@');
    assert.strictEqual(append.querySelector('[data-post]')?.textContent, '.com');
    const rootStyle = getComputedStyle(layout);
    assert.strictEqual(rootStyle.display, 'flex');
    assert.strictEqual(rootStyle.overflow, 'hidden');
    assert.strictEqual(rootStyle.backgroundColor, rgb(f['background']!));
    assert.strictEqual(rootStyle.borderTopLeftRadius, '8px');
    const after = getComputedStyle(layout, '::after');
    assert.strictEqual(after.borderTopWidth, '1px');
    assert.strictEqual(after.borderTopColor, rgb(f['border']!));
    assert.strictEqual(after.pointerEvents, 'none');

    const iStyle = getComputedStyle(input);
    assert.strictEqual(iStyle.boxShadow, 'none', 'the group draws the border');
    assert.strictEqual(box(input).height, 40);
    assert.strictEqual(box(layout).height, 40);
    const wrapper = el(layout, '.euiFormControlLayout__childrenWrapper');
    assert.strictEqual(getComputedStyle(wrapper).flexGrow, '1');

    const pStyle = getComputedStyle(prepend);
    assert.strictEqual(pStyle.display, 'flex');
    assert.strictEqual(pStyle.flexShrink, '0');
    assert.strictEqual(pStyle.paddingInlineStart, '8px');
    const divider = getComputedStyle(prepend, '::before');
    assert.strictEqual(divider.borderInlineEndWidth, '1px');
    assert.strictEqual(divider.borderInlineEndColor, rgb(f['border']!));
    assert.strictEqual(divider.height, '24px');
    assert.strictEqual(
      getComputedStyle(append, '::before').borderInlineStartWidth,
      '1px'
    );
    assert.true(box(prepend).right <= box(input).left + 1, 'prepend first');
    assert.true(box(append).left >= box(input).right - 1, 'append last');
    assert.strictEqual(
      getComputedStyle(el(prepend, '[data-pre]')).lineHeight,
      '32px',
      'side text line height'
    );

    const compressed = layoutOf(el(this.element, '[data-c="compressed"]'));
    assert.strictEqual(box(compressed).height, 32);
    assert.strictEqual(
      getComputedStyle(
        el(compressed, '.euiFormControlLayout__prepend'),
        '::before'
      ).height,
      '16px'
    );

    const disabled = layoutOf(el(this.element, '[data-c="disabled"]'));
    assert.strictEqual(
      getComputedStyle(disabled).backgroundColor,
      rgb(f['backgroundDisabled']!)
    );
    assert.strictEqual(
      getComputedStyle(el(disabled, '.euiFormControlLayout__append'))
        .backgroundColor,
      rgb(f['backgroundDisabled']!)
    );

    const plain = layoutOf(el(this.element, '[data-c="plain"]'));
    assert.false(plain.classList.contains('euiFormControlLayout--group'));
    assert.strictEqual(
      plain.querySelectorAll(
        '.euiFormControlLayout__prepend, .euiFormControlLayout__append'
      ).length,
      0,
      'no empty side wrappers'
    );

    const rtl = el(this.element, '[data-c="rtl"]');
    const rtlPrepend = el(layoutOf(rtl), '.euiFormControlLayout__prepend');
    assert.true(
      box(rtlPrepend).left >= box(rtl).right - 1,
      'RTL prepend sits on the right'
    );
  });

  test('EuiFieldPassword: dual toggle in the append, focus, labels and disabled', async function (assert) {
    class State {
      @tracked disabled = false;
    }
    const state = new State();
    const refs: HTMLInputElement[] = [];
    const inputRef = (element: HTMLInputElement) => refs.push(element);
    await render(
      <template>
        <EuiFieldPassword
          @value="secret"
          @disabled={{state.disabled}}
          @inputRef={{inputRef}}
          data-c="dual"
        />
        <EuiFieldPassword @type="password" data-c="plain" />
        <EuiFieldPassword @type="text" @readOnly={{true}} data-c="text" />
      </template>
    );
    const input = el<HTMLInputElement>(this.element, '[data-c="dual"]');
    const layout = layoutOf(input);
    assert.deepEqual(refs, [input]);
    assert.strictEqual(input.type, 'password');
    assert.true(layout.classList.contains('euiFormControlLayout--group'));
    const toggle = el<HTMLButtonElement>(
      layout,
      ':scope > .euiFormControlLayout__append > .euiButtonIcon'
    );
    assert.true(
      toggle.getAttribute('aria-label')!.startsWith('Show password as plain text')
    );
    assert.strictEqual(box(toggle).width, 32, 'side node sizes the button');
    assert.strictEqual(box(toggle).height, 32);
    assert.strictEqual(getComputedStyle(input).boxShadow, 'none', 'in group');

    await click(toggle);
    assert.strictEqual(el(this.element, '[data-c="dual"]'), input, 'same input');
    assert.strictEqual(input.type, 'text');
    assert.strictEqual(document.activeElement, input, 'focus returns to input');
    assert.strictEqual(toggle.getAttribute('aria-label'), 'Mask password');
    await click(toggle);
    assert.strictEqual(input.type, 'password');

    state.disabled = true;
    await settled();
    assert.dom(toggle).isDisabled();
    assert.dom(input).isDisabled();

    assert.dom('[data-c="plain"]').hasAttribute('type', 'password');
    assert.strictEqual(
      layoutOf(el(this.element, '[data-c="plain"]')).querySelector('.euiButtonIcon'),
      null
    );
    assert.dom('[data-c="text"]').hasAttribute('type', 'text').hasAttribute('readonly');
  });

  test('EuiFieldSearch: clear, loading, incremental and a single search per Enter', async function (assert) {
    const searches: string[] = [];
    const onSearch = (value: string) => searches.push(value);
    class State {
      @tracked loading = false;
    }
    const state = new State();
    await render(
      <template>
        <EuiFieldSearch
          @value="dogs"
          @isLoading={{state.loading}}
          @onSearch={{onSearch}}
          data-c="search"
        />
        <EuiFieldSearch
          @incremental={{true}}
          @onSearch={{onSearch}}
          data-c="incremental"
        />
      </template>
    );
    const input = el<HTMLInputElement>(this.element, '[data-c="search"]');
    const wrapper = el(layoutOf(input), '.euiFormControlLayout__childrenWrapper');
    assert.strictEqual(input.type, 'search');
    assert.strictEqual(getComputedStyle(input).paddingInlineEnd, '36px');
    const clear = el(layoutOf(input), '.euiFormControlLayoutClearButton');
    assert.strictEqual(clear.getAttribute('aria-label'), 'Clear search input');

    state.loading = true;
    await settled();
    assert.ok(layoutOf(input).querySelector('.euiBorealisLoadingSpinner'));
    assert.strictEqual(
      wrapper.style.getPropertyValue('--euiFormControlRightIconsCount').trim(),
      '2'
    );
    assert.strictEqual(getComputedStyle(input).paddingInlineEnd, '60px');

    await click(clear);
    assert.strictEqual(input.value, '');
    assert.strictEqual(document.activeElement, input);
    assert.deepEqual(searches, ['']);
    assert.strictEqual(
      layoutOf(input).querySelector('.euiFormControlLayoutClearButton'),
      null,
      'clear hides once empty'
    );

    // Enter in a search input fires both `search` and `change`.
    searches.length = 0;
    await fillIn(input, 'cats');
    assert.deepEqual(searches, ['cats'], 'change searches');
    await triggerEvent(input, 'search');
    await triggerEvent(input, 'change');
    assert.deepEqual(searches, ['cats'], 'no duplicate for the same value');

    searches.length = 0;
    const incremental = el<HTMLInputElement>(this.element, '[data-c="incremental"]');
    incremental.value = 'd';
    await triggerKeyEvent(incremental, 'keyup', 'D');
    assert.deepEqual(searches, ['d']);
    assert.strictEqual(
      getComputedStyle(incremental).appearance,
      'textfield',
      'upstream textfield appearance (native search decorations off)'
    );
  });

  test('EuiTextArea: rows, resize, padding, line height and states', async function (assert) {
    class State {
      @tracked resize: 'vertical' | 'horizontal' | 'both' | 'none' = 'vertical';
      @tracked compressed = false;
    }
    const state = new State();
    await render(
      <template>
        <EuiTextArea
          @resize={{state.resize}}
          @compressed={{state.compressed}}
          @value="Hello"
          data-c="area"
        />
        <EuiTextArea @isInvalid={{true}} data-c="invalid" />
        <EuiTextArea @readOnly={{true}} data-c="readonly" />
        <EuiTextArea @rows={{2}} data-c="rows" />
      </template>
    );
    const f = forms(light);
    const area = el<HTMLTextAreaElement>(this.element, '[data-c="area"]');
    const s = getComputedStyle(area);
    assert.strictEqual(area.rows, 6);
    assert.strictEqual(s.resize, 'vertical');
    assert.strictEqual(s.display, 'block');
    assert.strictEqual(s.paddingTop, '12px');
    assert.strictEqual(s.paddingInlineStart, '12px');
    assert.strictEqual(s.borderRadius, '8px');
    assert.strictEqual(s.boxShadow, inset(f['border']!));
    assert.strictEqual(s.maxWidth, '400px');
    assert.strictEqual(
      parseFloat(s.lineHeight) / parseFloat(s.fontSize),
      light.font.lineHeightMultiplier,
      'line height multiplier'
    );
    assert.true(box(area).height > 40, 'auto height, not the 40px control');

    for (const resize of ['horizontal', 'both', 'none'] as const) {
      state.resize = resize;
      await settled();
      assert.strictEqual(getComputedStyle(area).resize, resize);
    }
    state.compressed = true;
    await settled();
    assert.strictEqual(el(this.element, '[data-c="area"]'), area, 'same element');
    assert.strictEqual(area.rows, 3);
    assert.strictEqual(getComputedStyle(area).paddingTop, '8px');

    const invalid = el<HTMLTextAreaElement>(this.element, '[data-c="invalid"]');
    assert.strictEqual(invalid.getAttribute('aria-invalid'), 'true');
    assert.strictEqual(
      getComputedStyle(invalid).outlineColor,
      rgb(f['borderInvalid']!)
    );
    assert.strictEqual(
      style(this.element, '[data-c="readonly"]').backgroundColor,
      rgb(f['backgroundReadOnly']!)
    );
    assert.strictEqual(el<HTMLTextAreaElement>(this.element, '[data-c="rows"]').rows, 2);
  });

  test('EuiSelect: dropdown arrow, line height, groups, options and change', async function (assert) {
    const options = OPTIONS;
    const changes: string[] = [];
    const onChange = (e: Event) =>
      changes.push((e.target as HTMLSelectElement).value);
    await render(
      <template>
        <EuiSelect
          @options={{options}}
          @value="b"
          data-c="select"
          {{on "change" onChange}}
        />
        <EuiSelect
          @options={{options}}
          @hasNoInitialSelection={{true}}
          data-c="empty"
        />
        <EuiSelect @options={{options}} @disabled={{true}} data-c="disabled" />
        <EuiSelect @options={{options}} data-c="group">
          <:prepend>Pick</:prepend>
        </EuiSelect>
        <EuiSelect @options={{options}} @compressed={{true}} data-c="group-s">
          <:append>Unit</:append>
        </EuiSelect>
      </template>
    );
    const select = el<HTMLSelectElement>(this.element, '[data-c="select"]');
    assert.strictEqual(select.value, 'b');
    assert.strictEqual(select.options.length, 3);
    assert.true(select.options[2]!.disabled);
    const icons = layoutOf(select).querySelectorAll('.euiFormControlLayoutIcons');
    assert.strictEqual(icons.length, 1);
    assert.ok(icons[0]!.querySelector('.euiFormControlLayoutCustomIcon svg'));
    assert.true(box(icons[0]!).left > box(select).left + box(select).width / 2);

    await fillIn(select, 'a');
    assert.deepEqual(changes, ['a']);

    const empty = el<HTMLSelectElement>(this.element, '[data-c="empty"]');
    assert.strictEqual(empty.value, '');
    assert.strictEqual(empty.options.length, 4);

    const disabled = el(this.element, '[data-c="disabled"]');
    assert.strictEqual(
      layoutOf(disabled).querySelector('.euiFormControlLayoutIcons'),
      null,
      'no dropdown arrow while disabled (upstream)'
    );
    assert.strictEqual(getComputedStyle(disabled).paddingInlineEnd, '12px');

    const group = style(this.element, '[data-c="group"]');
    assert.strictEqual(group.lineHeight, '38px', 'in-group line height');
    assert.strictEqual(group.boxShadow, 'none');
    assert.strictEqual(
      style(this.element, '[data-c="group-s"]').lineHeight,
      '30px'
    );
  });

  test('native events and attributes stay on the real control', async function (assert) {
    const events: string[] = [];
    const log = (name: string) => (e: Event) =>
      events.push(`${name}:${(e.target as HTMLInputElement).value}`);
    const onText = log('text');
    const onNumber = log('number');
    const onArea = log('area');
    const onChange = log('change');
    const refs: Element[] = [];
    const inputRef = (element: Element | null) => element && refs.push(element);
    await render(
      <template>
        <EuiFieldText
          name="first"
          aria-describedby="help"
          data-test-text
          @inputRef={{inputRef}}
          {{on "input" onText}}
          {{on "change" onChange}}
        />
        <EuiFieldNumber
          @value={{5}}
          @min={{0}}
          @max={{10}}
          data-test-number
          {{on "input" onNumber}}
        />
        <EuiTextArea maxlength="20" data-test-area {{on "input" onArea}} />
      </template>
    );
    const text = el<HTMLInputElement>(this.element, '[data-test-text]');
    assert.strictEqual(text.tagName, 'INPUT');
    assert.strictEqual(text.name, 'first');
    assert.strictEqual(text.getAttribute('aria-describedby'), 'help');
    assert.deepEqual(refs, [text]);
    await fillIn(text, 'Ada');
    const number = el<HTMLInputElement>(this.element, '[data-test-number]');
    assert.strictEqual(number.step, 'any', 'upstream default step');
    await fillIn(number, '2.5');
    assert.true(number.validity.valid, 'decimals are valid with step any');
    await fillIn('[data-test-area]', 'Note');
    assert.deepEqual(events, [
      'text:Ada',
      'change:Ada',
      'number:2.5',
      'area:Note'
    ]);
    assert.dom('[data-test-area]').hasAttribute('maxlength', '20');

    // Native number validity is announced (upstream `isNativelyInvalid`).
    assert.dom(number).doesNotHaveAttribute('aria-invalid');
    number.value = '42';
    await triggerKeyEvent(number, 'keyup', '2');
    assert.dom(number).hasAttribute('aria-invalid', 'true');
    assert.strictEqual(
      getComputedStyle(number).outlineColor,
      rgb(forms(light)['borderInvalid']!)
    );
  });

  test('reactive args restyle in place without replacing the control', async function (assert) {
    class State {
      @tracked compressed = false;
      @tracked fullWidth = false;
      @tracked invalid = false;
      @tracked disabled = false;
      @tracked readOnly = false;
      @tracked loading = false;
    }
    const state = new State();
    const options = OPTIONS;
    await render(
      <template>
        <div style="width: 700px">
          <EuiFieldText
            @compressed={{state.compressed}}
            @fullWidth={{state.fullWidth}}
            @isInvalid={{state.invalid}}
            @disabled={{state.disabled}}
            @readOnly={{state.readOnly}}
            @isLoading={{state.loading}}
            data-c="text"
          />
          <EuiSelect
            @options={{options}}
            @compressed={{state.compressed}}
            @isInvalid={{state.invalid}}
            @disabled={{state.disabled}}
            data-c="select"
          />
        </div>
      </template>
    );
    const f = forms(light);
    const text = el<HTMLInputElement>(this.element, '[data-c="text"]');
    const select = el<HTMLSelectElement>(this.element, '[data-c="select"]');
    const same = () => {
      assert.strictEqual(el(this.element, '[data-c="text"]'), text);
      assert.strictEqual(el(this.element, '[data-c="select"]'), select);
    };
    assert.strictEqual(box(text).height, 40);

    state.compressed = true;
    await settled();
    same();
    assert.strictEqual(box(text).height, 32);
    assert.strictEqual(box(select).height, 32);
    assert.strictEqual(getComputedStyle(select).lineHeight, '32px');

    state.fullWidth = true;
    await settled();
    same();
    assert.strictEqual(box(text).width, 700);

    state.invalid = true;
    await settled();
    same();
    assert.false(text.validity.valid);
    assert.strictEqual(text.getAttribute('aria-invalid'), 'true');
    assert.strictEqual(getComputedStyle(text).outlineColor, rgb(f['borderInvalid']!));
    assert.strictEqual(getComputedStyle(select).paddingInlineEnd, '56px', 'invalid + arrow (8 + 2×24)');

    state.invalid = false;
    state.loading = true;
    await settled();
    same();
    assert.true(text.validity.valid);
    assert.false(text.hasAttribute('aria-invalid'));
    assert.strictEqual(getComputedStyle(text).paddingInlineEnd, '32px');

    state.readOnly = true;
    await settled();
    same();
    assert.strictEqual(
      getComputedStyle(text).backgroundColor,
      rgb(f['backgroundReadOnly']!)
    );

    state.readOnly = false;
    state.disabled = true;
    await settled();
    same();
    assert.true(text.disabled);
    assert.strictEqual(
      getComputedStyle(text).backgroundColor,
      rgb(f['backgroundDisabled']!)
    );
    assert.true(select.disabled);
  });

  test('nearest-provider light/dark, sibling isolation and JS-object token overrides', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'light';
      @tracked overrides: EuiBorealisOverrides = {};
    }
    const state = new State();
    const own: EuiBorealisOverrides = {
      border: { radius: { control: '13px' } },
      size: { xxl: '48px' }
    };
    const options = OPTIONS;
    await render(
      <template>
        <EuiEmotionProvider
          @colorMode={{state.mode}}
          @borealisOverrides={{state.overrides}}
        >
          <EuiFieldText data-c="parent" />
          <EuiSelect @options={{options}} data-c="parent-select" />
          <EuiEmotionProvider @borealisOverrides={{own}}>
            <EuiFieldText data-c="child">
              <:append>Unit</:append>
            </EuiFieldText>
          </EuiEmotionProvider>
          <EuiEmotionProvider @colorMode="light">
            <EuiFieldText data-c="fixed" />
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <EuiFieldText data-c="sibling" />
        </EuiEmotionProvider>
      </template>
    );
    const parent = el(this.element, '[data-c="parent"]');
    const bg = (key: string) => style(this.element, `[data-c="${key}"]`).backgroundColor;
    assert.strictEqual(bg('parent'), rgb(forms(light)['background']!));
    assert.strictEqual(
      getComputedStyle(parent).color,
      rgb(light.colors.textParagraph)
    );
    const child = el(this.element, '[data-c="child"]');
    assert.strictEqual(box(child).height, 48, 'size override drives height');
    assert.strictEqual(box(layoutOf(child)).height, 48);
    assert.strictEqual(
      getComputedStyle(layoutOf(child)).borderTopLeftRadius,
      '13px'
    );

    state.mode = 'dark';
    await settled();
    assert.strictEqual(el(this.element, '[data-c="parent"]'), parent, 'no replacement');
    assert.strictEqual(bg('parent'), rgb(forms(dark)['background']!));
    assert.strictEqual(bg('parent-select'), rgb(forms(dark)['background']!));
    assert.strictEqual(getComputedStyle(parent).color, rgb(dark.colors.textParagraph));
    assert.strictEqual(getComputedStyle(parent).boxShadow, inset(forms(dark)['border']!));
    assert.strictEqual(
      getComputedStyle(layoutOf(child)).backgroundColor,
      rgb(forms(dark)['background']!),
      'child inherits the mode'
    );
    assert.strictEqual(bg('fixed'), rgb(forms(light)['background']!), 'light island');
    assert.strictEqual(bg('sibling'), rgb(forms(light)['background']!), 'sibling isolated');

    state.overrides = { border: { radius: { control: '4px' } } };
    await settled();
    assert.strictEqual(getComputedStyle(parent).borderRadius, '4px');
    assert.strictEqual(
      getComputedStyle(layoutOf(child)).borderTopLeftRadius,
      '13px',
      'nearest override wins'
    );
    assert.strictEqual(style(this.element, '[data-c="sibling"]').borderRadius, '8px');
  });

  test('high contrast: real borders, thicker invalid state, borderless group inputs', async function (assert) {
    await render(
      <template>
        <EuiEmotionProvider @highContrastMode="preferred">
          <EuiFieldText data-c="hc" />
          <EuiFieldText @isInvalid={{true}} data-c="hc-invalid" />
          <EuiFieldText data-c="hc-group">
            <:prepend>Pre</:prepend>
          </EuiFieldText>
        </EuiEmotionProvider>
        <EuiFieldText data-c="std" />
      </template>
    );
    const hc = style(this.element, '[data-c="hc"]');
    assert.strictEqual(hc.borderTopStyle, 'solid');
    assert.strictEqual(hc.borderTopWidth, '1px');
    assert.strictEqual(hc.borderTopColor, rgb(lightHc.border.color));
    assert.strictEqual(
      hc.backgroundColor,
      rgb(light.colors.emptyShade),
      'contrast background'
    );
    assert.strictEqual(
      style(this.element, '[data-c="hc-invalid"]').outlineWidth,
      '2px'
    );
    assert.strictEqual(
      style(this.element, '[data-c="hc-group"]').borderTopStyle,
      'none'
    );
    const std = style(this.element, '[data-c="std"]');
    assert.strictEqual(std.borderTopStyle, 'none', 'standard contrast isolated');
    assert.strictEqual(std.boxShadow, inset(forms(light)['border']!));
  });

  test('EuiFormControlLayoutDelimited: static icons, delimiter, centered inputs and states', async function (assert) {
    class State {
      @tracked invalid = false;
      @tracked readOnly = false;
    }
    const state = new State();
    await render(
      <template>
        <EuiFormControlLayoutDelimited
          @icon="calendar"
          @isInvalid={{state.invalid}}
          @readOnly={{state.readOnly}}
          data-c="delimited"
        >
          <:startControl as |classes|>
            <EuiFieldNumber
              @controlOnly={{true}}
              @value={{1}}
              class={{classes}}
              data-c="start"
            />
          </:startControl>
          <:endControl as |classes|>
            <EuiFieldNumber
              @controlOnly={{true}}
              @value={{9}}
              class={{classes}}
              data-c="end"
            />
          </:endControl>
        </EuiFormControlLayoutDelimited>
        <EuiFormControlLayoutDelimited @delimiter="to" data-c="custom">
          <:startControl as |c|><input class={{c}} /></:startControl>
          <:endControl as |c|><input class={{c}} /></:endControl>
        </EuiFormControlLayoutDelimited>
      </template>
    );
    const root = el(this.element, '[data-c="delimited"]');
    assert.true(root.classList.contains('euiFormControlLayout'));
    assert.true(root.classList.contains('euiFormControlLayoutDelimited'));
    assert.false(root.classList.contains('euiFormControlLayout--group'));
    assert.strictEqual(getComputedStyle(root).display, 'flex', 'group layout');
    assert.strictEqual(box(root).height, 40);
    const wrapper = el(root, '.euiFormControlLayout__childrenWrapper');
    assert.strictEqual(getComputedStyle(wrapper).display, 'flex');
    assert.strictEqual(wrapper.getAttribute('style'), null, 'static icons need no affordance');
    const icons = el(root, '.euiFormControlLayoutIcons');
    assert.strictEqual(getComputedStyle(icons).position, 'static');
    assert.strictEqual(getComputedStyle(icons).paddingInlineStart, '12px');

    const start = el(this.element, '[data-c="start"]');
    assert.true(start.classList.contains('euiFormControlLayoutDelimited__input'));
    const sStyle = getComputedStyle(start);
    assert.strictEqual(sStyle.textAlign, 'center');
    assert.strictEqual(sStyle.borderTopStyle, 'none');
    const delimiter = el(root, '.euiFormControlLayoutDelimited__delimiter');
    assert.strictEqual(delimiter.textContent!.trim(), '→');
    const dStyle = getComputedStyle(delimiter);
    assert.strictEqual(dStyle.display, 'flex');
    assert.strictEqual(dStyle.lineHeight, `${parseFloat(dStyle.fontSize)}px`);
    assert.strictEqual(dStyle.paddingInlineStart, '6px');
    assert.strictEqual(dStyle.color, rgb(light.colors.textSubdued));
    assert.true(box(delimiter).left >= box(start).right - 1);
    assert.true(box(el(this.element, '[data-c="end"]')).left >= box(delimiter).right - 1);
    assert.strictEqual(
      el(this.element, '[data-c="custom"] .euiFormControlLayoutDelimited__delimiter').textContent!.trim(),
      'to'
    );

    state.invalid = true;
    await settled();
    assert.strictEqual(el(this.element, '[data-c="delimited"]'), root);
    assert.true(root.classList.contains('euiFormControlLayoutDelimited--isInvalid'));
    assert.strictEqual(getComputedStyle(delimiter).color, rgb(light.colors.textDanger));
    assert.strictEqual(
      root.querySelectorAll('.euiFormControlLayoutIcons').length,
      2,
      'warning icon group on the end'
    );

    state.invalid = false;
    state.readOnly = true;
    await settled();
    assert.strictEqual(
      getComputedStyle(root).backgroundColor,
      rgb(forms(light)['backgroundReadOnly']!)
    );
  });
});
