import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { fn, hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { schedule } from '@ember/runloop';
import { service } from '@ember/service';

import { modifier } from 'ember-modifier';

import {
  addDefinedStop,
  addStop,
  DEFAULT_VISUALIZATION_COLOR,
  getChromaColor,
  getPositionFromStop,
  getSteppedGradient,
  getStopFromMouseLocation,
  isStopsInvalid,
  removeStop
} from '../-private/color.ts';
import cssStyle from '../-private/css-style.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  boxReset,
  euiColorStopsAddContainerStyles,
  euiColorStopsStyles
} from '../utils/eui/color-picker.ts';
import {
  euiRangeHighlightProgressStyles,
  euiRangeHighlightStyles,
  euiRangeTrackStyles,
  euiRangeWrapperStyles
} from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiColorStopThumb from './eui-color-stops/thumb.gts';
import EuiScreenReaderOnly from './eui-screen-reader-only.gts';

import type EuiI18n from '../services/eui-i18n';
import type { ColorStop } from '../-private/color.ts';

export type { ColorStop };

const DEFAULT_MIN = 0;
const DEFAULT_MAX = 100;
const STOP_ATTR = 'euiColorStop_';

type IndexedStop = ColorStop & { id: number };

/**
 * An editable gradient: a track with color stops (a value and a color
 * each) to drag, click to edit, add (click the track) and remove, e.g. to
 * color a map or a chart by value. You keep the stops: `@onChange` gets
 * the new ones and whether any is invalid.
 */
export interface EuiColorStopsSignature {
  Element: HTMLDivElement;
  Args: {
    /** The stops: `[{ stop: 0, color: '#54B399' }, …]`. */
    colorStops: ColorStop[];
    /** Called with the new stops and whether any stop is invalid. */
    onChange: (colorStops: ColorStop[], isInvalid: boolean) => void;
    /** Accessible name, e.g. "Map colors". */
    label: string;
    /** Lowest stop value; by default the track follows the stops. */
    min?: number;
    /** Highest stop value; by default the track follows the stops. */
    max?: number;
    /**
     * `'gradient'` (colors blend), `'fixed'` (each color until the next
     * stop) or `'stepped'` (`@stepNumber` blended steps). Defaults to
     * `'gradient'`.
     */
    stopType?: 'gradient' | 'fixed' | 'stepped';
    /** Number of steps with `@stopType="stepped"`. Defaults to `10`. */
    stepNumber?: number;
    /** Color of new stops. Defaults to EUI's second visualization color. */
    addColor?: string;
    /** Color picker of each stop: `'default'`, `'swatch'` or `'picker'`. */
    mode?: 'default' | 'swatch' | 'picker';
    /** Swatches of the stops' color pickers. */
    swatches?: string[];
    /** Colors may have an alpha channel. */
    showAlpha?: boolean;
    /** Disables it. */
    disabled?: boolean;
    /** Stops can be inspected but not changed. */
    readOnly?: boolean;
    /** Smaller track. */
    compressed?: boolean;
    /** Takes the container's full width. */
    fullWidth?: boolean;
  };
}

function sortStops(colorStops: ColorStop[]): IndexedStop[] {
  return colorStops.map((el, index) => ({ ...el, id: index })).sort((a, b) => a.stop - b.stop);
}

function validStops(colorStops: ColorStop[]): number[] {
  return colorStops.map((el) => el.stop).filter((stop) => !isNaN(stop));
}

