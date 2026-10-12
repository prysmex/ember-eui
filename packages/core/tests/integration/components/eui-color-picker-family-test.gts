import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  fillIn,
  render,
  settled,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';
import { on } from '@ember/modifier';
import { tracked } from '@glimmer/tracking';

import chroma from 'chroma-js';

import EuiColorPaletteDisplay from '#src/components/eui-color-palette-display.gts';
import EuiColorPalettePicker from '#src/components/eui-color-palette-picker.gts';
import EuiColorPicker from '#src/components/eui-color-picker.gts';
import EuiColorPickerSwatch from '#src/components/eui-color-picker-swatch.gts';
import EuiColorStops from '#src/components/eui-color-stops.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiHue from '#src/components/eui-hue.gts';
import EuiSaturation from '#src/components/eui-saturation.gts';
import EuiText from '#src/components/eui-text.gts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiColorPalettePickerPalette } from '#src/components/eui-color-palette-picker.gts';
import type { EuiColorPickerOutput } from '#src/components/eui-color-picker.gts';
import type { ColorStop } from '#src/components/eui-color-stops.gts';
import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type { EuiBorealisOverrides } from '#src/utils/eui/theme.ts';

const light = resolveBorealisTheme('light').euiTheme;
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

/** Measured box in CSS pixels (the ember-qunit container is scaled). */
function box(element: Element) {
  const container = document.querySelector<HTMLElement>('#ember-testing')!;
  const scale = container.getBoundingClientRect().width / container.offsetWidth;
  const rect = element.getBoundingClientRect();
  return {
    width: Math.round((rect.width / scale) * 100) / 100,
    height: Math.round((rect.height / scale) * 100) / 100,
    left: rect.left / scale,
    right: rect.right / scale,
    top: rect.top / scale
  };
}

/** Unscaled box, for content portaled out of the scaled test container. */
function pbox(element: Element) {
  const rect = element.getBoundingClientRect();
  return { width: Math.round(rect.width * 100) / 100, height: Math.round(rect.height * 100) / 100, left: rect.left, right: rect.right, top: rect.top };
}

