import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { service } from '@ember/service';

import { getChromaColor } from '../-private/color.ts';
import cssStyle from '../-private/css-style.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { buttonReset } from '../utils/eui/color-picker.ts';
import { euiColorPickerSwatchStyles } from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';

import type EuiI18n from '../services/eui-i18n';

/**
 * A button showing a color, to pick it; the swatches of `EuiColorPicker`.
 * Add `{{on "click" …}}` to handle the choice.
 */
export interface EuiColorPickerSwatchSignature {
  Element: HTMLButtonElement;
  Args: {
    /** The color: a hex string or `'r, g, b(, a)'`. */
    color?: string;
  };
}

/** A color swatch button on the upstream EUI 123 / Borealis swatch styles. */
export default class EuiColorPickerSwatch extends Component<EuiColorPickerSwatchSignature> {
  @service declare euiI18n: EuiI18n;

  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiColorPickerSwatchStyles);

    return `euiColorPickerSwatch ${euiClass(context, buttonReset, styles.euiColorPickerSwatch)}`;
  }

  get background(): string {
    return getChromaColor(this.args.color, true)?.css() ?? 'transparent';
  }

  get label(): string {
    return this.euiI18n.lookupToken('euiColorPickerSwatch.ariaLabel', 'Select {color} as the color', {
      color: this.args.color
    });
  }

  <template>
    <button
      type="button"
      class={{this.classes}}
      aria-label={{this.label}}
      style={{cssStyle (hash background=this.background)}}
      ...attributes
    ></button>
  </template>
}
