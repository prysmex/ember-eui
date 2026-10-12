import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { logicalStyle } from '../utils/eui/range.ts';
import {
  euiRangeTooltipStyles,
  euiRangeTooltipValueStyles
} from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';

import type { EuiRangeTick } from './eui-range-ticks';

export type { EuiRangeTick };

/** React global reset for the `<output>` (upstream rules that follow win). */
const outputReset = { boxSizing: 'border-box', margin: 0 } as const;

export type EuiRangeTooltipArgs = {
  /** The value. */
  value?: number | string;
  /** Content after the value. */
  valueAppend?: unknown;
  /** Content before the value. */
  valuePrepend?: unknown;
  /** Highest value. */
  max: number;
  /** Lowest value. */
  min: number;
  /** `name` of the input (`for` of the `<output>`). */
  name?: string;
  /** Positions the tooltip on a thumb-height track (room for ticks). */
  showTicks?: boolean;
  /** @deprecated Has no effect (upstream has no compressed tooltip). */
  compressed?: boolean;
};

/** @private The value tooltip of EuiRange (`@showValue`). */
export interface EuiRangeTooltipSignature {
  Args: EuiRangeTooltipArgs;
  Blocks: {
    valuePrepend: [];
    value: [];
    valueAppend: [];
  };
}

/**
 * Upstream `EuiRangeTooltip`: an `<output>` with the tooltip colors and an
 * arrow, beside the thumb (after it below the midpoint, before it above).
 */
export default class EuiRangeTooltip extends Component<EuiRangeTooltipSignature> {
  get valuePosition(): number {
    const { value, max, min } = this.args;
    let val = 0;
    if (typeof value === 'number') {
      val = value;
    } else if (typeof value === 'string') {
      val = parseFloat(value);
    }
    const decimal = (val - min) / (max - min);
    // Must be between 0-100%
    const position = decimal <= 1 ? decimal : 1;
    return position >= 0 ? position : 0;
  }

  get side(): 'left' | 'right' {
    return this.valuePosition > 0.5 ? 'left' : 'right';
  }

  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiRangeTooltipStyles);
    const value = useEuiBorealisStyles(context, euiRangeTooltipValueStyles);
    return {
      root: `euiRangeTooltip ${euiClass(context, styles.euiRangeTooltip)}`,
      value: `euiRangeTooltip__value ${euiClass(
        context,
        outputReset,
        value.euiRangeTooltip__value,
        value[this.side],
        this.args.showTicks && value.hasTicks
      )}`
    };
  }

  @cached
  get style() {
    const position = this.valuePosition;
    return this.side === 'left'
      ? logicalStyle({ right: `${(1 - position) * 100}%` })
      : logicalStyle({ left: `${position * 100}%` });
  }

  <template>
    <div class={{this.classes.root}}>
      <output
        class={{this.classes.value}}
        for={{@name}}
        style={{this.style}}
      >{{yield to="valuePrepend"}}{{yield to="value"}}{{yield
          to="valueAppend"
        }}</output>
    </div>
  </template>
}