function q<T extends Element = HTMLElement>(selector: string, root: ParentNode = document) {
  const element = root.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

const css = (element: Element, pseudo?: string) => getComputedStyle(element, pseudo);
const popover = () => document.querySelector<HTMLElement>('[data-test-subj="euiColorPickerPopover"]');
const input = (key: string) => q<HTMLInputElement>(`[data-c="${key}"] input.euiColorPicker__input`);
const layoutOf = (element: Element) => element.closest<HTMLElement>('.euiFormControlLayout')!;
const leftIcon = (element: Element) =>
  layoutOf(element).querySelector<HTMLElement>(
    '.euiFormControlLayout__childrenWrapper > .euiFormControlLayoutIcons:first-child .euiIcon'
  )!;

async function openPicker(selector: string) {
  await click(selector);
  await waitUntil(() => popover()?.querySelector('.euiSaturation, .euiColorPickerSwatch'));
}

class PickerState {
  @tracked color = '#D36086';
  outputs: EuiColorPickerOutput[] = [];
  onChange = (text: string, output: EuiColorPickerOutput) => {
    this.color = text;
    this.outputs.push(output);
  };
}

const SWATCHES = ['#54B399', '#6092C0', '#D36086'];

module('Integration | Component | Borealis color picker family', function (hooks) {
  setupRenderingTest(hooks);

  test('picker field: upstream form control, swatch icon in the chosen color, dropdown arrow, sizes', async function (assert) {
    const state = new PickerState();
    await render(
      <template>
        <div style="width: 800px">
          <div data-c="m"><EuiColorPicker @color={{state.color}} @onChange={{state.onChange}} /></div>
          <div data-c="s"><EuiColorPicker @color={{state.color}} @onChange={{state.onChange}} @compressed={{true}} /></div>
          <div data-c="empty"><EuiColorPicker @color="" @onChange={{state.onChange}} /></div>
          <div data-c="full"><EuiColorPicker @color={{state.color}} @onChange={{state.onChange}} @fullWidth={{true}} /></div>
        </div>
      </template>
    );

    const m = input('m');
    assert.true(m.classList.contains('euiFieldText'), 'an upstream field text');
    assert.strictEqual(m.getAttribute('data-test-subj'), 'euiColorPickerAnchor');
    assert.strictEqual(m.value, '#D36086');
    assert.strictEqual(m.getAttribute('autocomplete'), 'off');
    assert.strictEqual(box(m).height, 40, 'control height');
    assert.strictEqual(box(input('s')).height, 32, 'compressed height');
    assert.strictEqual(css(m).paddingLeft, '36px', '12px + the swatch icon affordance');
    assert.strictEqual(css(m).paddingRight, '36px', '12px + the dropdown arrow affordance');
    assert.strictEqual(css(input('s')).paddingLeft, '32px');
    assert.strictEqual(css(m).boxShadow, `${rgb(forms(light)['border']!)} 0px 0px 0px 1px inset`);
    assert.strictEqual(css(m).borderTopLeftRadius, light.border.radius.control);
    assert.strictEqual(box(m).width, 400, 'form width');
    assert.strictEqual(box(input('full')).width, 800, 'full width');

    const layout = layoutOf(m);
    assert.true(layout.classList.contains('euiFormControlLayout'));
    assert.notOk(layout.classList.contains('euiFormControlLayout--group'), 'no group without prepend/append');
    assert.ok(layout.querySelector('[data-icon-type="chevronSingleDown"]'), 'upstream isDropdown arrow');

    const swatch = leftIcon(m);
    assert.strictEqual(swatch.getAttribute('data-icon-type'), 'swatchInput');
    assert.strictEqual(css(swatch).color, 'rgb(211, 96, 134)', 'the swatch icon takes the chosen color');
    const arrow = q('[data-icon-type="chevronSingleDown"]', layout);
    assert.notStrictEqual(css(arrow).color, 'rgb(211, 96, 134)', 'the arrow keeps its own color');
    await waitUntil(() => swatch.querySelector('.euiSwatchInput__stroke'));
    const stroke = q('.euiSwatchInput__stroke', swatch);
    assert.strictEqual(css(stroke).fill, 'none');
    assert.strictEqual(css(stroke).stroke, rgb(light.colors.borderBaseFormsColorSwatch), 'swatch stroke color');

    const empty = input('empty');
    assert.strictEqual(empty.value, '');
    assert.strictEqual(empty.placeholder, 'Transparent');
    assert.strictEqual(leftIcon(empty).getAttribute('data-icon-type'), 'stopSlash');
    assert.strictEqual(css(leftIcon(empty)).color, rgb(light.colors.textSubdued), 'stopSlash is subdued');
  });

  test('picker field states: invalid, disabled, read-only, clearable and a11y labelling', async function (assert) {
    const state = new PickerState();
    let blurs = 0;
    const onBlur = () => blurs++;
    await render(
      <template>
        <div data-c="invalid"><EuiColorPicker @color={{state.color}} @onChange={{state.onChange}} @isInvalid={{true}} /></div>
        <div data-c="disabled"><EuiColorPicker @color={{state.color}} @onChange={{state.onChange}} @disabled={{true}} /></div>
        <div data-c="readonly"><EuiColorPicker @color={{state.color}} @onChange={{state.onChange}} @readOnly={{true}} /></div>
        <div data-c="clear"><EuiColorPicker @color={{state.color}} @onChange={{state.onChange}} @isClearable={{true}} @onBlur={{onBlur}} /></div>
        <div data-c="id"><EuiColorPicker @id="my-color" @color={{state.color}} @onChange={{state.onChange}} /></div>
      </template>
    );

    const invalid = input('invalid');
    assert.strictEqual(invalid.getAttribute('aria-invalid'), 'true');
    assert.ok(layoutOf(invalid).querySelector('[data-icon-type="warning"]'), 'warning icon');
    assert.strictEqual(css(invalid).outlineColor, rgb(forms(light)['borderInvalid']!));
    assert.strictEqual(css(invalid).paddingRight, '60px', 'warning + arrow affordance');

    const disabled = input('disabled');
    assert.true(disabled.disabled);
    assert.notOk(layoutOf(disabled).querySelector('[data-icon-type="chevronSingleDown"]'), 'no arrow while disabled');
    assert.true(layoutOf(disabled).classList.contains('euiFormControlLayout-isDisabled'));
    assert.strictEqual(css(disabled).backgroundColor, rgb(forms(light)['backgroundDisabled']!));
    assert.strictEqual(css(leftIcon(disabled)).color, 'rgb(211, 96, 134)', 'the swatch keeps its color');

    const readonly = input('readonly');
    assert.true(readonly.readOnly);
    assert.notOk(layoutOf(readonly).querySelector('[data-icon-type="chevronSingleDown"]'), 'no arrow while read-only');
    await click(readonly);
    
    assert.notOk(popover(), 'read-only never opens');

    const clear = input('clear');
    const clearButton = q<HTMLButtonElement>('.euiFormControlLayoutClearButton', layoutOf(clear));
    assert.strictEqual(clearButton.getAttribute('aria-label'), 'Clear input');
    assert.strictEqual(css(clear).paddingRight, '60px', 'clear + arrow affordance');
    await click(clearButton);
    assert.strictEqual(state.color, '', 'clearing reports an empty color');
    assert.strictEqual(state.outputs.at(-1)!.hex, '');
    assert.false(state.outputs.at(-1)!.isValid);
    assert.strictEqual(clear.placeholder, 'Transparent');
    assert.notOk(layoutOf(clear).querySelector('.euiFormControlLayoutClearButton'), 'nothing left to clear');
    void blurs;

    // a11y: upstream aria-label fallback and open/close descriptions
    state.color = '#D36086';
    await settled();
    const plain = input('clear');
    assert.strictEqual(plain.getAttribute('aria-label'), 'Select a color');
    assert.notOk(input('id').hasAttribute('aria-label'), 'an @id is labelled by its form row instead');
    assert.strictEqual(input('id').id, 'my-color');
    const describedBy = () => document.getElementById(plain.getAttribute('aria-describedby')!)!;
    assert.strictEqual(describedBy().textContent, 'Press the down key to open a popover containing color options');
    assert.ok(describedBy().closest('.euiScreenReaderOnly'));
    await openPicker('[data-c="clear"] input');
    assert.strictEqual(describedBy().textContent, 'Press the escape key to close the popover');
    assert.strictEqual(q('.euiPopover__panel').getAttribute('aria-label'), 'Color selection dialog');
  });

  test('prepend and append: an upstream group around the field', async function (assert) {
    const state = new PickerState();
    await render(
      <template>
        <div data-c="group">
          <EuiColorPicker @color={{state.color}} @onChange={{state.onChange}}>
            <:prepend as |className inputId|><span class="pre" data-class={{className}} data-for={{inputId}}>Color</span></:prepend>
            <:append as |className|><span class="post" data-class={{className}}>Hex</span></:append>
          </EuiColorPicker>
        </div>
        <div data-c="pre-only">
          <EuiColorPicker @color={{state.color}} @onChange={{state.onChange}}>
            <:prepend><span class="pre-only">Color</span></:prepend>
          </EuiColorPicker>
        </div>
      </template>
    );

    const field = input('group');
    const layout = layoutOf(field);
    assert.true(layout.classList.contains('euiFormControlLayout--group'));
    assert.ok(q('.euiFormControlLayout__prepend .pre', layout), 'prepend side node');
    assert.ok(q('.euiFormControlLayout__append .post', layout), 'append side node');
    assert.strictEqual(q('.pre', layout).dataset['class'], 'euiFormControlLayout__prepend');
    assert.strictEqual(q('.pre', layout).dataset['for'], field.id, 'yields the input id');
    assert.strictEqual(css(field).boxShadow, 'none', 'in-group input has no own border');
    assert.strictEqual(css(layout).boxSizing, 'border-box');
    const only = layoutOf(input('pre-only'));
    assert.ok(only.querySelector('.euiFormControlLayout__prepend'));
    assert.notOk(only.querySelector('.euiFormControlLayout__append'), 'no empty append wrapper');
  });

  test('popover: upstream picker column with saturation, hue, swatches and the selected color announcement', async function (assert) {
    const state = new PickerState();
    await render(
      <template>
        <div data-c="p"><EuiColorPicker @color={{state.color}} @onChange={{state.onChange}} @swatches={{SWATCHES}} /></div>
      </template>
    );
    await openPicker('[data-c="p"] input');

    const root = popover()!;
    assert.true(root.classList.contains('euiColorPicker'));
    assert.true(q('.euiPopover__panel').classList.contains('euiColorPicker__popoverPanel'));
    assert.strictEqual(pbox(root).width, 152, '5 swatches and 4 gaps wide');
    assert.strictEqual(css(root).display, 'flex');
    assert.strictEqual(css(root).flexDirection, 'column');
    assert.strictEqual(css(root).rowGap, light.size.s);
    assert.notOk(root.querySelector('.euiSpacer'), 'gaps replace the spacers');

    const saturation = q('.euiSaturation', root);
    assert.strictEqual(pbox(saturation).width, 152);
    assert.strictEqual(pbox(saturation).height, 152, 'square');
    assert.strictEqual(css(saturation).position, 'relative');
    assert.strictEqual(css(saturation).borderTopLeftRadius, light.border.radius.control);
    assert.strictEqual(css(saturation).touchAction, 'none');
    assert.strictEqual(css(saturation).backgroundColor, rgb(`hsl(${chroma('#D36086').hsv()[0]}, 100%, 50%)`), 'the hue at full saturation');
    const lightness = q('.euiSaturation__lightness', saturation);
    assert.strictEqual(css(lightness).position, 'absolute');
    assert.strictEqual(css(lightness).borderTopLeftRadius, '7px', 'radius - 1px');
    assert.ok(css(lightness).backgroundImage.includes('linear-gradient(to right, rgb(255, 255, 255), rgba(255, 255, 255, 0))'));
    assert.ok(css(q('.euiSaturation__saturation', saturation)).backgroundImage.includes('linear-gradient(to top, rgb(0, 0, 0), rgba(0, 0, 0, 0))'));

    const indicator = q<HTMLButtonElement>('.euiSaturation__indicator', saturation);
    assert.strictEqual(indicator.type, 'button');
    assert.strictEqual(pbox(indicator).width, 12);
    assert.strictEqual(pbox(indicator).height, 12);
    assert.strictEqual(css(indicator).borderTopLeftRadius, '100%');
    assert.strictEqual(css(indicator).borderTopColor, rgb(light.colors.darkestShade));
    assert.strictEqual(css(indicator).backgroundColor, 'rgba(0, 0, 0, 0)', 'button reset');
    assert.strictEqual(css(indicator, '::before').borderTopColor, rgb(light.colors.lightestShade));
    assert.strictEqual(indicator.getAttribute('aria-label'), 'Select a color');
    assert.strictEqual(indicator.getAttribute('aria-roledescription'), 'HSV color mode saturation and value 2-axis slider.');
    assert.ok(document.getElementById(indicator.getAttribute('aria-describedby')!)!.textContent!.startsWith('Arrow keys'));
    // #D36086: s ≈ 0.546, v ≈ 0.827 → centre at (83, 26) in the 152px square
    const sat = pbox(saturation);
    const ind = pbox(indicator);
    assert.true(Math.abs(ind.left + 6 - sat.left - 0.546 * 152) < 2, 'indicator x follows saturation');
    assert.true(Math.abs(ind.top + 6 - sat.top - (1 - 0.827) * 152) < 2, 'indicator y follows value');

    const hue = q('.euiHue', root);
    assert.strictEqual(pbox(hue).height, 12);
    assert.strictEqual(css(hue).borderTopLeftRadius, '12px');
    assert.ok(css(hue).backgroundImage.startsWith('linear-gradient(to right, rgb(255, 50, 50) 0%'));
    const range = q<HTMLInputElement>('input.euiHue__range', hue);
    assert.strictEqual(range.type, 'range');
    assert.strictEqual(range.getAttribute('aria-roledescription'), 'Hue slider');
    assert.strictEqual(range.getAttribute('aria-valuetext'), `Hue ${chroma('#D36086').hsv()[0]}°`, 'upstream value text');
    assert.strictEqual(css(range).appearance, 'none');
    assert.strictEqual(css(range).backgroundColor, 'rgba(0, 0, 0, 0)');
    assert.strictEqual(pbox(range).width, 154, 'the anchor bleeds 1px on each side');
    assert.strictEqual(pbox(range).height, 24, 'thumb-sized anchor');
    assert.strictEqual(css(range).marginTop, '0px', 'input reset');

    const list = q('ul.euiColorPicker__swatches', root);
    assert.strictEqual(css(list).display, 'flex');
    assert.strictEqual(css(list).flexWrap, 'wrap');
    assert.strictEqual(css(list).columnGap, light.size.s);
    assert.strictEqual(css(list).listStyleType, 'none');
    assert.strictEqual(css(list).paddingLeft, '0px');
    const swatches = Array.from(list.querySelectorAll<HTMLButtonElement>('li > .euiColorPickerSwatch'));
    assert.strictEqual(swatches.length, 3);
    const first = swatches[0]!;
    assert.true(first.classList.contains('euiColorPicker__swatchSelect'));
    assert.strictEqual(pbox(first).width, 24);
    assert.strictEqual(pbox(first).height, 24);
    assert.strictEqual(css(first).backgroundColor, 'rgb(84, 179, 153)');
    assert.strictEqual(css(first).borderTopLeftRadius, light.border.radius.inline);
    assert.strictEqual(css(first).borderTopWidth, '1px');
    assert.strictEqual(css(first).borderTopColor, rgb(light.colors.borderBaseFormsColorSwatch));
    assert.strictEqual(css(first).cursor, 'pointer');
    assert.strictEqual(first.getAttribute('aria-label'), 'Select #54B399 as the color');
    assert.strictEqual(pbox(swatches[1]!).left - pbox(first).right, 8, 'swatch gap');

    const announcement = q('.euiScreenReaderOnly p[aria-live="polite"]', root);
    assert.strictEqual(announcement.getAttribute('aria-atomic'), 'true');
    assert.strictEqual(announcement.textContent!.trim(), 'Selected color: #D36086');
  });

  test('keyboard: arrow down moves into the saturation square, arrows change the color, Enter returns to the field', async function (assert) {
    const state = new PickerState();
    await render(
      <template>
        <div data-c="k"><EuiColorPicker @color={{state.color}} @onChange={{state.onChange}} @swatches={{SWATCHES}} /></div>
      </template>
    );
    const field = input('k');

    await triggerKeyEvent(field, 'keydown', 'ArrowDown');
    await waitUntil(() => popover()?.querySelector('.euiSaturation'));
    await triggerKeyEvent(field, 'keydown', 'ArrowDown');
    const saturation = q('.euiSaturation', popover()!);
    assert.strictEqual(document.activeElement, saturation, 'focus moves into the square');
    assert.strictEqual(saturation.getAttribute('tabindex'), '-1');

    const before = state.color;
    await triggerKeyEvent(saturation, 'keydown', 'ArrowRight');
    assert.notStrictEqual(state.color, before, 'ArrowRight raises the saturation');
    assert.true(/^#[0-9a-f]{6}$/.test(state.color), 'hex format kept');
    const afterRight = state.outputs.length;
    await triggerKeyEvent(saturation, 'keydown', 'ArrowUp');
    assert.strictEqual(state.outputs.length, afterRight + 1, 'ArrowUp changes the value');
    await settled();
    assert.strictEqual(field.value, state.color.toUpperCase(), 'the field follows, without replacement');
    assert.strictEqual(
      q('.euiScreenReaderOnly p[aria-live="polite"]', popover()!).textContent!.trim(),
      `Selected color: ${state.color.toUpperCase()}`
    );

    await triggerKeyEvent(saturation, 'keydown', 'Enter');
    await waitUntil(() => !popover());
    assert.strictEqual(document.activeElement, field, 'Enter confirms and returns to the field');

    await triggerKeyEvent(field, 'keydown', 'Enter');
    await waitUntil(() => popover());
    assert.ok(popover(), 'Enter on the field toggles it open');
  });

  test('keyboard and pointer on swatches: swatch mode focuses the first swatch, picking closes', async function (assert) {
    const state = new PickerState();
    await render(
      <template>
        <div data-c="sw"><EuiColorPicker @color={{state.color}} @onChange={{state.onChange}} @mode="swatch" @swatches={{SWATCHES}} /></div>
      </template>
    );
    const field = input('sw');
    await triggerKeyEvent(field, 'keydown', 'ArrowDown');
    await waitUntil(() => popover()?.querySelector('.euiColorPickerSwatch'));
    assert.notOk(popover()!.querySelector('.euiSaturation'), 'no saturation in swatch mode');
    assert.notOk(popover()!.querySelector('.euiHue'), 'no hue in swatch mode');
    await triggerKeyEvent(field, 'keydown', 'ArrowDown');
    const swatches = popover()!.querySelectorAll<HTMLButtonElement>('.euiColorPickerSwatch');
    assert.strictEqual(document.activeElement, swatches[0], 'first swatch focused');
    assert.strictEqual(css(swatches[0]!).outlineStyle, 'solid', 'focus outline');
    assert.strictEqual(css(swatches[0]!).outlineWidth, light.focus.width);
    assert.strictEqual(css(swatches[0]!).outlineColor, rgb(light.focus.color));
    assert.strictEqual(css(swatches[0]!).outlineOffset, '-1px', 'centered outline');

    await click(swatches[1]!);
    await waitUntil(() => !popover());
    assert.strictEqual(state.color, '#6092C0');
    assert.deepEqual(state.outputs.at(-1), { rgba: [96, 146, 192, 1], hex: '#6092c0', isValid: true });
    assert.strictEqual(field.value, '#6092C0');
    assert.strictEqual(document.activeElement, field);
  });

  test('inline display: secondary inputs, alpha range in rgba format and clearing', async function (assert) {
    class State {
      @tracked color = '211, 96, 134, 0.5';
      outputs: EuiColorPickerOutput[] = [];
      onChange = (text: string, output: EuiColorPickerOutput) => {
        this.color = text;
        this.outputs.push(output);
      };
    }
    const state = new State();
    await render(
      <template>
        <div data-c="top">
          <EuiColorPicker @color={{state.color}} @onChange={{state.onChange}} @display="inline" @secondaryInputDisplay="top" @showAlpha={{true}} @isClearable={{true}} />
        </div>
        <div data-c="bottom">
          <EuiColorPicker @color={{state.color}} @onChange={{state.onChange}} @display="inline" @secondaryInputDisplay="bottom" @compressed={{false}} @mode="picker" />
        </div>
      </template>
    );

    const top = q('[data-c="top"] .euiColorPicker');
    assert.strictEqual(box(top).width, 152, 'inline picker is the picker width');
    const children = Array.from(top.children);
    const secondary = q<HTMLInputElement>('[data-test-subj="euiColorPickerInput_top"]', top);
    assert.ok(children[0]!.contains(secondary), 'secondary input first (top)');
    assert.strictEqual(secondary.value, '211, 96, 134, 0.5');
    assert.strictEqual(secondary.getAttribute('aria-label'), 'Color value');
    assert.strictEqual(box(secondary).height, 40, 'inline display follows @compressed (false)');
    assert.ok(q('.euiColorPickerSwatch', top), 'default mode has swatches');

    const alpha = q('.euiColorPicker__alphaRange', top);
    assert.strictEqual(children.at(-1), alpha, 'alpha range last');
    const alphaInput = q<HTMLInputElement>('input[type="number"]', alpha);
    assert.strictEqual(alphaInput.value, '50');
    assert.strictEqual(alphaInput.getAttribute('aria-label'), 'Alpha channel (opacity) value');
    assert.strictEqual(alpha.textContent!.trim(), '%', 'percent append');

    await fillIn(alphaInput, '25');
    assert.strictEqual(state.color, '211, 96, 134, 0.25', 'alpha keeps the rgba format');
    assert.deepEqual(state.outputs.at(-1), { hex: '#d3608640', rgba: [211, 96, 134, 0.25], isValid: true });
    await fillIn(alphaInput, '100');
    assert.strictEqual(state.color, '211, 96, 134', 'opaque drops the alpha');

    await fillIn('[data-c="top"] .euiHue__range', '120');
    assert.true(/^\d+, \d+, \d+$/.test(state.color), `hue keeps the rgb format: ${state.color}`);

    const bottom = q('[data-c="bottom"] .euiColorPicker');
    assert.notOk(bottom.querySelector('.euiColorPicker__swatches'), 'picker mode has no swatches');
    assert.ok(Array.from(bottom.children).at(-1)!.querySelector('[data-test-subj="euiColorPickerInput_bottom"]'), 'secondary input last (bottom)');

    const clear = q<HTMLButtonElement>('.euiFormControlLayoutClearButton', top);
    await click(clear);
    assert.strictEqual(state.color, '', 'clear empties the color');
    await settled();
    assert.strictEqual(secondary.value, '');
    assert.strictEqual(secondary.placeholder, 'Transparent');

    await fillIn(secondary, 'nope');
    assert.false(state.outputs.at(-1)!.isValid, 'invalid text');
  });

  test('a custom button trigger, invalid secondary input error and standalone swatch/hue/saturation', async function (assert) {
    const state = new PickerState();
    const hues: number[] = [];
    const onHue = (hue: number) => hues.push(hue);
    await render(
      <template>
        <EuiColorPicker @color={{state.color}} @onChange={{state.onChange}} @mode="swatch" @swatches={{SWATCHES}}>
          <:button as |toggle|>
            <EuiColorPickerSwatch class="trigger" @color={{state.color}} {{on "click" toggle}} />
          </:button>
        </EuiColorPicker>
        <div data-c="err"><EuiColorPicker @color="nope" @onChange={{state.onChange}} @display="inline" @mode="secondaryInput" @secondaryInputDisplay="bottom" @isInvalid={{true}} /></div>
        <EuiHue @id="h0" @hue={{0}} @onChange={{onHue}} />
        <div style="width: 100px"><EuiSaturation @id="s0" @onChange={{onHue}} /></div>
        <EuiColorPickerSwatch class="none" @color="nope" />
      </template>
    );

    assert.notOk(document.querySelector('input.euiColorPicker__input'), 'no field with a custom button');
    assert.strictEqual(css(q('.trigger')).backgroundColor, 'rgb(211, 96, 134)');
    await click('.trigger');
    await waitUntil(() => popover()?.querySelector('.euiColorPickerSwatch'));
    assert.strictEqual(css(q('.euiPopover-isOpen, .euiColorPicker__popoverAnchor')).display, 'inline-block', 'inline-block anchor');

    const err = q('[data-c="err"]');
    assert.ok(err.querySelector('[data-test-subj="euiColorPickerInput_bottom"]'));
    assert.notOk(err.querySelector('.euiSaturation'), 'secondaryInput mode has no picker');
    assert.notOk(err.querySelector('.euiColorPicker__swatches'), 'nor swatches');
    assert.strictEqual(q('.euiFormErrorText', err).textContent!.trim(), 'Invalid color value');

    assert.strictEqual(q<HTMLInputElement>('#h0-hue').value, '0', 'hue 0 is not replaced by the default');
    assert.strictEqual(css(q('[data-test-subj="euiSaturation"]')).backgroundColor, 'rgb(255, 4, 0)', 'default color [1, 0, 0]');
    assert.strictEqual(q('.none').getAttribute('style'), 'background: transparent');
    assert.strictEqual(css(q('.none')).backgroundColor, 'rgba(0, 0, 0, 0)');
  });

  test('reactive args update in place without replacing elements', async function (assert) {
    class State {
      @tracked color = '#D36086';
      @tracked compressed = false;
      @tracked invalid = false;
      @tracked disabled = false;
      @tracked size: 'xs' | 's' | 'm' = 's';
      @tracked type: 'fixed' | 'gradient' = 'fixed';
      @tracked stopsCompressed = false;
      onChange = (text: string) => (this.color = text);
    }
    const state = new State();
    const stops: ColorStop[] = [
      { stop: 0, color: '#54B399' },
      { stop: 50, color: '#D36086' }
    ];
    const noop = () => {};
    await render(
      <template>
        <div data-c="r">
          <EuiColorPicker @color={{state.color}} @onChange={{state.onChange}} @compressed={{state.compressed}} @isInvalid={{state.invalid}} @disabled={{state.disabled}} />
        </div>
        <EuiColorPaletteDisplay class="pd" @palette={{SWATCHES}} @size={{state.size}} />
        <EuiColorStops class="cs" @label="Stops" @colorStops={{stops}} @onChange={{noop}} @compressed={{state.stopsCompressed}} />
      </template>
    );

    const field = input('r');
    const layout = layoutOf(field);
    const icon = leftIcon(field);
    state.compressed = true;
    state.invalid = true;
    state.color = '#00FF00';
    await settled();
    assert.strictEqual(input('r'), field, 'same input');
    assert.strictEqual(layoutOf(field), layout, 'same layout');
    assert.strictEqual(box(field).height, 32);
    assert.strictEqual(field.getAttribute('aria-invalid'), 'true');
    assert.strictEqual(field.value, '#00FF00');
    assert.strictEqual(css(leftIcon(field)).color, 'rgb(0, 255, 0)', 'icon follows the color');
    assert.strictEqual(leftIcon(field), icon, 'same icon');
    state.disabled = true;
    await settled();
    assert.strictEqual(input('r'), field);
    assert.true(field.disabled);
    assert.notOk(layout.querySelector('[data-icon-type="chevronSingleDown"]'));

    const pd = q('.pd');
    assert.strictEqual(box(pd).height, 8);
    state.size = 'm';
    await settled();
    assert.strictEqual(q('.pd'), pd, 'same palette element');
    assert.strictEqual(box(pd).height, 16);
    assert.strictEqual(css(pd).borderTopLeftRadius, '16px');

    const cs = q('.cs');
    assert.strictEqual(box(cs).height, 40);
    state.stopsCompressed = true;
    await settled();
    assert.strictEqual(q('.cs'), cs, 'same color stops element');
    assert.strictEqual(box(cs).height, 32);
  });

  test('color stops: upstream range wrapper, striped track, gradient highlight and stop thumbs', async function (assert) {
    class State {
      @tracked colorStops: ColorStop[] = [
        { stop: 0, color: '#54B399' },
        { stop: 25, color: '#D36086' },
        { stop: 50, color: '#9170B8' }
      ];
      invalid?: boolean;
      onChange = (colorStops: ColorStop[], isInvalid: boolean) => {
        this.colorStops = colorStops;
        this.invalid = isInvalid;
      };
    }
    const state = new State();
    await render(
      <template>
        <div style="width: 600px">
          <EuiColorStops class="cs" @label="Map colors" @colorStops={{state.colorStops}} @onChange={{state.onChange}} @min={{0}} @max={{100}} />
          <EuiColorStops class="full" @label="Full" @colorStops={{state.colorStops}} @onChange={{state.onChange}} @fullWidth={{true}} />
        </div>
      </template>
    );

    const cs = q('.cs');
    assert.true(cs.classList.contains('euiRangeWrapper') && cs.classList.contains('euiColorStops'), 'root classes');
    assert.strictEqual(cs.dataset['testSubj'], 'euiColorStops');
    assert.strictEqual(css(cs).display, 'flex');
    assert.strictEqual(css(cs).alignItems, 'center');
    assert.strictEqual(box(cs).height, 40, 'form control height');
    assert.strictEqual(box(cs).width, 400, 'form width');
    assert.strictEqual(box(q('.full')).width, 600, 'full width');
    assert.strictEqual(cs.getAttribute('tabindex'), '0');
    assert.ok(q('.euiScreenReaderOnly', cs).textContent!.replace(/\s+/g, ' ').includes('Map colors: Color stop picker.'), 'announcement');

    const track = q('.euiRangeTrack.euiColorStops__track', cs);
    assert.strictEqual(css(track).position, 'relative');
    assert.strictEqual(css(track).flexGrow, '1');
    const after = css(track, '::after');
    assert.strictEqual(after.height, '6px', 'track height');
    assert.ok(after.backgroundImage.startsWith('repeating-linear-gradient(-45deg'), `stripes: ${after.backgroundImage}`);
    assert.ok(after.backgroundImage.includes(rgb(light.colors.lightShade)), 'track color stripes');
    assert.strictEqual(after.backgroundSize, '4px 4px');

    const highlight = q('.euiRangeHighlight.euiColorStops__highlight', track);
    assert.strictEqual(css(highlight).position, 'absolute');
    assert.strictEqual(css(highlight).zIndex, '2');
    assert.strictEqual(css(highlight).height, '6px');
    const progress = q('.euiRangeHighlight__progress', highlight);
    assert.ok(progress.style.background.startsWith('linear-gradient(to right, transparent, transparent'), `the track shows before the first stop: ${progress.style.background}`);
    assert.ok(progress.style.background.includes('rgb(211, 96, 134)'));
    assert.strictEqual(css(progress).borderTopLeftRadius, light.border.radius.inline);

    const add = q('.euiColorStops__addContainer', track);
    assert.strictEqual(css(add).position, 'absolute');
    assert.strictEqual(box(add).height, 16);
    const target = q('.euiColorStops__addTarget', add);
    assert.strictEqual(css(target).opacity, '0', 'hidden until hover');
    assert.strictEqual(box(target).width, 16);
    assert.strictEqual(css(target).backgroundColor, rgb(light.colors.lightestShade));
    assert.strictEqual(css(target).borderTopColor, rgb(light.colors.darkShade));
    assert.strictEqual(css(target).pointerEvents, 'none');

    const thumbs = Array.from(cs.querySelectorAll<HTMLButtonElement>('.euiColorStopThumb'));
    assert.strictEqual(thumbs.length, 3);
    const thumb = thumbs[1]!;
    assert.true(thumb.classList.contains('euiRangeThumb'));
    assert.strictEqual(thumb.getAttribute('role'), 'slider', 'upstream EuiRangeThumb: one slider button');
    assert.strictEqual(thumb.type, 'button');
    assert.strictEqual(thumb.getAttribute('aria-valuenow'), '25');
    assert.strictEqual(thumb.getAttribute('aria-valuemin'), '1');
    assert.strictEqual(thumb.getAttribute('aria-valuemax'), '49');
    assert.strictEqual(thumb.getAttribute('aria-valuetext'), 'Stop: 25, Color: #D36086 (2 of 3)');
    assert.strictEqual(thumb.getAttribute('tabindex'), '-1');
    assert.notOk(thumb.querySelector('*'), 'no nested slider element');
    assert.strictEqual(box(thumb).width, 16);
    assert.strictEqual(box(thumb).height, 16);
    assert.strictEqual(css(thumb).borderTopLeftRadius, '50%');
    assert.strictEqual(css(thumb).backgroundColor, 'rgb(211, 96, 134)', 'the stop color');
    assert.strictEqual(css(thumb).borderTopWidth, light.border.width.thick);
    assert.strictEqual(css(thumb).borderTopColor, rgb(light.colors.emptyShade));
    assert.strictEqual(css(thumb).cursor, 'grab');
    assert.strictEqual(css(thumb).pointerEvents, 'auto');

    const wrapper = thumb.closest<HTMLElement>('.euiColorStopPopover')!;
    assert.strictEqual(css(wrapper).position, 'absolute');
    assert.strictEqual(box(wrapper).width, 16);
    assert.strictEqual(css(q('.euiColorStopThumbPopover__anchor', wrapper), '::before').backgroundColor, rgb(light.colors.emptyShade), 'white disc under transparent colors');
    // thumbs follow the stops along the track
    assert.true(box(thumbs[0]!).left < box(thumbs[1]!).left && box(thumbs[1]!).left < box(thumbs[2]!).left, 'ordered thumbs');
    assert.true(Math.abs(box(thumbs[0]!).left - box(track).left) < 1, `the first stop at the start: ${box(thumbs[0]!).left} vs ${box(track).left}`);
  });

  test('color stops: keyboard add/remove/move, popover editing, modes and invalid stops', async function (assert) {
    class State {
      @tracked colorStops: ColorStop[] = [
        { stop: 0, color: '#54B399' },
        { stop: 25, color: '#D36086' },
        { stop: 50, color: '#9170B8' }
      ];
      @tracked stopType: 'gradient' | 'fixed' | 'stepped' = 'gradient';
      invalid?: boolean;
      onChange = (colorStops: ColorStop[], isInvalid: boolean) => {
        this.colorStops = colorStops;
        this.invalid = isInvalid;
      };
    }
    const state = new State();
    await render(
      <template>
        <EuiColorStops class="cs" @label="Colors" @colorStops={{state.colorStops}} @onChange={{state.onChange}} @min={{0}} @max={{100}} @stopType={{state.stopType}} @stepNumber={{4}} />
      </template>
    );

    const cs = q('.cs');
    const progress = q('.euiRangeHighlight__progress', cs);
    const gradient = progress.style.background;
    state.stopType = 'fixed';
    await settled();
    assert.notStrictEqual(progress.style.background, gradient, 'fixed differs');
    assert.ok(/rgb\(84, 179, 153\) ([\d.]+)%, rgb\(211, 96, 134\) \1%/.test(progress.style.background), `hard edges between stops: ${progress.style.background}`);
    assert.ok(/rgb\(211, 96, 134\) ([\d.]+)%, rgb\(145, 112, 184\) \1%/.test(progress.style.background), 'each color until the next stop');
    state.stopType = 'stepped';
    await settled();
    assert.strictEqual(new Set(progress.style.background.match(/rgb\([^)]+\)/g)).size, 4, `4 steps: ${progress.style.background}`);
    assert.ok(progress.style.background.startsWith('linear-gradient(to right, transparent 0%'), 'stepped starts transparent');
    assert.strictEqual(q('.euiRangeHighlight__progress', cs), progress, 'same element');

    cs.focus();
    await triggerKeyEvent(cs, 'keydown', 'ArrowDown');
    assert.strictEqual(document.activeElement, q('[data-index="euiColorStop_0"]', cs));
    await triggerKeyEvent(cs, 'keydown', 'ArrowDown');
    const second = q<HTMLButtonElement>('[data-index="euiColorStop_1"]', cs);
    assert.strictEqual(document.activeElement, second);
    assert.strictEqual(css(second.closest('.euiColorStopPopover')!).zIndex, '3', 'focused stop on top');
    await triggerKeyEvent(second, 'keydown', 'ArrowRight');
    
    assert.strictEqual(state.colorStops[1]!.stop, 26);
    await triggerKeyEvent(second, 'keydown', 'Backspace');
    
    assert.deepEqual(state.colorStops.map((s) => s.stop), [0, 50]);
    assert.strictEqual(document.activeElement, cs, 'focus returns to the group');
    await triggerKeyEvent(cs, 'keydown', 'Enter');
    
    assert.deepEqual(state.colorStops.map((s) => s.stop), [0, 50, 100], 'Enter adds a stop');
    assert.false(state.invalid);

    await waitUntil(() => document.querySelector('[data-test-subj="euiColorStopPopover"]'));
    const form = q('[data-test-subj="euiColorStopPopover"]');
    assert.true(form.classList.contains('euiColorStop'));
    assert.strictEqual(pbox(form).width, 152, 'the picker width');
    const opened = q<HTMLButtonElement>('[data-index="euiColorStop_2"]', cs);
    assert.strictEqual(css(opened).outlineStyle, 'solid', 'open stop keeps the focus look');
    assert.strictEqual(css(opened).outlineColor, rgb(light.colors.primary));
    assert.ok(q('.euiColorPicker .euiSaturation', form), 'inline picker');
    assert.ok(q('[data-test-subj="euiColorPickerInput_bottom"]', form), 'secondary input');
    assert.strictEqual(q('.euiScreenReaderOnly p', form).getAttribute('aria-live'), 'polite');

    await fillIn(q('input[type="number"]', form), '');
    assert.true(state.invalid, 'an empty stop is invalid');
    await settled();
    assert.strictEqual(q('.euiFormErrorText', form).textContent!.trim(), 'Value is out of range');

    await click(q('.euiButtonIcon', form));
    
    assert.strictEqual(state.colorStops.length, 2, 'the trash button removes the stop');
  });

  test('color stops: read-only and disabled', async function (assert) {
    const stops: ColorStop[] = [
      { stop: 0, color: '#54B399' },
      { stop: 50, color: '#D36086' }
    ];
    let changes = 0;
    const onChange = () => changes++;
    await render(
      <template>
        <EuiColorStops class="ro" @label="A" @colorStops={{stops}} @onChange={{onChange}} @readOnly={{true}} />
        <EuiColorStops class="dis" @label="B" @colorStops={{stops}} @onChange={{onChange}} @disabled={{true}} />
      </template>
    );

    const ro = q('.ro');
    assert.ok(q('.euiScreenReaderOnly', ro).textContent!.includes('Read-only.'));
    await click(q('.euiColorStops__addContainer', ro));
    ro.focus();
    await triggerKeyEvent(ro, 'keydown', 'Enter');
    assert.strictEqual(changes, 0, 'read-only adds nothing');
    const roThumb = q<HTMLButtonElement>('.euiColorStopThumb', ro);
    await triggerKeyEvent(roThumb, 'keydown', 'ArrowRight');
    assert.strictEqual(changes, 0, 'read-only stops do not move');
    await triggerKeyEvent(roThumb, 'keydown', 'Enter');
    await waitUntil(() => document.querySelector('[data-test-subj="euiColorStopPopover"]'));
    const form = q('[data-test-subj="euiColorStopPopover"]');
    assert.notOk(form.querySelector('.euiButtonIcon'), 'no remove button');
    assert.true(q<HTMLInputElement>('input[type="number"]', form).readOnly);
    assert.notOk(form.querySelector('.euiSaturation'), 'secondary input only');

    const dis = q('.dis');
    assert.strictEqual(dis.getAttribute('tabindex'), '-1');
    assert.ok(q('.euiScreenReaderOnly', dis).textContent!.includes('Disabled.'));
    assert.strictEqual(css(q('.euiRangeTrack', dis)).opacity, '0.5', 'upstream disabled track');
    const thumb = q<HTMLButtonElement>('.euiColorStopThumb', dis);
    assert.true(thumb.disabled);
    assert.strictEqual(thumb.getAttribute('aria-disabled'), 'true');
    assert.strictEqual(css(thumb).pointerEvents, 'none');
    await click(q('.euiColorStops__addContainer', dis));
    assert.strictEqual(changes, 0, 'disabled adds nothing');
  });

  test('palette display: fixed and gradient, sizes xs/s/m, border and screen reader title', async function (assert) {
    const colors = ['#ff0000', '#00ff00', '#0000ff'];
    const stops = [
      { stop: 0, color: '#ff0000' },
      { stop: 50, color: '#00ff00' }
    ];
    await render(
      <template>
        <div style="width: 300px">
          <EuiColorPaletteDisplay class="xs" @palette={{colors}} @size="xs" />
          <EuiColorPaletteDisplay class="s" @palette={{colors}} @title="Primary" />
          <EuiColorPaletteDisplay class="m" @palette={{colors}} @size="m" />
          <EuiColorPaletteDisplay class="g" @palette={{stops}} @type="gradient" @title="Ramp" />
        </div>
      </template>
    );

    for (const [key, size] of [['xs', 4], ['s', 8], ['m', 16]] as const) {
      const el = q(`.${key}`);
      assert.strictEqual(box(el).height, size, `${key} height`);
      assert.strictEqual(css(el).borderTopLeftRadius, `${size}px`, `${key} radius`);
      assert.strictEqual(box(el).width, 300);
    }
    const s = q('.s');
    assert.strictEqual(css(s).display, 'flex');
    assert.strictEqual(css(s).overflow, 'hidden');
    assert.strictEqual(css(s).position, 'relative');
    const after = css(s, '::after');
    assert.strictEqual(after.position, 'absolute');
    assert.strictEqual(after.borderTopWidth, '1px');
    assert.strictEqual(after.borderTopColor, rgb(light.colors.borderBaseFormsColorSwatch));
    assert.strictEqual(after.pointerEvents, 'none');
    const bleed = q('.euiColorPaletteDisplayFixed__bleedArea', s);
    assert.strictEqual(bleed.getAttribute('aria-hidden'), 'true');
    assert.strictEqual(css(bleed).position, 'absolute');
    assert.strictEqual(css(bleed).display, 'flex');
    assert.strictEqual(css(bleed).right, '-1px', 'bleeds 1px');
    const blocks = bleed.querySelectorAll('span');
    assert.strictEqual(blocks.length, 3);
    assert.strictEqual(css(blocks[0]!).backgroundColor, 'rgb(255, 0, 0)');
    assert.strictEqual(q('.euiScreenReaderOnly', s).textContent!.trim(), 'Primary');

    const g = q('.g');
    assert.strictEqual(g.getAttribute('aria-hidden'), 'true');
    assert.ok(g.style.background.includes('linear-gradient'));
    assert.strictEqual(box(g).height, 8);
    assert.strictEqual(g.previousElementSibling!.textContent!.trim(), 'Ramp', 'title before the gradient');
  });

  test('palette picker: super select items with an xs title above the palette, selection display and states', async function (assert) {
    class State {
      @tracked value = 'cool';
      @tracked disabled = false;
    }
    const state = new State();
    const onChange = (value: string) => (state.value = value);
    const palettes: EuiColorPalettePickerPalette[] = [
      { value: 'cool', title: 'Cool', type: 'fixed', palette: ['#6092C0', '#54B399'] },
      { value: 'warm', title: 'Warm', type: 'gradient', palette: ['#D36086', '#E7664C'] },
      { value: 'custom', title: 'Custom', type: 'text' }
    ];
    await render(
      <template>
        <EuiColorPalettePicker data-c="pp" @palettes={{palettes}} @valueOfSelected={{state.value}} @onChange={{onChange}} @disabled={{state.disabled}} />
        <EuiColorPalettePicker data-c="title" @palettes={{palettes}} @valueOfSelected="warm" @onChange={{onChange}} @selectionDisplay="title" />
        <EuiText class="xs-probe" @size="xs">probe</EuiText>
      </template>
    );

    const control = q<HTMLButtonElement>('[data-c="pp"]');
    assert.ok(control.querySelector('.euiColorPaletteDisplay'), 'the selected palette is shown');
    assert.strictEqual(q('[data-c="title"]').textContent!.trim().startsWith('Warm'), true, 'title selection display');

    await click(control);
    await waitUntil(() => document.querySelector('.euiColorPalettePicker__item'));
    const items = Array.from(document.querySelectorAll<HTMLElement>('.euiSuperSelect__item'));
    assert.strictEqual(items.length, 3);
    assert.notOk(items[0]!.classList.contains('euiSuperSelect__item--hasDividers'), 'no dividers (upstream)');
    const title = q('.euiColorPalettePicker__itemTitle', items[0]);
    assert.true(title.classList.contains('euiText'));
    assert.strictEqual(title.getAttribute('aria-hidden'), 'true');
    assert.strictEqual(css(title).fontSize, css(q('.xs-probe')).fontSize, 'EuiText xs');
    assert.ok(title.closest('.euiFlexGroup'), 'in a flex group');
    const display = q('.euiColorPaletteDisplay', items[0]);
    assert.true(pbox(display).top > pbox(title).top, 'palette below the title');
    assert.strictEqual(pbox(display).height, 8);
    assert.strictEqual(q('.euiScreenReaderOnly', items[0]).textContent!.trim(), 'Cool', 'accessible name');
    assert.notOk(items[2]!.querySelector('.euiColorPalettePicker__itemTitle'), 'text options only show the title');
    assert.strictEqual(items[2]!.textContent!.trim(), 'Custom');

    await click(items[2]!);
    
    assert.strictEqual(state.value, 'custom');
    assert.strictEqual(control.textContent!.trim(), 'Custom');

    state.disabled = true;
    await settled();
    assert.true(control.disabled, 'disabled reaches the super select');
  });

  test('light/dark from the nearest provider, sibling isolation and JS-object token overrides', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'light';
      @tracked overrides: EuiBorealisOverrides = {};
    }
    const state = new State();
    const own: EuiBorealisOverrides = { size: { l: '32px' }, border: { radius: { control: '2px' } } };
    const noop = () => {};
    const colors = ['#ff0000', '#00ff00'];
    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}} @borealisOverrides={{state.overrides}}>
          <EuiColorPicker class="parent" @color="#D36086" @onChange={{noop}} @display="inline" @swatches={{SWATCHES}} />
          <EuiColorPaletteDisplay class="pd" @palette={{colors}} />
          <EuiEmotionProvider @borealisOverrides={{own}}>
            <EuiColorPicker class="child" @color="#D36086" @onChange={{noop}} @display="inline" @swatches={{SWATCHES}} />
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <EuiColorPicker class="sibling" @color="#D36086" @onChange={{noop}} @display="inline" @swatches={{SWATCHES}} />
        </EuiEmotionProvider>
      </template>
    );

    const swatchOf = (key: string) => q(`.${key} .euiColorPickerSwatch`);
    const indicatorOf = (key: string) => q(`.${key} .euiSaturation__indicator`);
    assert.strictEqual(css(swatchOf('parent')).borderTopColor, rgb(light.colors.borderBaseFormsColorSwatch));
    assert.strictEqual(box(swatchOf('child')).width, 32, 'size.l override drives the swatch size');
    assert.strictEqual(box(q('.child')).width, 192, 'and the picker width (5 × 32 + 4 × 8)');
    assert.strictEqual(css(q('.child .euiSaturation')).borderTopLeftRadius, '2px', 'control radius override');

    const parentSwatch = swatchOf('parent');
    state.mode = 'dark';
    await settled();
    assert.strictEqual(swatchOf('parent'), parentSwatch, 'no replacement');
    assert.strictEqual(css(parentSwatch).borderTopColor, rgb(dark.colors.borderBaseFormsColorSwatch));
    assert.strictEqual(css(indicatorOf('parent')).borderTopColor, rgb(dark.colors.darkestShade));
    assert.strictEqual(css(q('.pd'), '::after').borderTopColor, rgb(dark.colors.borderBaseFormsColorSwatch));
    assert.strictEqual(css(indicatorOf('child')).borderTopColor, rgb(dark.colors.darkestShade), 'child inherits the mode');
    assert.strictEqual(css(indicatorOf('sibling')).borderTopColor, rgb(light.colors.darkestShade), 'sibling isolated');

    state.overrides = { size: { l: '20px' } };
    await settled();
    assert.strictEqual(box(swatchOf('parent')).width, 20);
    assert.strictEqual(box(swatchOf('child')).width, 32, 'nearest override wins');
    assert.strictEqual(box(swatchOf('sibling')).width, 24);
  });

  test('popover content portaled out of a dark provider keeps the dark tokens', async function (assert) {
    const noop = () => {};
    await render(
      <template>
        <EuiEmotionProvider @colorMode="dark">
          <div data-c="d"><EuiColorPicker @color="#D36086" @onChange={{noop}} @swatches={{SWATCHES}} /></div>
        </EuiEmotionProvider>
      </template>
    );
    assert.strictEqual(css(input('d')).backgroundColor, rgb(forms(dark)['background']!));
    await openPicker('[data-c="d"] input');
    assert.strictEqual(css(q('.euiColorPickerSwatch', popover()!)).borderTopColor, rgb(dark.colors.borderBaseFormsColorSwatch));
    assert.strictEqual(css(q('.euiSaturation__indicator', popover()!), '::before').borderTopColor, rgb(dark.colors.lightestShade));
  });

  test('RTL: the swatch icon and its padding move to the right; color geometry stays physical', async function (assert) {
    const stops: ColorStop[] = [
      { stop: 0, color: '#54B399' },
      { stop: 100, color: '#D36086' }
    ];
    const noop = () => {};
    await render(
      <template>
        <div dir="rtl" style="width: 600px">
          <div data-c="rtl"><EuiColorPicker @color="#D36086" @onChange={{noop}} /></div>
          <EuiColorStops class="cs" @label="Stops" @colorStops={{stops}} @onChange={{noop}} @min={{0}} @max={{100}} />
          <EuiColorPicker class="inline" @color="#ffffff" @onChange={{noop}} @display="inline" @mode="picker" />
        </div>
      </template>
    );

    const field = input('rtl');
    assert.strictEqual(css(field).paddingRight, '36px', 'swatch affordance on the right');
    assert.strictEqual(css(field).paddingLeft, '36px', 'arrow affordance on the left');
    assert.true(box(leftIcon(field)).left > box(field).left + box(field).width / 2, 'the swatch icon sits at inline start (right)');
    const arrow = q('[data-icon-type="chevronSingleDown"]', layoutOf(field));
    assert.true(box(arrow).left < box(field).left + 40, 'the arrow sits at inline end (left)');

    const thumbs = q('.cs').querySelectorAll('.euiColorStopThumb');
    assert.true(box(thumbs[0]!).left < box(thumbs[1]!).left, 'stops keep the physical left-to-right gradient');

    // white: saturation 0 → the indicator at the physical left edge of the square
    const saturation = q('.inline .euiSaturation');
    const indicator = q('.inline .euiSaturation__indicator');
    assert.true(Math.abs(box(indicator).left + 6 - box(saturation).left) < 1.5, 'indicator follows the physical gradient');
  });

  test('high contrast: real borders on swatches, hue, saturation and palettes; standard isolated', async function (assert) {
    const noop = () => {};
    const colors = ['#ff0000', '#00ff00'];
    await render(
      <template>
        <EuiEmotionProvider @highContrastMode="preferred">
          <EuiColorPicker class="hc" @color="#D36086" @onChange={{noop}} @display="inline" @swatches={{SWATCHES}} />
          <EuiColorPaletteDisplay class="hcpd" @palette={{colors}} />
        </EuiEmotionProvider>
        <EuiColorPicker class="std" @color="#D36086" @onChange={{noop}} @display="inline" @swatches={{SWATCHES}} />
      </template>
    );

    const hcSwatch = q('.hc .euiColorPickerSwatch');
    assert.strictEqual(css(hcSwatch).borderTopColor, rgb(light.border.color), 'border.thin');
    assert.strictEqual(css(hcSwatch).boxShadow, 'none');
    assert.notStrictEqual(css(q('.std .euiColorPickerSwatch')).boxShadow, 'none', 'standard inset highlight');

    const hue = q('.hc .euiHue');
    assert.strictEqual(css(hue).borderTopStyle, 'solid');
    assert.strictEqual(css(hue).borderTopColor, rgb(light.border.color));
    assert.strictEqual(css(q('.std .euiHue')).borderTopStyle, 'none');

    const satAfter = css(q('.hc .euiSaturation'), '::after');
    assert.strictEqual(satAfter.borderTopStyle, 'solid');
    assert.strictEqual(satAfter.borderTopColor, rgb(light.border.color));
    assert.strictEqual(css(q('.std .euiSaturation'), '::after').content, 'none');

    const indicator = q('.hc .euiSaturation__indicator');
    assert.strictEqual(css(indicator).borderTopWidth, light.border.width.thick);
    assert.strictEqual(css(indicator).backgroundColor, rgb(light.colors.plainLight));

    assert.strictEqual(css(q('.hcpd'), '::after').borderTopColor, rgb(light.border.color));
  });
});
