import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { buttonReset } from '../utils/eui/form-controls.ts';
import {
  calculateThumbPosition,
  EUI_THUMB_SIZE,
  logicalStyle,
  tickLabelShift
} from '../utils/eui/range.ts';
import {
  euiRangeTicksStyles,
  euiRangeTickStyles
} from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';

import type { SafeString } from '@ember/template';

/** A custom tick of EuiRange / EuiDualRange: `{ value: 20, label: '20kb' }`. */
export interface EuiRangeTick {
  /** Where the tick is. */
  value: number;
  /** Its label. */
  label: unknown;
  /**
   * Screen reader text for the value (`aria-valuetext`), when the label is
   * not a usable string.
   */
  accessibleLabel?: string;
}

type Value = string | number;

export type EuiRangeTicksArgs = {
  /** Custom ticks; without them, ticks are rendered for every interval step */
  ticks?: EuiRangeTick[];
  /** Values to render ticks at. */
  tickSequence: number[];
  /** The value. */
  value?: Value | Value[];
  /** Lowest value. */
  min: number;
  /** Highest value. */
  max: number;
  /** Compressed (smaller) spacing. */
  compressed?: boolean;
  /** Interval between ticks. */
  interval?: number;
  /** Disabled ticks. */
  disabled?: boolean;
  /** Called with the click event when a tick is clicked (its `value` is the tick). */
  onChange?: (e: MouseEvent) => void;
  /** Width of the track in px. */
  trackWidth?: number;
};

/** @private The ticks under the track of EuiRange / EuiDualRange. */
export interface EuiRangeTicksSignature {
  Element: HTMLDivElement;
  Args: EuiRangeTicksArgs;
}

interface RenderedTick {
  value: number;
  label: unknown;
  title: string | undefined;
  classes: string;
  style: SafeString | undefined;
  pseudo: SafeString | undefined | false;
}

/**
 * Upstream `EuiRangeTicks`: a `button.euiRangeTick` per value with a
 * `::before` tick mark (or a `span.euiRangeTick__pseudo` for shifted long
 * min/max labels).
 */
export default class EuiRangeTicks extends Component<EuiRangeTicksSignature> {
  get context() {
    return getEuiThemeContext(this);
  }

  get percentageWidth(): number {
    const { max, min, interval = 1 } = this.args;
    return (interval / (max - min + interval)) * 100;
  }

  @cached
  get classes(): string {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiRangeTicksStyles);
    return `euiRangeTicks ${euiClass(
      context,
      styles.euiRangeTicks,
      this.args.compressed ? styles.compressed : styles.regular,
      this.args.ticks && styles.isCustom
    )}`;
  }

  @cached
  get ticks(): RenderedTick[] {
    const { ticks, min, max, value, compressed, trackWidth = 0 } = this.args;
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiRangeTickStyles);
    const hasCustomTicks = !!ticks;
    const percentageWidth = this.percentageWidth;
    const xs = context.upstream.euiTheme.size.xs;

    return this.args.tickSequence.map((tickValue) => {
      const tickObject = hasCustomTicks
        ? ticks.find((tick) => tick.value === tickValue)
        : { value: tickValue, label: tickValue };
      const isMinTick = tickObject?.value === min;
      const isMaxTick = tickObject?.value === max;
      const label = tickObject ? tickObject.label : tickValue;
      const shift = tickLabelShift(label, isMinTick, isMaxTick);
      const pseudoTick = !!tickObject && !!shift && (isMinTick || isMaxTick);
      const selected = !Array.isArray(value) && String(value) === String(tickValue);

      const position: Record<string, string | undefined> = {};
      if (isMaxTick && shift) {
        position['right'] = '0%';
        position['marginRight'] = `-${shift}em`;
      } else {
        const left = calculateThumbPosition(tickValue, min, max, trackWidth);
        position['left'] = `calc(${left}% + ${shift ? 0 : EUI_THUMB_SIZE / 2}px)`;
        if (shift) position['marginLeft'] = `-${shift}em`;
      }
      position['maxWidth'] = hasCustomTicks ? undefined : `${percentageWidth}%`;

      return {
        value: tickValue,
        label,
        title:
          typeof label === 'string' || typeof label === 'number'
            ? String(label)
            : undefined,
        classes: `euiRangeTick ${euiClass(
          context,
          buttonReset,
          styles.euiRangeTick,
          selected && styles.selected,
          hasCustomTicks && styles.isCustom,
          !!shift && isMinTick && styles.isMin,
          !!shift && isMaxTick && styles.isMax,
          !pseudoTick && styles.hasPseudoTickMark,
          compressed ? styles.compressed : styles.regular
        )}`,
        style: logicalStyle(position),
        pseudo:
          pseudoTick &&
          logicalStyle({
            [isMaxTick ? 'marginRight' : 'marginLeft']: `calc(${shift}em + ${xs})`
          })
      };
    });
  }

  @cached
  get pseudoClass(): string {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiRangeTickStyles);
    return `euiRangeTick__pseudo ${euiClass(context, styles.euiRangeTick__pseudo)}`;
  }

  <template>
    <div class={{this.classes}} ...attributes>
      {{#each this.ticks key="value" as |tick|}}
        <button
          type="button"
          class={{tick.classes}}
          value={{tick.value}}
          disabled={{@disabled}}
          style={{tick.style}}
          title={{tick.title}}
          tabindex="-1"
          {{on "click" (optional @onChange)}}
        >
          {{#if tick.pseudo}}
            <span
              class={{this.pseudoClass}}
              aria-hidden="true"
              style={{tick.pseudo}}
            ></span>
          {{/if}}
          {{! @glint-expect-error labels are strings, numbers or safe strings }}
          {{tick.label}}
        </button>
      {{/each}}
    </div>
  </template>
}
