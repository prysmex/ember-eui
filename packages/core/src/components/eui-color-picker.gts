import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { next } from '@ember/runloop';
import { service } from '@ember/service';

import chroma from 'chroma-js';
import { modifier } from 'ember-modifier';

import {
  getChromaColor,
  HEX_FALLBACK,
  HSV_FALLBACK,
  parseColor,
  RGB_FALLBACK,
  RGB_JOIN,
  VISUALIZATION_COLORS
} from '../-private/color.ts';
import { randomId } from '../-private/random-id.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { boxReset, listReset } from '../utils/eui/color-picker.ts';
import { euiColorPickerStyles } from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import EuiColorPickerSwatch from './eui-color-picker-swatch.gts';
import EuiFieldText from './eui-field-text.gts';
import EuiFormControlLayout from './eui-form-control-layout.gts';
import EuiFormLabel from './eui-form-label.gts';
import EuiFormRow from './eui-form-row.gts';
import EuiHue from './eui-hue.gts';
import EuiPopover from './eui-popover.gts';
import EuiRange from './eui-range.gts';
import EuiSaturation from './eui-saturation.gts';
import EuiScreenReaderOnly from './eui-screen-reader-only.gts';

import type EuiI18n from '../services/eui-i18n';
import type { HSV, RGBA } from '../-private/color.ts';
import type Owner from '@ember/owner';

export interface EuiColorPickerOutput {
  /** The color as `[r, g, b, a]` (`NaN`s when invalid). */
  rgba: RGBA;
  /** The color as hex (`''` when invalid). */
  hex: string;
  /** Whether the text is a valid color (opaque, unless `@showAlpha`). */
  isValid: boolean;
}

/**
 * A color field: a text input showing the color (hex or `r, g, b`) that
 * opens a popover to pick it from a saturation square and a hue slider,
 * and from swatches. You keep the color: `@onChange` gets the new text and
 * `{ hex, rgba, isValid }`.
 */
export interface EuiColorPickerSignature {
  Element: HTMLDivElement;
  Args: {
    /** The color: a hex string (`'#D36086'`), `'r, g, b'`, or `''`. */
    color?: string;
    /** Called with the new color text and `{ hex, rgba, isValid }`. */
    onChange: (text: string, output: EuiColorPickerOutput) => void;
    /**
     * `'default'` (square, hue and swatches), `'picker'` (no swatches),
     * `'swatch'` (only swatches) or `'secondaryInput'` (only the text
     * field set by `@secondaryInputDisplay`). Defaults to `'default'`.
     */
    mode?: 'default' | 'picker' | 'swatch' | 'secondaryInput';
    /** `'default'` (a field opening a popover) or `'inline'` (the picker itself). */
    display?: 'default' | 'inline';
    /** The swatches. Defaults to EUI's color-blind safe palette. */
    swatches?: string[];
    /** Adds an opacity slider; the color can then have an alpha channel. */
    showAlpha?: boolean;
    /** `'hex'` or `'rgba'` output. Defaults to the format of `@color`. */
    format?: 'hex' | 'rgba';
    /**
     * A text field inside the popover: `'top'`, `'bottom'` or `'none'`.
     * Defaults to `'none'`.
     */
    secondaryInputDisplay?: 'top' | 'bottom' | 'none';
    /** Adds a button clearing the color. */
    isClearable?: boolean;
    /** Placeholder while empty. Defaults to "Transparent". */
    placeholder?: string;
    /** Smaller field. */
    compressed?: boolean;
    /** Takes the container's full width. */
    fullWidth?: boolean;
    /** Disables it. */
    disabled?: boolean;
    /** Read-only: the popover does not open. */
    readOnly?: boolean;
    /** Invalid look. */
    isInvalid?: boolean;
    /** `id` of the input. */
    id?: string;
    /** Called when the popover opens. */
    onFocus?: () => void;
    /** Called when the field loses focus or the popover closes. */
    onBlur?: () => void;
  };
  Blocks: {
    /**
     * A custom trigger instead of the field (e.g. a swatch button); yields
     * the function toggling the popover.
     */
    button: [toggle: () => void];
    /** Content before the field; yields the class to put on it. */
    prepend: [className: string, inputId: string];
    /** Content after the field; yields the class to put on it. */
    append: [className: string, inputId: string];
  };
}

