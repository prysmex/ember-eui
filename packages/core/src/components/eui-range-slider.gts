import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { formControlReset } from '../utils/eui/form-controls.ts';
import { logicalStyle } from '../utils/eui/range.ts';
import {
  euiRangeLevelColor,
  euiRangeSliderStyles
} from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';

import type { EuiCss } from '../utils/eui/styles.ts';
import type { CommonArgs } from './common.ts';

export type EuiRangeSliderArgs = CommonArgs & {
  /** Id of the input. */
  id?: string;
  /** `name` of the input. */
  name?: string;
  /** Lowest value. */
  min: number;
  /** Highest value. */
  max: number;
  /** Increment between values. */
  step?: number;
  /** The value. */
  value?: number | string;
  /** @deprecated Has no effect (upstream styles its sizes on the wrapper). */
  compressed?: boolean;
  /**
   * @deprecated Has no effect: focus styling follows `:focus-visible` on the
   * slider (or a thumb), as upstream.
   */
  hasFocus?: boolean;
  /** Makes the native track transparent so the highlight shows through. */
  showRange?: boolean;
  /** Thumb-height slider, leaving room for ticks under the track. */
  showTicks?: boolean;
  /** Disabled styling. */
  disabled?: boolean;
  /** `tabindex` of the control. */
  tabIndex?: number;
  /** @deprecated Has no effect; listen to `input` events instead. */
  onChange?: (e: InputEvent) => void;
  /** Read-only. */
  readonly?: boolean;
  /**
   * Thumb color: a level color name (`'primary'`, `'success'`, `'warning'`,
   * `'danger'`) or any CSS color. EuiRange passes the matching level's color.
   */
  thumbColor?: string;
  /** `aria-valuetext` of the slider. */
  ariaValueText?: string;
  /** @private Styles composed last into the slider's class (upstream `css`). */
  css?: EuiCss;
};

/** @private The native range input of EuiRange / EuiDualRange. */
export interface EuiRangeSliderSignature {
  Element: HTMLInputElement;
  Args: EuiRangeSliderArgs;
}

/**
 * Upstream `EuiRangeSlider`: a transparent native `input[type=range]` whose
 * WebKit/Gecko thumb pseudo-elements get the Borealis thumb styles.
 */
export default class EuiRangeSlider extends Component<EuiRangeSliderSignature> {
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiRangeSliderStyles);
    return `euiRangeSlider ${euiClass(
      context,
      formControlReset,
      styles.euiRangeSlider,
      this.args.showTicks && styles.hasTicks,
      this.args.showRange && styles.hasRange,
      this.args.css
    )}`;
  }

  @cached
  get style() {
    const { thumbColor } = this.args;
    if (!thumbColor) return undefined;
    const context = getEuiThemeContext(this);
    return logicalStyle({
      '--euiRangeThumbColor': euiRangeLevelColor(thumbColor, context.upstream)
    });
  }

  <template>
    <input
      type="range"
      id={{@id}}
      name={{@name}}
      class={{this.classes}}
      style={{this.style}}
      min={{@min}}
      max={{@max}}
      step={{@step}}
      value={{@value}}
      disabled={{@disabled}}
      aria-valuetext={{@ariaValueText}}
      ...attributes
    />
  </template>
}
