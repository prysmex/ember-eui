import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { hash } from '@ember/helper';

import { getFixedLinearGradient, getLinearGradient } from '../-private/color.ts';
import cssStyle from '../-private/css-style.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { boxReset } from '../utils/eui/color-picker.ts';
import {
  euiColorPaletteDisplayFixed__bleedArea,
  euiColorPaletteDisplayStyles
} from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiScreenReaderOnly from './eui-screen-reader-only.gts';

import type { ColorStop } from '../-private/color.ts';

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

/** A palette bar on the upstream EUI 123 / Borealis palette display styles. */
export default class EuiColorPaletteDisplay extends Component<EuiColorPaletteDisplaySignature> {
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiColorPaletteDisplayStyles);
    const size = this.args.size ?? 's';

    return `euiColorPaletteDisplay ${euiClass(
      context,
      boxReset,
      styles.euiColorPaletteDisplay,
      styles[size] ?? styles.s
    )}`;
  }

  @cached
  get bleedAreaClasses(): string {
    const context = getEuiThemeContext(this);

    return `euiColorPaletteDisplayFixed__bleedArea ${euiClass(context, euiColorPaletteDisplayFixed__bleedArea)}`;
  }

  get isGradient(): boolean {
    return this.args.type === 'gradient';
  }

  @cached
  get gradient(): string {
    return getLinearGradient(this.args.palette);
  }

  @cached
  get fixed() {
    return getFixedLinearGradient(this.args.palette);
  }

  <template>
    {{#if this.isGradient}}
      {{#if @title}}
        <EuiScreenReaderOnly><span>{{@title}}</span></EuiScreenReaderOnly>
      {{/if}}
      <span
        class={{this.classes}}
        aria-hidden="true"
        style={{cssStyle (hash background=this.gradient)}}
        ...attributes
      ></span>
    {{else}}
      <span class={{this.classes}} ...attributes>
        {{#if @title}}
          <EuiScreenReaderOnly><span>{{@title}}</span></EuiScreenReaderOnly>
        {{/if}}
        <span aria-hidden="true" class={{this.bleedAreaClasses}}>
          {{#each this.fixed as |item|}}
            <span
              style={{cssStyle
                (hash backgroundColor=item.color width=item.width)
              }}
            ></span>
          {{/each}}
        </span>
      </span>
    {{/if}}
  </template>
}
