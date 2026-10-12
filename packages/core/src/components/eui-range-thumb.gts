import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { buttonReset } from '../utils/eui/form-controls.ts';
import { euiRangeThumbStyles } from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';

import type { EuiCss } from '../utils/eui/styles.ts';

/** @private A draggable thumb of EuiDualRange (and EuiColorStops). */
export interface EuiRangeThumbSignature {
  Element: HTMLButtonElement;
  Args: {
    /** Lowest value (`aria-valuemin`). */
    min?: number;
    /** Highest value (`aria-valuemax`). */
    max?: number;
    /** The value (`aria-valuenow`). */
    value?: number | string;
    /** Disables the thumb (`aria-disabled`, not focusable). */
    disabled?: boolean;
    /** `tabindex` of the thumb. Defaults to `0`. */
    tabIndex?: number;
    /** Positions the thumb on a thumb-height track (room for ticks). */
    showTicks?: boolean;
    /**
     * The range shows number inputs: the thumb is then not focusable, as
     * upstream (the inputs are the keyboard controls).
     */
    showInput?: boolean;
    /** @private Styles composed last into the thumb's class (upstream `css`). */
    css?: EuiCss;
  };
}

/**
 * Upstream `EuiRangeThumb` (the button variant): an absolutely positioned
 * `role="slider"` circle. Position it with an inline `inset-inline-start`.
 */
export default class EuiRangeThumb extends Component<EuiRangeThumbSignature> {
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiRangeThumbStyles);
    return `euiRangeThumb ${euiClass(
      context,
      buttonReset,
      styles.euiRangeThumb,
      this.args.showTicks && styles.hasTicks,
      this.args.css
    )}`;
  }

  get valueNow(): number {
    return Number(this.args.value);
  }

  get tabindex(): number {
    return this.args.showInput || this.args.disabled
      ? -1
      : this.args.tabIndex || 0;
  }

  <template>
    <button
      type="button"
      role="slider"
      class={{this.classes}}
      aria-valuemin={{@min}}
      aria-valuemax={{@max}}
      aria-valuenow={{this.valueNow}}
      aria-disabled={{if @disabled "true"}}
      disabled={{@disabled}}
      tabindex={{this.tabindex}}
      ...attributes
    ></button>
  </template>
}
