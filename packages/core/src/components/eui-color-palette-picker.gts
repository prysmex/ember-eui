import Component from '@glimmer/component';

import EuiColorPaletteDisplay from './eui-color-palette-display.gts';
import EuiSuperSelect from './eui-super-select.gts';

import type { ColorStop } from '../-private/color.ts';
import type { EuiSuperSelectOption } from './eui-super-select';

export interface EuiColorPalettePickerPalette {
  /** The value passed to `@onChange` when chosen. */
  value: string;
  /** Name of the palette. */
  title?: string;
  /**
   * `'fixed'` (solid blocks), `'gradient'`, or `'text'` for an option
   * that is only its title (e.g. "Custom").
   */
  type: 'fixed' | 'gradient' | 'text';
  /** The colors or `{ stop, color }` stops (not for `'text'`). */
  palette?: (string | ColorStop)[];
}

/**
 * A select of color palettes (e.g. for charts), showing each palette as a
 * bar of colors. Built on `EuiSuperSelect`.
 */
export interface EuiColorPalettePickerSignature {
  Element: HTMLButtonElement;
  Args: {
    /** The palettes to choose from. */
    palettes: EuiColorPalettePickerPalette[];
    /** Value of the selected palette. */
    valueOfSelected?: string;
    /** Called with the chosen palette's value. */
    onChange: (value: string) => void;
    /**
     * Show the selected palette as its `'palette'` (colors) or its
     * `'title'`. Defaults to `'palette'`.
     */
    selectionDisplay?: 'palette' | 'title';
    /** Smaller, for dense forms. */
    compressed?: boolean;
    /** Takes the container's full width. */
    fullWidth?: boolean;
    /** Invalid look. */
    isInvalid?: boolean;
    /** Shows a spinner. */
    isLoading?: boolean;
  };
}

type PaletteOption = EuiSuperSelectOption & { palette: EuiColorPalettePickerPalette };

export default class EuiColorPalettePicker extends Component<EuiColorPalettePickerSignature> {
  get options(): PaletteOption[] {
    return this.args.palettes.map((palette) => ({
      value: String(palette.value),
      inputDisplay: palette.title,
      palette
    }));
  }

  showTitleOnly = (palette: EuiColorPalettePickerPalette): boolean =>
    palette.type === 'text' || this.args.selectionDisplay === 'title';

  <template>
    <EuiSuperSelect
      @options={{this.options}}
      @valueOfSelected={{@valueOfSelected}}
      @onChange={{@onChange}}
      @hasDividers={{true}}
      @compressed={{@compressed}}
      @fullWidth={{@fullWidth}}
      @isInvalid={{@isInvalid}}
      @isLoading={{@isLoading}}
      ...attributes
    >
      <:inputDisplay as |option|>
        {{#let (paletteOf option) as |palette|}}
          {{#if (this.showTitleOnly palette)}}
            {{palette.title}}
          {{else}}
            <EuiColorPaletteDisplay
              @type={{fixedOrGradient palette.type}}
              @palette={{paletteColors palette}}
              @title={{palette.title}}
            />
          {{/if}}
        {{/let}}
      </:inputDisplay>
      <:dropdownDisplay as |option|>
        {{#let (paletteOf option) as |palette|}}
          <div class="euiColorPalettePicker__item">
            {{#if (isText palette.type)}}
              {{palette.title}}
            {{else}}
              {{#if palette.title}}
                {{! the display's screen reader title names the option }}
                <div aria-hidden="true" class="euiColorPalettePicker__itemTitle">{{palette.title}}</div>
              {{/if}}
              <EuiColorPaletteDisplay
                @type={{fixedOrGradient palette.type}}
                @palette={{paletteColors palette}}
                @title={{palette.title}}
              />
            {{/if}}
          </div>
        {{/let}}
      </:dropdownDisplay>
    </EuiSuperSelect>
  </template>
}

function paletteOf(option: EuiSuperSelectOption<unknown>): EuiColorPalettePickerPalette {
  return (option as PaletteOption).palette;
}

function paletteColors(palette: EuiColorPalettePickerPalette): (string | ColorStop)[] {
  return palette.palette ?? [];
}

function fixedOrGradient(type: string): 'fixed' | 'gradient' {
  return type === 'gradient' ? 'gradient' : 'fixed';
}

function isText(type: string): boolean {
  return type === 'text';
}
