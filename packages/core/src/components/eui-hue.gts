import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { service } from '@ember/service';

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
    /** The current color as hex, announced to screen readers. */
    hex?: string;
    /** Prefix of the input's id. */
    id?: string;
    /** Called with the new hue. */
    onChange: (hue: number) => void;
  };
}

export default class EuiHue extends Component<EuiHueSignature> {
  @service declare euiI18n: EuiI18n;

  get label(): string {
    return this.euiI18n.lookupToken('euiHue.label', "Select the HSV color mode 'hue' value");
  }

  @action
  onInput(event: Event): void {
    this.args.onChange(Number((event.target as HTMLInputElement).value));
  }

  <template>
    <EuiScreenReaderOnly><label for="{{@id}}-hue">{{this.label}}</label></EuiScreenReaderOnly>
    <EuiScreenReaderOnly><p aria-live="polite">{{@hex}}</p></EuiScreenReaderOnly>
    <div class="euiHue">
      <input
        id="{{@id}}-hue"
        class="euiHue__range"
        type="range"
        min="0"
        max="359"
        step="1"
        value={{if @hue @hue 1}}
        {{on "input" this.onInput}}
        ...attributes
      />
    </div>
  </template>
}