export default class EuiColorStops extends Component<EuiColorStopsSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked wrapper?: HTMLElement;
  @tracked trackWidth = 0;
  @tracked hasFocus = false;
  @tracked focusedStopIndex: number | null = null;
  @tracked openedStopId: number | null = null;
  @tracked addTargetPosition = 0;
  @tracked isHoverDisabled = false;

  // after adding a stop, focus it and open it once rendered
  focusStopOnUpdate: number | null = null;

  get sortedStops(): IndexedStop[] {
    return sortStops(this.args.colorStops);
  }

  get rangeMax(): number {
    const { max, colorStops } = this.args;

    if (max !== undefined) return max;

    const stops = validStops(colorStops);
    const last = Math.max(...stops);
    let result = DEFAULT_MAX;

    if (last > DEFAULT_MAX) result = stops.length === 1 ? last + DEFAULT_MAX : last;

    return isNaN(result) ? DEFAULT_MAX : result + Math.round(result * 0.05);
  }

  get rangeMin(): number {
    const { min, colorStops } = this.args;

    if (min !== undefined) return min;

    const stops = validStops(colorStops);
    const first = Math.min(...stops);
    let result = DEFAULT_MIN;

    if (first < DEFAULT_MIN) result = stops.length === 1 ? first - DEFAULT_MIN : first;

    return isNaN(result) ? DEFAULT_MIN : result - Math.round(this.rangeMax * 0.05);
  }

  get globalMin(): number {
    return this.args.min ?? this.rangeMin;
  }

  get globalMax(): number {
    return this.args.max ?? this.rangeMax;
  }

  get isNotInteractive(): boolean {
    return Boolean(this.args.disabled || this.args.readOnly);
  }

  /**
   * The root: upstream EuiRangeWrapper styles (height, form width) with
   * the EUI 88.5.4 color stops states composed last. The range pieces are
   * rendered here (not through EuiRangeWrapper/Track/Highlight/Thumb) so
   * each element keeps a single Emotion class, as upstream composes them
   * through `css`.
   */
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const wrapper = useEuiBorealisStyles(context, euiRangeWrapperStyles);
    const styles = useEuiBorealisStyles(context, euiColorStopsStyles);
    const { compressed, fullWidth, disabled, readOnly } = this.args;

    return `euiRangeWrapper euiColorStops ${euiClass(
      context,
      boxReset,
      wrapper.euiRangeWrapper,
      compressed ? wrapper.compressed : wrapper.uncompressed,
      fullWidth ? wrapper.fullWidth : wrapper.formWidth,
      styles.euiColorStops,
      disabled ? styles.isDisabled : styles.isEnabled,
      readOnly && styles.isReadOnly,
      this.isHoverDisabled && styles.isDragging
    )}`;
  }

  @cached
  get trackClasses(): string {
    const context = getEuiThemeContext(this);
    const track = useEuiBorealisStyles(context, euiRangeTrackStyles);
    const styles = useEuiBorealisStyles(context, euiColorStopsStyles);

    return `euiRangeTrack euiColorStops__track ${euiClass(
      context,
      track.euiRangeTrack,
      this.args.disabled && track.disabled,
      styles.euiColorStops__track
    )}`;
  }

  @cached
  get highlightClasses() {
    const context = getEuiThemeContext(this);
    const highlight = useEuiBorealisStyles(context, euiRangeHighlightStyles);
    const progress = useEuiBorealisStyles(context, euiRangeHighlightProgressStyles);

    return {
      highlight: `euiRangeHighlight euiColorStops__highlight ${euiClass(context, highlight.euiRangeHighlight)}`,
      progress: `euiRangeHighlight__progress ${euiClass(context, progress.euiRangeHighlight__progress)}`
    };
  }

  get isAddDisabled(): boolean {
    return this.isHoverDisabled || this.isNotInteractive;
  }

  @cached
  get addContainerClasses(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiColorStopsAddContainerStyles);

    return `euiColorStops__addContainer ${euiClass(
      context,
      styles.euiColorStopsAddContainer,
      this.isAddDisabled ? styles.isDisabled : styles.isEnabled
    )}`;
  }

  @cached
  get addTargetClasses(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiColorStopsStyles);

    return `euiColorStops__addTarget ${euiClass(context, styles.euiColorStops__addTarget)}`;
  }

  get announcement(): string {
    return this.euiI18n.lookupToken(
      'euiColorStops.screenReaderAnnouncement',
      '{label}: {readOnly} {disabled} Color stop picker. Each stop consists of a number and corresponding color value. Use the Down and Up arrow keys to select individual stops. Press the Enter key to create a new stop.',
      {
        label: this.args.label,
        disabled: this.args.disabled ? 'Disabled.' : '',
        readOnly: this.args.readOnly ? 'Read-only.' : ''
      }
    );
  }

  positionOf = (stop: number): number =>
    getPositionFromStop(stop, this.trackWidth, this.globalMin, this.globalMax);

  get gradient(): string {
    const stops = this.sortedStops;
    const positions = stops.map((stop) => this.positionOf(stop.stop));
    const colorAt = (index: number) =>
      getChromaColor(stops[index]!.color, this.args.showAlpha)?.css() ?? 'transparent';
    // before the first stop the track (stripes) shows through, as upstream
    const gradientStop = (index: number) =>
      index === 0
        ? `transparent, transparent ${positions[0]}%, ${colorAt(0)} ${positions[0]}%`
        : `${colorAt(index)} ${positions[index]}%`;

    if (this.args.stopType === 'stepped' && positions.length > 0) {
      const start = positions[0]!;
      const end = positions[positions.length - 1]!;
      const colors = getSteppedGradient(this.args.colorStops, this.args.stepNumber ?? 10);
      const width = (end - start) / colors.length;
      const steps = colors
        .map((color, i) => `${color} ${start + width * i}% ${start + width * (i + 1)}%`)
        .join(', ');

      return `linear-gradient(to right, transparent ${start}%, ${steps})`;
    }

    // fixed: each color holds until the next stop (upstream `fixedStop`)
    const parts = stops.map((_, index) =>
      this.args.stopType === 'fixed' && index < stops.length - 1
        ? `${gradientStop(index)}, ${colorAt(index)} ${positions[index + 1]}%`
        : gradientStop(index)
    );

    return `linear-gradient(to right,${parts.join(',')})`;
  }

  change(colorStops: ColorStop[]): void {
    this.args.onChange(colorStops, isStopsInvalid(colorStops, this.args.showAlpha));
  }

  focusStop(index: number): void {
    if (this.args.disabled || !this.wrapper) return;

    const thumb = this.wrapper.querySelector<HTMLElement>(`[data-index="${STOP_ATTR}${index}"]`);

    if (thumb) {
      this.hasFocus = false;
      this.focusedStopIndex = index;
      thumb.focus();
    }
  }

  @action
  focusWrapper(): void {
    this.focusedStopIndex = null;
    this.wrapper?.focus();
  }

  @action
  onAdd(): void {
    const stops = this.sortedStops.map(({ color, stop }) => ({ color, stop }));
    const newStops = addStop(stops, this.args.addColor ?? DEFAULT_VISUALIZATION_COLOR, this.globalMax);

    this.focusStopOnUpdate = newStops[this.args.colorStops.length]!.stop;
    this.change(newStops);
  }

  @action
  onRemove(id: number): void {
    this.focusWrapper();
    this.change(removeStop(this.args.colorStops, id));
  }

  @action
  onStopChange(id: number, colorStop: ColorStop): void {
    const colorStops = [...this.args.colorStops];

    colorStops.splice(id, 1, colorStop);
    this.change(colorStops);
  }

  @action
  onAddHover(event: MouseEvent): void {
    if (this.isNotInteractive || !this.wrapper) return;

    const stop = getStopFromMouseLocation(
      { x: event.clientX, y: event.clientY },
      this.wrapper,
      this.globalMin,
      this.globalMax
    );

    this.addTargetPosition = this.positionOf(stop);
  }

  @action
  onAddClick(event: MouseEvent): void {
    const target = event.target as HTMLElement;

    if (this.isNotInteractive || !this.wrapper || target.closest('.euiColorStopThumb')) return;

    const stop = getStopFromMouseLocation(
      { x: event.clientX, y: event.clientY },
      this.wrapper,
      this.globalMin,
      this.globalMax
    );

    this.focusStopOnUpdate = stop;
    this.change(addDefinedStop(this.args.colorStops, stop, this.args.addColor ?? DEFAULT_VISUALIZATION_COLOR));
  }

  @action
  onKeyDown(event: KeyboardEvent): void {
    if (this.args.disabled) return;

    const target = event.target as HTMLElement;
    const isThumb = (target.getAttribute('data-index') ?? '').startsWith(STOP_ATTR);
    const index = this.focusedStopIndex;

    switch (event.key) {
      case 'Escape':
        this.focusWrapper();
        break;
      case 'Enter':
        if (this.args.readOnly || !this.hasFocus) return;
        this.onAdd();
        break;
      case 'Backspace': {
        if (this.args.readOnly || this.hasFocus || index === null || !isThumb) return;

        const isFirst = this.args.min === undefined && index === 0;
        const isLast = this.args.max === undefined && index === this.sortedStops.length - 1;

        if (!isFirst && !isLast) this.onRemove(this.sortedStops[index]!.id);
        break;
      }
      case 'ArrowDown':
      case 'ArrowUp':
        if (target !== this.wrapper && !isThumb) return;

        event.preventDefault();

        if (index === null) {
          this.focusStop(0);
        } else if (event.key === 'ArrowDown') {
          this.focusStop(Math.min(index + 1, this.sortedStops.length - 1));
        } else {
          this.focusStop(Math.max(index - 1, 0));
        }
        break;
    }
  }

  @action
  onWrapperFocus(event: FocusEvent): void {
    if (event.target === this.wrapper) this.hasFocus = true;
  }

  @action
  onWrapperBlur(): void {
    this.hasFocus = false;
  }

  @action
  setHoverDisabled(value: boolean): void {
    if (!this.args.disabled) this.isHoverDisabled = value;
  }

  @action
  setFocusedStop(index: number): void {
    this.focusedStopIndex = index;
  }

  @action
  openStop(id: number): void {
    this.openedStopId = id;
  }

  @action
  closeStop(): void {
    this.openedStopId = null;
  }

  isRangeMin = (stop: number): boolean => this.args.min === undefined && stop === this.rangeMin;

  isRangeMax = (stop: number): boolean => this.args.max === undefined && stop === this.rangeMax;

  localMin = (index: number): number =>
    index === 0 ? this.globalMin : this.sortedStops[index - 1]!.stop + 1;

  localMax = (index: number): number =>
    index === this.sortedStops.length - 1 ? this.globalMax : this.sortedStops[index + 1]!.stop - 1;

  registerWrapper = modifier((element: HTMLElement, [colorStops]: [ColorStop[]]) => {
    schedule('afterRender', () => {
      this.wrapper = element;

      if (element.clientWidth !== this.trackWidth) this.trackWidth = element.clientWidth;

      // a stop was just added: focus it and open its popover
      if (this.focusStopOnUpdate !== null) {
        const index = this.sortedStops.map((el) => el.stop).indexOf(this.focusStopOnUpdate);

        this.focusStopOnUpdate = null;

        if (index > -1) {
          this.focusStop(index);
          this.openedStopId = this.sortedStops[index]!.id;
        }
      }
    });

    void colorStops;
  });

  <template>
    <div
      class={{this.classes}}
      data-test-subj="euiColorStops"
      tabindex={{if @disabled "-1" "0"}}
      {{this.registerWrapper @colorStops}}
      {{on "mousedown" (fn this.setHoverDisabled true)}}
      {{on "mouseup" (fn this.setHoverDisabled false)}}
      {{on "mouseleave" (fn this.setHoverDisabled false)}}
      {{on "keydown" this.onKeyDown}}
      {{on "focus" this.onWrapperFocus}}
      {{on "blur" this.onWrapperBlur}}
      ...attributes
    >
      <EuiScreenReaderOnly><p aria-live="polite">{{this.announcement}}</p></EuiScreenReaderOnly>
      <div class={{this.trackClasses}}>
        <div class={{this.highlightClasses.highlight}}>
          <div
            class={{this.highlightClasses.progress}}
            data-test-subj="euiRangeHighlightProgress"
            style={{cssStyle
              (hash background=this.gradient marginInlineStart="0%" width="100%")
            }}
          ></div>
        </div>
        {{! template-lint-disable no-invalid-interactive }}
        <div
          class={{this.addContainerClasses}}
          data-test-subj="euiColorStopsAdd"
          {{on "click" this.onAddClick}}
          {{on "mousemove" this.onAddHover}}
        >
          <div
            class={{this.addTargetClasses}}
            style={{cssStyle (hash left=(percent this.addTargetPosition))}}
          ></div>
        </div>
        {{#each this.sortedStops key="id" as |colorStop index|}}
          <EuiColorStopThumb
            @stop={{colorStop.stop}}
            @color={{colorStop.color}}
            @index={{index}}
            @count={{@colorStops.length}}
            @onChange={{fn this.onStopChange colorStop.id}}
            @onFocus={{fn this.setFocusedStop index}}
            @onRemove={{if
              (gt1 this.sortedStops.length)
              (fn this.onRemove colorStop.id)
            }}
            @globalMin={{this.globalMin}}
            @globalMax={{this.globalMax}}
            @localMin={{this.localMin index}}
            @localMax={{this.localMax index}}
            @min={{@min}}
            @max={{@max}}
            @isRangeMin={{this.isRangeMin colorStop.stop}}
            @isRangeMax={{this.isRangeMax colorStop.stop}}
            @trackWidth={{this.trackWidth}}
            @parent={{this.wrapper}}
            @mode={{@mode}}
            @showAlpha={{@showAlpha}}
            @swatches={{@swatches}}
            @disabled={{@disabled}}
            @readOnly={{@readOnly}}
            @isPopoverOpen={{isEqual colorStop.id this.openedStopId}}
            @openPopover={{fn this.openStop colorStop.id}}
            @closePopover={{this.closeStop}}
          />
        {{/each}}
      </div>
    </div>
  </template>
}

function gt1(n: number): boolean {
  return n > 1;
}

function isEqual(a: unknown, b: unknown): boolean {
  return a === b;
}

function percent(value: number): string {
  return `${value}%`;
}
