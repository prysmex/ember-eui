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
import type { EuiCss } from '../utils/eui/styles.ts';

import EuiToolTip from './eui-tool-tip.gts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiToolTipSignature } from './eui-tool-tip';

export interface EuiColorPickerSwatchToolTipProps {
  content?: string;
  position?: EuiToolTipSignature['Args']['position'];
  delay?: EuiToolTipSignature['Args']['delay'];
  title?: string;
  offset?: number;
  id?: string;
  display?: EuiToolTipSignature['Args']['display'];
  className?: string;
  css?: EuiToolTipSignature['Args']['css'];
  anchorClassName?: string;
  anchorCss?: EuiToolTipSignature['Args']['anchorCss'];
}

/**
 * A button showing a color, to pick it; the swatches of `EuiColorPicker`.
 * Add `{{on "click" …}}` to handle the choice.
 */
export interface EuiColorPickerSwatchSignature {
  Element: HTMLButtonElement;
  Args: {
    /** The color: a hex string or `'r, g, b(, a)'`. */
    color?: string;
    /**
     * Shows a tooltip with the color value, as a visual text alternative to
     * the button's label. Defaults to `true`.
     */
    showToolTip?: boolean;
    /**
     * Props of the tooltip (upstream `toolTipProps`): `content` (defaults to
     * the color), `position`, `delay`, `title`, `offset`, `id`, `display`,
     * `className`, `css`, `anchorClassName` and `anchorCss`.
     */
    toolTipProps?: EuiColorPickerSwatchToolTipProps;
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

  /** Upstream: the caller's anchor css, then `styles.tooltip`. */
  @cached
  get anchorCss(): EuiCss {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiColorPickerSwatchStyles);

    return [this.args.toolTipProps?.anchorCss, styles.tooltip];
  }

  get showToolTip(): boolean {
    return this.args.showToolTip ?? true;
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
    {{#if this.showToolTip}}
      {{! the button already has a label, so the tooltip is only visual }}
      <EuiToolTip
        @content={{if @toolTipProps.content @toolTipProps.content @color}}
        @position={{@toolTipProps.position}}
        @delay={{@toolTipProps.delay}}
        @title={{@toolTipProps.title}}
        @offset={{@toolTipProps.offset}}
        @id={{@toolTipProps.id}}
        @display={{@toolTipProps.display}}
        @className={{@toolTipProps.className}}
        @css={{@toolTipProps.css}}
        @anchorClassName={{@toolTipProps.anchorClassName}}
        @anchorCss={{this.anchorCss}}
        @disableScreenReaderOutput={{true}}
      >
        <button
          type="button"
          class={{this.classes}}
          aria-label={{this.label}}
          style={{cssStyle (hash background=this.background)}}
          ...attributes
        ></button>
      </EuiToolTip>
    {{else}}
      <button
        type="button"
        class={{this.classes}}
        aria-label={{this.label}}
        style={{cssStyle (hash background=this.background)}}
        ...attributes
      ></button>
    {{/if}}
  </template>
}
