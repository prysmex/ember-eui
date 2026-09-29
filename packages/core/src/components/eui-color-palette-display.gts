import { hash } from '@ember/helper';

import { getFixedLinearGradient, getLinearGradient } from '../-private/color.ts';
import cssStyle from '../-private/css-style.ts';
import EuiScreenReaderOnly from './eui-screen-reader-only.gts';

import type { ColorStop } from '../-private/color.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

const SIZES = {
  xs: 'euiColorPaletteDisplay--sizeExtraSmall',
  s: 'euiColorPaletteDisplay--sizeSmall',
  m: 'euiColorPaletteDisplay--sizeMedium'
};

/**
 * Shows a color palette as a bar: `'fixed'` blocks of solid color or a
 * `'gradient'`, e.g. to preview the palette of a chart.
 */
export interface EuiColorPaletteDisplaySignature {
  Element: HTMLSpanElement;
  Args: {
    /**
     * The colors: an array of colors (evenly spread), or of
     * `{ stop, color }` color stops.
     */
    palette: (string | ColorStop)[];
    /** `'fixed'` (solid blocks) or `'gradient'`. Defaults to `'fixed'`. */
    type?: 'fixed' | 'gradient';
    /** Height of the bar: `'xs'`, `'s'` or `'m'`. Defaults to `'s'`. */
    size?: 'xs' | 's' | 'm';
    /** Name of the palette, read by screen readers. */
    title?: string;
  };
}

function classes(size: keyof typeof SIZES = 's'): string {
  return `euiColorPaletteDisplay ${SIZES[size]}`;
}

function isGradient(type?: string): boolean {
  return type === 'gradient';
}

const EuiColorPaletteDisplay: TemplateOnlyComponent<EuiColorPaletteDisplaySignature> =
  <template>
    {{#if (isGradient @type)}}
      {{#if @title}}
        <EuiScreenReaderOnly>{{@title}}</EuiScreenReaderOnly>
      {{/if}}
      <span
        class={{classes @size}}
        aria-hidden="true"
        style={{cssStyle (hash background=(getLinearGradient @palette))}}
        ...attributes
      ></span>
    {{else}}
      <span class={{classes @size}} ...attributes>
        {{#if @title}}
          <EuiScreenReaderOnly>{{@title}}</EuiScreenReaderOnly>
        {{/if}}
        <span aria-hidden="true" class="euiColorPaletteDisplayFixed__bleedArea">
          {{#each (getFixedLinearGradient @palette) as |item|}}
            <span
              style={{cssStyle
                (hash backgroundColor=item.color width=item.width)
              }}
            ></span>
          {{/each}}
        </span>
      </span>
    {{/if}}
  </template>;

export default EuiColorPaletteDisplay;
