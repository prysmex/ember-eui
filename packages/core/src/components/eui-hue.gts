import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { boxReset, inputReset } from '../utils/eui/color-picker.ts';
import { euiHueStyles } from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiScreenReaderOnly from './eui-screen-reader-only.gts';

import type EuiI18n from '../services/eui-i18n';

/**
 * The hue slider of `EuiColorPicker` (0 to 359), with the rainbow track.
 * Rendered for you by the color picker.
 */
export interface EuiHueSignature {
  Element: HTMLInputElement;
  Args: {
    /** The hue, 0 to 359. Defaults to `1`. */
    hue?: number;
    /**
     * The current color as hex. Upstream shows it in a tooltip over the
     * thumb, which is not ported; `EuiColorPicker` announces the color.
     */
    hex?: string;
    /** Prefix of the input's id. */
    id?: string;
    /** Called with the new hue. */
    onChange: (hue: number) => void;
  };
}

/** The hue slider on the upstream EUI 123 / Borealis hue styles. */
export default class EuiHue extends Component<EuiHueSignature> {
  @service declare euiI18n: EuiI18n;

  @cached
  get styles() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiHueStyles);

    return {
      root: `euiHue ${euiClass(context, boxReset, styles.euiHue)}`,
      // upstream: the EuiToolTip anchor around the range (taller than the
      // track, so the thumb can overflow it)
      anchor: euiClass(context, { display: 'block' }, styles.euiHue__tooltip),
      range: `euiHue__range ${euiClass(context, inputReset, styles.euiHue__range)}`
    };
  }

  get hue(): number {
    return this.args.hue ?? 1;
  }

  get label(): string {
    return this.euiI18n.lookupToken('euiHue.label', "Select the HSV color mode 'hue' value");
  }

  get roleDescription(): string {
    return this.euiI18n.lookupToken('euiHue.ariaRoleDescription', 'Hue slider');
  }

  get valueText(): string {
    return `${this.euiI18n.lookupToken('euiHue.ariaValueText', 'Hue')} ${this.hue}°`;
  }

  @action
  onInput(event: Event): void {
    this.args.onChange(Number((event.target as HTMLInputElement).value));
  }

  <template>
    <div class={{this.styles.root}}>
      <EuiScreenReaderOnly><label for="{{@id}}-hue">{{this.label}}</label></EuiScreenReaderOnly>
      <div class={{this.styles.anchor}}>
        <input
          id="{{@id}}-hue"
          class={{this.styles.range}}
          type="range"
          min="0"
          max="359"
          step="1"
          value={{this.hue}}
          aria-roledescription={{this.roleDescription}}
          aria-valuetext={{this.valueText}}
          {{on "input" this.onInput}}
          ...attributes
        />
      </div>
    </div>
  </template>
}
