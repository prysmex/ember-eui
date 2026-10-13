import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { logicalStyle } from '../utils/eui/range.ts';
import {
  euiRangeHighlightLevelsStyles,
  euiRangeHighlightLevelsWrapperStyles,
  euiRangeHighlightProgressStyles,
  euiRangeHighlightStyles
} from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiRangeLevels from './eui-range-levels.gts';

import type { EuiRangeLevel } from './eui-range-levels';

/** @private The highlighted part of the track of EuiRange / EuiDualRange. */
export interface EuiRangeHighlightSignature {
  Element: HTMLDivElement;
  Args: {
    /** Positions the highlight on a thumb-height track (room for ticks). */
    showTicks?: boolean;
    /** @deprecated Has no effect (upstream has no compressed highlight). */
    compressed?: boolean;
    /**
     * @deprecated Has no effect: the highlight turns primary while the
     * slider or a thumb has `:focus-visible`, as upstream.
     */
    hasFocus?: boolean;
    /** Start of the highlighted range. */
    lowerValue?: number;
    /** Lowest value. */
    min?: number;
    /** Highest value. */
    max?: number;
    /** End of the highlighted range. */
    upperValue?: number;
    /** Custom CSS `background` of the highlight. */
    background?: string;
    /** Levels: the highlight then shows the levels' colors instead. */
    levels?: EuiRangeLevel[];
    /** Width of the track in px (for the levels). */
    trackWidth?: number;
  };
}

/**
 * Upstream `EuiRangeHighlight`. Render it after the slider and thumbs: its
 * focus color uses `.euiRangeSlider:focus-visible ~ .euiRangeHighlight`.
 */
export default class EuiRangeHighlight extends Component<EuiRangeHighlightSignature> {
  get context() {
    return getEuiThemeContext(this);
  }

  get min(): number {
    return Number(this.args.min ?? 0);
  }

  get max(): number {
    return Number(this.args.max ?? 100);
  }

  get leftPosition(): number {
    return (Number(this.args.lowerValue ?? this.min) - this.min) / (this.max - this.min);
  }

  get rangeWidth(): number {
    return (
      (Number(this.args.upperValue ?? this.max) -
        Number(this.args.lowerValue ?? this.min)) /
      (this.max - this.min)
    );
  }

  get hasLevels(): boolean {
    return !!this.args.levels && this.args.levels.length > 0;
  }

  @cached
  get classes() {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiRangeHighlightStyles);
    const progress = useEuiBorealisStyles(context, euiRangeHighlightProgressStyles);
    const wrapper = useEuiBorealisStyles(context, euiRangeHighlightLevelsWrapperStyles);
    const levels = useEuiBorealisStyles(context, euiRangeHighlightLevelsStyles);
    return {
      root: `euiRangeHighlight ${euiClass(
        context,
        styles.euiRangeHighlight,
        this.args.showTicks && styles.hasTicks
      )}`,
      progress: `euiRangeHighlight__progress ${euiClass(
        context,
        progress.euiRangeHighlight__progress
      )}`,
      levelsWrapper: euiClass(context, wrapper.euiRangeHighlight__levelsWrapper),
      levelsCss: levels.euiRangeHighlight__levels
    };
  }

  @cached
  get progressStyle() {
    return logicalStyle({
      background: this.args.background,
      marginLeft: `${this.leftPosition * 100}%`,
      width: `${this.rangeWidth * 100}%`
    });
  }

  @cached
  get levelsWrapperStyle() {
    return logicalStyle({
      marginLeft: `${this.leftPosition * 100}%`,
      width: `${this.rangeWidth * 100}%`
    });
  }

  @cached
  get levelsStyle() {
    const trackWidth = this.args.trackWidth ?? 0;
    return logicalStyle({
      left: `-${trackWidth * this.leftPosition}px`,
      width: `${trackWidth}px`
    });
  }

  <template>
    <div class={{this.classes.root}} ...attributes>
      {{#if this.hasLevels}}
        <div class={{this.classes.levelsWrapper}} style={{this.levelsWrapperStyle}}>
          <EuiRangeLevels
            style={{this.levelsStyle}}
            @css={{this.classes.levelsCss}}
            @levels={{@levels}}
            @max={{this.max}}
            @min={{this.min}}
            @showTicks={{@showTicks}}
            @trackWidth={{@trackWidth}}
          />
        </div>
      {{else}}
        <div
          class={{this.classes.progress}}
          data-test-subj="euiRangeHighlightProgress"
          style={{this.progressStyle}}
        ></div>
      {{/if}}
    </div>
  </template>
}
