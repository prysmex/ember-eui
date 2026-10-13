import Component from '@glimmer/component';

import EuiColorPaletteDisplay from './eui-color-palette-display.gts';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiSpacer from './eui-spacer.gts';
import EuiSuperSelect from './eui-super-select.gts';
import EuiText from './eui-text.gts';

import type { ComponentLike } from '@glint/template';
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
  /**
   * Shown to the right of the title in the list (not for `'text'`
   * options, as upstream): text, or a component (React nodes become
   * components in Ember), e.g. a badge or a button.
   */
  append?: string | ComponentLike;
}

/**
 * A select of color palettes (e.g. for charts), showing each palette as a
 * bar of colors. Built on `EuiSuperSelect`; each option shows the title
 * (EuiText `xs`) above the palette, as upstream.
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
    /** Disables the select. */
    disabled?: boolean;
    /** Read-only: the list does not open. */
    readOnly?: boolean;
  };
  Blocks: {
    /**
     * Content before the picker (upstream's `prepend`), e.g. a label or
     * an icon; yields the class to put on it.
     */
    prepend: [className: string];
    /** Content after the picker (upstream's `append`); yields the class to put on it. */
    append: [className: string];
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
      @compressed={{@compressed}}
      @fullWidth={{@fullWidth}}
      @isInvalid={{@isInvalid}}
      @isLoading={{@isLoading}}
      @disabled={{@disabled}}
      @readOnly={{@readOnly}}
      @isPrependProvided={{has-block "prepend"}}
      @isAppendProvided={{has-block "append"}}
      ...attributes
    >
      <:prepend as |className|>{{yield className to="prepend"}}</:prepend>
      <:append as |className|>{{yield className to="append"}}</:append>
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
                <EuiFlexGroup @responsive={{false}}>
                  <EuiFlexItem>
                    <EuiText
                      aria-hidden="true"
                      class="euiColorPalettePicker__itemTitle"
                      @size="xs"
                    >{{palette.title}}</EuiText>
                  </EuiFlexItem>
                  {{#if palette.append}}
                    <EuiFlexItem @grow={{false}}>
                      {{#if (isString palette.append)}}
                        {{asText palette.append}}
                      {{else}}
                        {{#let (asComponent palette.append) as |Append|}}<Append />{{/let}}
                      {{/if}}
                    </EuiFlexItem>
                  {{/if}}
                </EuiFlexGroup>
                <EuiSpacer @size="xs" />
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

function isString(value: unknown): boolean {
  return typeof value === 'string';
}

function asText(value: unknown): string {
  return String(value);
}

function asComponent(value: unknown): ComponentLike {
  return value as ComponentLike;
}