function hsvOf(color: ReturnType<typeof getChromaColor>, fallbackHue = 0): HSV {
  if (!color) return HSV_FALLBACK;

  const [h, s, v] = color.hsv();

  // black, white and grays have no hue
  return [isNaN(h) ? fallbackHue : h, s, v];
}

export default class EuiColorPicker extends Component<EuiColorPickerSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked isColorSelectorShown = false;
  @tracked colorAsHsv: HSV;
  @tracked alphaInput?: string;

  ownId = `euiColorPicker_${randomId()}`;
  openLabelId = `${this.ownId}-openLabel`;
  closeLabelId = `${this.ownId}-closeLabel`;
  prevColor: string | null;
  input?: HTMLInputElement;
  saturation?: HTMLElement;
  firstSwatch?: HTMLElement;

  constructor(owner: Owner, args: EuiColorPickerSignature['Args']) {
    super(owner, args);

    const color = getChromaColor(args.color, args.showAlpha);

    this.prevColor = color ? color.rgba().join() : null;
    this.colorAsHsv = color ? hsvOf(color) : HSV_FALLBACK;
  }

  get id(): string {
    return this.args.id ?? this.ownId;
  }

  get mode(): string {
    return this.args.mode ?? 'default';
  }

  get secondaryInputDisplay(): string {
    return this.args.secondaryInputDisplay ?? 'none';
  }

  get chromaColor(): ReturnType<typeof getChromaColor> {
    return getChromaColor(this.args.color, this.args.showAlpha);
  }

  get preferredFormat(): 'hex' | 'rgba' {
    if (this.args.format) return this.args.format;

    const parsed = parseColor(this.args.color);

    return parsed !== null && typeof parsed === 'object' ? 'rgba' : 'hex';
  }

  get alphaChannel(): number {
    return this.chromaColor ? this.chromaColor.alpha() : 1;
  }

  get alphaRangeValue(): number {
    return Number(this.alphaInput ?? (this.alphaChannel * 100).toFixed());
  }

  /** The color as HSV; the hue is kept for colors without one. */
  get usableHsv(): HSV {
    const color = this.chromaColor;

    if (color && color.rgba().join() !== this.prevColor) {
      return hsvOf(color, this.colorAsHsv[0]);
    }

    return this.colorAsHsv;
  }

  get hex(): string | undefined {
    return this.chromaColor?.hex();
  }

  get inputValue(): string {
    return this.args.color ? this.args.color.toUpperCase() : HEX_FALLBACK;
  }

  get placeholder(): string | undefined {
    if (this.args.color) return undefined;

    return this.args.placeholder ?? this.euiI18n.lookupToken('euiColorPicker.transparent', 'Transparent');
  }

  get showPicker(): boolean {
    return this.mode !== 'swatch' && this.mode !== 'secondaryInput';
  }

  get showSwatches(): boolean {
    return this.mode !== 'picker' && this.mode !== 'secondaryInput';
  }

  get swatches(): string[] {
    return this.args.swatches ?? VISUALIZATION_COLORS;
  }

  get canClear(): boolean {
    return Boolean(this.args.isClearable && this.args.color && !this.args.readOnly && !this.args.disabled);
  }

  /** The popover / inline root: upstream `euiColorPickerStyles.euiColorPicker`. */
  @cached
  get rootClasses(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiColorPickerStyles);

    return `euiColorPicker ${euiClass(context, boxReset, styles.euiColorPicker)}`;
  }

  @cached
  get swatchesClasses(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiColorPickerStyles);

    return `euiColorPicker__swatches ${euiClass(context, listReset, styles.euiColorPicker__swatches)}`;
  }

  @cached
  get alphaRangeClasses(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiColorPickerStyles);

    // upstream puts these on the EuiRange root; here they sit on a wrapper
    // around it, so the direct-child rule is restated from the range wrapper
    return `euiColorPicker__alphaRange ${euiClass(context, styles.euiColorPicker__alphaRange, {
      '.euiRangeWrapper > .euiFormControlLayout': { flexShrink: 0 }
    })}`;
  }

  /**
   * Upstream's `icon={{ color, css }}`: the field icon takes the chosen
   * color (`subdued` for the empty `stopSlash` icon), and the swatch icon's
   * stroke uses the swatch border color.
   */
  get iconColor(): string {
    return cssColor(this.chromaColor) ?? 'subdued';
  }

  @cached
  get iconCss(): EuiCss {
    const context = getEuiThemeContext(this);
    return useEuiBorealisStyles(context, euiColorPickerStyles)
      .euiColorPicker__swatchInputIcon;
  }

  get panelClasses(): string {
    return 'euiColorPicker__popoverPanel';
  }

  get hexLabel(): string {
    return this.chromaColor ? this.chromaColor.hex().toUpperCase() : '';
  }

  get secondaryInputCompressed(): boolean {
    return this.args.display === 'inline' ? Boolean(this.args.compressed) : true;
  }

  get labels(): {
    popover: string;
    color: string;
    selected: string;
    error: string;
    alpha: string;
    open: string;
    closed: string;
    select: string;
  } {
    const t = (token: string, text: string) => this.euiI18n.lookupToken(`euiColorPicker.${token}`, text);

    return {
      popover: t('popoverLabel', 'Color selection dialog'),
      color: t('colorLabel', 'Color value'),
      selected: t('selectedColorLabel', 'Selected color'),
      error: t('colorErrorMessage', 'Invalid color value'),
      alpha: t('alphaLabel', 'Alpha channel (opacity) value'),
      open: t('openLabel', 'Press the escape key to close the popover'),
      closed: t('closeLabel', 'Press the down key to open a popover containing color options'),
      select: t('ariaLabel', 'Select a color')
    };
  }

  output(text: string): EuiColorPickerOutput {
    const color = getChromaColor(text, true);

    if (!color) return { rgba: RGB_FALLBACK, hex: HEX_FALLBACK, isValid: false };

    // without @showAlpha a transparent color is returned but invalid
    return {
      rgba: color.rgba() as RGBA,
      hex: color.hex(),
      isValid: this.args.showAlpha ? true : color.alpha() === 1
    };
  }

  change(text: string): void {
    const output = this.output(text);

    if (output.isValid) this.prevColor = output.rgba.join();
    this.args.onChange(text, output);
  }

  updateColorAsHsv(hsv: HSV): void {
    this.colorAsHsv = [isNaN(hsv[0]) ? this.usableHsv[0] : hsv[0], hsv[1], hsv[2]];
  }

  updateWithHsv(hsv: HSV): void {
    const color = chroma.hsv(...hsv).alpha(this.alphaChannel);
    const text =
      this.preferredFormat === 'rgba'
        ? (this.alphaChannel < 1 ? color.rgba() : color.rgb()).join(RGB_JOIN)
        : color.hex();

    this.change(text);
    this.updateColorAsHsv(hsv);
  }

  @action
  showColorSelector(): void {
    if (this.isColorSelectorShown || this.args.readOnly) return;

    this.args.onFocus?.();
    this.isColorSelectorShown = true;
  }

  @action
  closeColorSelector(): void {
    this.args.onBlur?.();
    this.isColorSelectorShown = false;
  }

  @action
  toggle(): void {
    if (this.isColorSelectorShown) this.closeColorSelector();
    else this.showColorSelector();
  }

  /** Closes the popover and returns to the field, to keep adjusting. */
  @action
  finalSelection(): void {
    this.input?.focus();
    next(this, this.closeColorSelector);
  }

  @action
  onInputClick(): void {
    this.showColorSelector();
  }

  @action
  onInputKeyDown(event: KeyboardEvent): void {
    if (event.key === 'Enter') {
      event.preventDefault();
      this.toggle();
    }
  }

  @action
  onInputBlur(): void {
    // closing the popover calls onBlur already
    if (!this.isColorSelectorShown) this.args.onBlur?.();
  }

  /** Arrow down opens the popover, then moves into it. */
  @action
  onLayoutKeyDown(event: KeyboardEvent): void {
    if (event.key !== 'ArrowDown') return;

    event.preventDefault();

    if (!this.isColorSelectorShown) {
      this.showColorSelector();

      return;
    }

    (this.mode !== 'swatch' ? this.saturation : this.firstSwatch)?.focus();
  }

  /** Enter in the picker confirms the color. */
  @action
  onPickerKeyDown(event: KeyboardEvent): void {
    if (event.key !== 'Enter') return;

    if (this.isColorSelectorShown) this.finalSelection();
    else this.showColorSelector();
  }

  @action
  onColorInput(event: Event): void {
    const text = (event.target as HTMLInputElement).value;
    const color = getChromaColor(text, this.args.showAlpha);

    this.change(text);
    if (color) this.updateColorAsHsv(hsvOf(color, this.usableHsv[0]));
  }

  @action
  clear(): void {
    this.change('');

    if (this.secondaryInputDisplay === 'none' && this.isColorSelectorShown) {
      this.closeColorSelector();
    }
  }

  @action
  onSaturationChange([, s, v]: HSV): void {
    this.updateWithHsv([this.usableHsv[0], s, v]);
  }

  @action
  onHueChange(hue: number): void {
    const [, s, v] = this.usableHsv;

    this.updateWithHsv([hue, s, v]);
  }

  @action
  onSwatchClick(swatch: string): void {
    const color = getChromaColor(swatch, this.args.showAlpha);

    this.change(swatch);
    if (color) this.updateColorAsHsv(hsvOf(color, this.usableHsv[0]));
    this.finalSelection();
  }

  @action
  onAlphaChange(event: Event, isValid: boolean): void {
    const value = (event.target as HTMLInputElement).value;

    this.alphaInput = value;

    if (!isValid) return;

    const alpha = parseInt(value, 10) / 100;
    const color = this.chromaColor ? this.chromaColor.alpha(alpha) : null;
    const hex = color ? color.hex() : HEX_FALLBACK;
    const rgba = (color ? color.rgba() : RGB_FALLBACK) as RGBA;
    const text =
      this.preferredFormat === 'rgba'
        ? (alpha < 1 ? rgba : rgba.slice(0, 3)).join(RGB_JOIN)
        : hex;

    this.alphaInput = undefined;
    this.args.onChange(text, { hex, rgba, isValid: Boolean(color) });
  }

  registerInput = (element: HTMLInputElement | null): void => {
    this.input = element ?? undefined;
  };

  registerSaturation = modifier((element: HTMLElement) => {
    this.saturation = element;
  });

  registerFirstSwatch = modifier((element: HTMLElement, [index]: [number]) => {
    if (index === 0) this.firstSwatch = element;
  });

  <template>
    {{#if (isInline @display)}}
      <div class={{this.rootClasses}} ...attributes>
        <Composite
          @picker={{this}}
          @isInvalid={{@isInvalid}}
          @disabled={{@disabled}}
          @readOnly={{@readOnly}}
          @showAlpha={{@showAlpha}}
        />
      </div>
    {{else}}
      <EuiPopover
        class="euiColorPicker__popoverAnchor"
        @isOpen={{this.isColorSelectorShown}}
        @closePopover={{this.finalSelection}}
        @panelClassName={{this.panelClasses}}
        @display={{if (has-block "button") "inlineBlock" "block"}}
        @attachToAnchor={{if (has-block "button") false true}}
        @anchorPosition="downLeft"
        @panelPaddingSize="s"
        @ownFocus={{false}}
        @initialFocus={{false}}
        @ariaLabel={{this.labels.popover}}
      >
        <:button>
          {{#if (has-block "button")}}
            {{yield this.toggle to="button"}}
          {{else}}
              <EuiFormControlLayout
                @icon={{if this.chromaColor "swatchInput" "stopSlash"}}
                @clear={{if this.canClear this.clear}}
                @readOnly={{@readOnly}}
                @fullWidth={{@fullWidth}}
                @compressed={{@compressed}}
                @isInvalid={{@isInvalid}}
                @isDisabled={{@disabled}}
                @isDropdown={{true}}
                @isPrependProvided={{has-block "prepend"}}
                @isAppendProvided={{has-block "append"}}
                @iconColor={{this.iconColor}}
                @iconCss={{this.iconCss}}
                {{on "keydown" this.onLayoutKeyDown}}
              >
                <:prepend as |className|>{{yield className this.id to="prepend"}}</:prepend>
                <:field>
                  <EuiFieldText
                    class="euiColorPicker__input"
                    data-test-subj="euiColorPickerAnchor"
                    id={{this.id}}
                    autocomplete="off"
                    aria-label={{unless @id this.labels.select}}
                    aria-describedby={{if this.isColorSelectorShown this.openLabelId this.closeLabelId}}
                    @controlOnly={{true}}
                    @value={{this.inputValue}}
                    @placeholder={{this.placeholder}}
                    @isInvalid={{@isInvalid}}
                    @compressed={{@compressed}}
                    @disabled={{@disabled}}
                    @readOnly={{@readOnly}}
                    @fullWidth={{@fullWidth}}
                    @inputRef={{this.registerInput}}
                    {{on "click" this.onInputClick}}
                    {{on "keydown" this.onInputKeyDown}}
                    {{on "blur" this.onInputBlur}}
                    {{on "input" this.onColorInput}}
                  />
                  <EuiScreenReaderOnly>
                    <span>
                      <span
                        id={{this.openLabelId}}
                        aria-hidden={{if this.isColorSelectorShown "false" "true"}}
                      >{{this.labels.open}}</span>
                      <span
                        id={{this.closeLabelId}}
                        aria-hidden={{if this.isColorSelectorShown "true" "false"}}
                      >{{this.labels.closed}}</span>
                    </span>
                  </EuiScreenReaderOnly>
                </:field>
                <:append as |className|>{{yield className this.id to="append"}}</:append>
              </EuiFormControlLayout>
          {{/if}}
        </:button>
        <:content>
          <div
            class={{this.rootClasses}}
            data-test-subj="euiColorPickerPopover"
            ...attributes
          >
            <Composite
              @picker={{this}}
              @isInvalid={{@isInvalid}}
              @disabled={{@disabled}}
              @readOnly={{@readOnly}}
              @showAlpha={{@showAlpha}}
            />
          </div>
        </:content>
      </EuiPopover>
    {{/if}}
  </template>
}

interface CompositeSignature {
  Args: {
    picker: EuiColorPicker;
    isInvalid?: boolean;
    disabled?: boolean;
    readOnly?: boolean;
    showAlpha?: boolean;
  };
}

/**
 * The saturation square, hue slider, swatches and secondary input: the
 * flex column children of the root (upstream spaces them with `gap`).
 */
class Composite extends Component<CompositeSignature> {
  get picker(): EuiColorPicker {
    return this.args.picker;
  }

  <template>
    {{#if (eq2 this.picker.secondaryInputDisplay "top")}}
      <SecondaryInput
        @picker={{this.picker}}
        @isInvalid={{@isInvalid}}
        @disabled={{@disabled}}
        @readOnly={{@readOnly}}
      />
    {{/if}}
    {{#if this.picker.showPicker}}
      <EuiSaturation
        @id={{this.picker.id}}
        @color={{this.picker.usableHsv}}
        @hex={{this.picker.hex}}
        @onChange={{this.picker.onSaturationChange}}
        {{this.picker.registerSaturation}}
        {{on "keydown" this.picker.onPickerKeyDown}}
      />
      <EuiHue
        @id={{this.picker.id}}
        @hue={{hueOf this.picker.usableHsv}}
        @hex={{this.picker.hex}}
        @onChange={{this.picker.onHueChange}}
        {{on "keydown" this.picker.onPickerKeyDown}}
      />
      <EuiScreenReaderOnly>
        <p aria-live="polite" aria-atomic="true">{{this.picker.labels.selected}}: {{this.picker.hexLabel}}</p>
      </EuiScreenReaderOnly>
    {{/if}}
    {{#if this.picker.showSwatches}}
      <ul class={{this.picker.swatchesClasses}}>
        {{#each this.picker.swatches as |swatch index|}}
          <li>
            <EuiColorPickerSwatch
              class="euiColorPicker__swatchSelect"
              @color={{swatch}}
              {{on "click" (fn this.picker.onSwatchClick swatch)}}
              {{this.picker.registerFirstSwatch index}}
            />
          </li>
        {{/each}}
      </ul>
    {{/if}}
    {{#if (eq2 this.picker.secondaryInputDisplay "bottom")}}
      <SecondaryInput
        @picker={{this.picker}}
        @isInvalid={{@isInvalid}}
        @disabled={{@disabled}}
        @readOnly={{@readOnly}}
      />
    {{/if}}
    {{#if @showAlpha}}
      <div class={{this.picker.alphaRangeClasses}}>
        <EuiRange
          data-test-subj="euiColorPickerAlpha"
          aria-label={{this.picker.labels.alpha}}
          @compressed={{true}}
          @showInput={{true}}
          @min={{0}}
          @max={{100}}
          @value={{this.picker.alphaRangeValue}}
          @onChange={{this.picker.onAlphaChange}}
        >
          <:append><EuiFormLabel>%</EuiFormLabel></:append>
        </EuiRange>
      </div>
    {{/if}}
  </template>
}

interface SecondaryInputSignature {
  Args: {
    picker: EuiColorPicker;
    isInvalid?: boolean;
    disabled?: boolean;
    readOnly?: boolean;
  };
}

class SecondaryInput extends Component<SecondaryInputSignature> {
  get picker(): EuiColorPicker {
    return this.args.picker;
  }

  <template>
    <EuiFormRow
      @isInvalid={{@isInvalid}}
      @error={{if @isInvalid this.picker.labels.error}}
    >
      <EuiFieldText
        data-test-subj="euiColorPickerInput_{{this.picker.secondaryInputDisplay}}"
        autocomplete="off"
        aria-label={{this.picker.labels.color}}
        @compressed={{this.picker.secondaryInputCompressed}}
        @value={{this.picker.inputValue}}
        @placeholder={{this.picker.placeholder}}
        @clear={{if this.picker.canClear this.picker.clear}}
        @isInvalid={{@isInvalid}}
        @disabled={{@disabled}}
        @readOnly={{@readOnly}}
        {{on "input" this.picker.onColorInput}}
      />
    </EuiFormRow>
  </template>
}

function hueOf(hsv: HSV): number {
  return hsv[0];
}

function isInline(display?: string): boolean {
  return display === 'inline';
}

function cssColor(color: ReturnType<typeof getChromaColor>): string | undefined {
  return color ? color.css() : undefined;
}

function eq2(a: unknown, b: unknown): boolean {
  return a === b;
}
