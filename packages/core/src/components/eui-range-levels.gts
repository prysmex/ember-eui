import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { assert } from '@ember/debug';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { levelPosition, logicalStyle } from '../utils/eui/range.ts';
import {
  euiRangeLevelsStyles,
  euiRangeLevelStyles,
  isNamedLevelColor
} from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';

import type { EuiCss } from '../utils/eui/styles.ts';
import type { SafeString } from '@ember/template';

export type EuiRangeLevelColor = 'primary' | 'success' | 'warning' | 'danger';

export const LEVEL_COLORS: EuiRangeLevelColor[] = [
  'primary',
  'success',
  'warning',
  'danger'
];

/**
 * A colored interval of EuiRange / EuiDualRange's track, e.g.
 * `{ min: 0, max: 20, color: 'danger' }`.
 */
export interface EuiRangeLevel {
  /** Start of the interval. */
  min: number;
  /** End of the interval. */
  max: number;
  /**
   * `'primary'`, `'success'`, `'warning'`, `'danger'` (theme colors) or any
   * CSS color.
   */
  color: EuiRangeLevelColor | (string & {});
  /** Extra classes for the level's `<span>`. */
  className?: string;
}

export type EuiRangeLevelsArgs = {
  /** Colored intervals, see `EuiRangeLevel`. */
  levels?: EuiRangeLevel[];
  /** Highest value. */
  max: number;
  /** Lowest value. */
  min: number;
  /** Positions the levels on a thumb-height track (room for ticks). */
  showTicks?: boolean;
  /** Stripes the levels, so a highlighted range stands out. */
  showRange?: boolean;
  /** @deprecated Has no effect (upstream has no compressed levels). */
  compressed?: boolean;
  /** Width of the track in px. */
  trackWidth?: number;
  /** @private Styles composed last into the root's class (upstream `css`). */
  css?: EuiCss;
};

/** @private Renders the `@levels` of EuiRange / EuiDualRange. */
export interface EuiRangeLevelsSignature {
  Element: HTMLDivElement;
  Args: EuiRangeLevelsArgs;
  Blocks: { default: [] };
}

interface RenderedLevel {
  classes: string;
  style: SafeString | undefined;
}

export default class EuiRangeLevels extends Component<EuiRangeLevelsSignature> {
  get context() {
    return getEuiThemeContext(this);
  }

  @cached
  get classes(): string {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiRangeLevelsStyles);
    return `euiRangeLevels ${euiClass(
      context,
      styles.euiRangeLevels,
      this.args.showTicks && styles.hasTicks,
      this.args.showRange && styles.hasRange,
      this.args.css
    )}`;
  }

  @cached
  get levels(): RenderedLevel[] {
    const { min, max, trackWidth = 0 } = this.args;
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiRangeLevelStyles);
    return (this.args.levels ?? []).map((level) => {
      assert(
        `The level min of ${level.min} is lower than the min value of ${min}.`,
        !(level.min < min)
      );
      assert(
        `The level max of ${level.max} is higher than the max value of ${max}.`,
        !(level.max > max)
      );
      const named = isNamedLevelColor(level.color);
      const position = levelPosition(level, min, max, trackWidth);
      return {
        classes: [
          'euiRangeLevel',
          level.className,
          euiClass(
            context,
            styles.euiRangeLevel,
            named
              ? styles[level.color as EuiRangeLevelColor]
              : styles.customColor
          )
        ]
          .filter(Boolean)
          .join(' '),
        style: logicalStyle({
          ...position,
          backgroundColor: named ? undefined : level.color
        })
      };
    });
  }

  <template>
    <div class={{this.classes}} ...attributes>
      {{#each this.levels as |level|}}
        <span class={{level.classes}} style={{level.style}}></span>
      {{/each}}
    </div>
  </template>
}
