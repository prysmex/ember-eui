import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import dateMath from '@elastic/datemath';
import { modifier } from 'ember-modifier';
import { eq, or } from 'ember-truth-helpers';

import { argOrDefaultDecorator } from '../helpers/arg-or-default.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  euiSuperDatePickerStyles,
  euiTextTruncate
} from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiDatePopoverButton from './eui-super-date-picker/date-popover/eui-date-popover-button.gts';
import EuiDatePickerRange from './eui-super-date-picker/eui-date-picker-range.gts';
import EuiQuickSelectPopover from './eui-super-date-picker/eui-quick-select-popover.gts';
import EuiSuperUpdateButton from './eui-super-date-picker/eui-super-update-button.gts';
import EuiTimeWindowButtons from './eui-super-date-picker/eui-time-window-buttons.gts';
import EuiAutoRefresh from './eui-auto-refresh.gts';
import EuiAutoRefreshButton from './eui-auto-refresh-button.gts';
import EuiFormControlButton from './eui-form-control-button.gts';
import EuiFormControlLayout from './eui-form-control-layout.gts';
import EuiToolTip from './eui-tool-tip.gts';
import { isRangeInvalid } from './eui-super-date-picker/utils/index.ts';
import {
  prettyDuration,
  showPrettyDuration
} from './eui-super-date-picker/utils/pretty-duration.ts';
import { useI18nTimeOptions } from './eui-super-date-picker/utils/time-options.ts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiTimeZoneDisplayProps } from './eui-super-date-picker/date-popover/eui-time-zone-display.gts';
import type {
  CustomQuickSelectRenderOptions,
  EuiQuickSelectButtonProps
} from './eui-super-date-picker/eui-quick-select-popover.gts';
import type { EuiSuperUpdateButtonProps } from './eui-super-date-picker/eui-super-update-button.gts';
import type { EuiTimeWindowButtonsConfig } from './eui-super-date-picker/eui-time-window-buttons.gts';
import type {
  ApplyRefreshInterval,
  ApplyTime,
  DurationRange,
  Milliseconds,
  QuickSelectPanel,
  RefreshUnitsOptions,
  ShortDate
} from './eui-super-date-picker/types/global';
import type { ComponentLike } from '@glint/template';
import type { LocaleSpecifier, Moment } from 'moment';

export type {
  ApplyRefreshInterval,
  ApplyTime,
  CustomQuickSelectRenderOptions,
  DurationRange,
  EuiQuickSelectButtonProps,
  EuiSuperUpdateButtonProps,
  EuiTimeWindowButtonsConfig,
  EuiTimeZoneDisplayProps,
  Milliseconds,
  QuickSelectPanel,
  RefreshUnitsOptions,
  ShortDate
};

/**
 * EuiSuperDatePicker picks a time range (absolute dates, relative like
 * "last 15 minutes", or "now") with a quick select popover and optional
 * auto refresh, as in Kibana. `@onTimeChange` receives date math strings.
 */
export interface EuiSuperDatePickerArgs {
  /**
   * Ranges listed as "Commonly used" in the quick select popover:
   * `[{ start: 'now/d', end: 'now/d', label: 'Today' }, …]`. Defaults to
   * EUI's list (Today, This week, Last 15 minutes, …).
   */
  commonlyUsedRanges?: DurationRange[];
  /**
   * Extra panels at the end of the quick select popover:
   * `[{ title: 'My panel', content: MyPanel }]`. `content` is a component,
   * rendered with `@applyTime`; call it with `{ start, end }` to apply a
   * range (as a quick selection) and close the popover.
   */
  customQuickSelectPanels?: QuickSelectPanel[];
  /**
   * moment format for absolute dates. Defaults to
   * `'MMM D, YYYY @ HH:mm:ss.SSS'`.
   */
  dateFormat?: string;
  /**
   * Set isAutoRefreshOnly to true to limit the component to only display
   * auto refresh content. Defaults to `false`.
   */
  isAutoRefreshOnly?: boolean;
  /**
   * Disables the picker. Defaults to `false`. Pass `{ display }` to also
   * replace the dates with your own content, e.g. `{ display: 'All time' }`
   * (a string or a component), in a disabled button.
   */
  isDisabled?: boolean | { display: string | ComponentLike };
  /**
   * Shows a commonly used or relative range ("Last 15 minutes") as one
   * summary button until it is clicked. Upstream always does this; in Ember
   * EUI it is opt-in. Defaults to `false`.
   */
  showPrettyDuration?: boolean;
  /** Shows the update button's loading state, e.g. while data refreshes. */
  isLoading?: boolean;
  /**
   * Whether auto refresh is paused (with `@onRefreshChange`).
   * Defaults to `true`.
   */
  isPaused?: boolean;
  /**
   * Sets the overall width by adding sensible min and max widths.
   * - `auto`: fits width to internal content / time string.
   * - `restricted`: static width that fits the longest possible time string
   *   (600px with the update button, 480px without).
   * - `full`: expands to 100% of the container.
   * Defaults to `'restricted'`. `@isQuickSelectOnly` forces `'auto'`.
   */
  width?: 'restricted' | 'full' | 'auto';
  /**
   * Reduces overall height to compressed form size
   */
  compressed?: boolean;
  /**
   * Used to localize e.g. month names, passed to `moment`. Defaults to
   * `'en'`, also for `null`.
   */
  locale?: LocaleSpecifier | null;
  /**
   * Called every `@refreshInterval` ms while not `@isPaused` (and by the
   * update button when the range has not changed), with `{ start, end,
   * refreshInterval }`. If it returns a promise, the next call waits for
   * it; if the promise rejects, refreshing stops.
   */
  onRefresh?: (props: {
    start: string;
    end: string;
    refreshInterval: number;
  }) => void | Promise<unknown>;
  /**
   * Adds the "Refresh every" section to the quick select popover; called
   * with `{ refreshInterval, isPaused }` when the user changes them.
   */
  onRefreshChange?: ApplyRefreshInterval;
  /**
   * Callback for when the time changes.
   */
  onTimeChange: (props: {
    start: string;
    end: string;
    isQuickSelection: boolean;
    isInvalid: boolean;
  }) => void;
  /**
   * Ranges listed as "Recently used" in the quick select popover (their
   * `label`, or "start → end").
   */
  recentlyUsedRanges?: DurationRange[];
  /**
   * Refresh interval in milliseconds. Defaults to `1000`.
   */
  refreshInterval?: Milliseconds;
  /**
   * Minimum refresh interval in milliseconds: the refresh interval fields
   * don't go below it. Defaults to `0`.
   */
  refreshMinInterval?: Milliseconds;
  /**
   * The refresh interval's unit (`'s'`, `'m'` or `'h'`). By default it is
   * rounded up to the largest unit that fits (90 seconds become 2 minutes).
   * To keep the user's unit, store the `intervalUnits` `@onRefreshChange`
   * receives and pass it back here.
   */
  refreshIntervalUnits?: RefreshUnitsOptions;
  /**
   * Start of the range, as date math (`'now-15m'`, `'now/d'`) or an ISO
   * date. Defaults to `'now-15m'`.
   */
  start?: ShortDate;
  /** End of the range, like `@start`. Defaults to `'now'`. */
  end?: ShortDate;
  /**
   * Earliest selectable date (a moment): earlier days are disabled in the
   * calendar and a start before it makes the range invalid.
   */
  minDate?: Moment;
  /**
   * Latest selectable date (a moment): later days are disabled in the
   * calendar and an end after it makes the range invalid.
   */
  maxDate?: Moment;
  /**
   * moment format for times in the date picker. Defaults to `'HH:mm'`.
   */
  timeFormat?: string;
  /** UTC offset in minutes for absolute dates, e.g. `-300`. */
  utcOffset?: number;
  /**
   * Set showUpdateButton to false to immediately invoke onTimeChange for
   * all start and end changes; `'iconOnly'` shows a compact button.
   * Defaults to `true`.
   */
  showUpdateButton?: boolean | 'iconOnly';
  /**
   * Hides the actual input reducing to just the quick select button.
   */
  isQuickSelectOnly?: boolean;
  /**
   * Arguments for the update button: `{ fill, color, size, iconType,
   * iconOnly, className, children, minWidth, showTooltip, toolTipProps,
   * responsive, 'data-test-subj' }` (`children` is a custom label;
   * `responsive` lists the screen sizes where it collapses to its icon,
   * `['xs', 's']` by default, or `false`). They win over the picker's own,
   * e.g. `{ fill: false }`.
   */
  updateButtonProps?: EuiSuperUpdateButtonProps;
  /**
   * Props for the quick select button, spread over its defaults:
   * `{ 'aria-label', 'data-test-subj', onClick, onMouseDown, label,
   * iconLeft, iconRight, className, … }`. `on*` functions become event
   * listeners (`onClick` runs after the popover toggles); other unknown
   * keys are set as attributes.
   */
  quickSelectButtonProps?: EuiQuickSelectButtonProps;
  /**
   * Shows a button group next to the control to shift the time window back
   * and forward and to zoom it out. `true`, or a configuration
   * `{ showZoomOut, showZoomIn, showShiftArrows, zoomFactor }` (zoom in is
   * off by default; `zoomFactor` defaults to `0.5`, also as `'50%'`).
   */
  showTimeWindowButtons?: boolean | EuiTimeWindowButtonsConfig;
  /**
   * Shows time zone information in the start/end popovers:
   * `{ timeZone: 'America/Los_Angeles' }` (any IANA name, `'Browser'` or
   * `'UTC'`), plus an optional reference `date` and a `customRender`
   * component (`@nameDisplay`, `@utcOffset`, `@timeZoneName`).
   * Informational only: dates are not converted.
   */
  timeZoneDisplayProps?: EuiTimeZoneDisplayProps;
  /**
   * By default relative values are rounded to the largest unit that fits
   * (90 minutes show as "~ 2 hours ago"). `false` keeps the user's units.
   * Defaults to `true`.
   */
  canRoundRelativeUnits?: boolean;
  /** Called when the start or end date button gets focus. */
  onFocus?: (event: FocusEvent) => void;
}

export interface EuiSuperDatePickerSignature {
  Element: HTMLDivElement;
  Args: EuiSuperDatePickerArgs;
  Blocks: {
    /**
     * Replaces the quick select popover's content (upstream
     * `customQuickSelectRender`). Yields the default panels as components
     * (`quickSelect`, `commonlyUsedRanges`, `recentlyUsedRanges`,
     * `refreshInterval`, `customQuickSelectPanels`) to re-order, omit or
     * mix with your own content.
     */
    customQuickSelectRender: [CustomQuickSelectRenderOptions];
  };
}

export default class EuiSuperDatePicker extends Component<EuiSuperDatePickerSignature> {
  @argOrDefaultDecorator('MMM D, YYYY @ HH:mm:ss.SSS') dateFormat!: string;
  @argOrDefaultDecorator('HH:mm') timeFormat!: string;
  // @argOrDefaultDecorator('now-15m') start!: ShortDate;
  // @argOrDefaultDecorator('now') end!: ShortDate;
  @argOrDefaultDecorator(false) isAutoRefreshOnly!: boolean;
  @argOrDefaultDecorator(true) isPaused!: boolean;
  @argOrDefaultDecorator(true) showUpdateButton!: boolean | 'iconOnly';
  @argOrDefaultDecorator('restricted') width!: string;
  // recentlyUsedRanges: [],
  @argOrDefaultDecorator(1000) refreshInterval!: Milliseconds;

  @service declare euiI18n: EuiI18n;

  /** Whether the start / end date popovers are open (upstream state). */
  @tracked isStartDatePopoverOpen = false;
  @tracked isEndDatePopoverOpen = false;

  /**
   * Upstream `showPrettyDuration` state, set for the @start/@end it was
   * set for (like the draft below): new arguments recompute it.
   */
  @tracked private prettyDurationOverride?: {
    show: boolean;
    forStart: ShortDate | undefined;
    forEnd: ShortDate | undefined;
  };

  /**
   * The range the user is editing, before it is applied with the update
   * button. It remembers the @start/@end it was based on: when the parent
   * passes a different range, the draft no longer applies and the picker
   * shows the new arguments (like EUI React's getDerivedStateFromProps).
   */
  @tracked private draft?: {
    start: ShortDate;
    end: ShortDate;
    hasChanged: boolean;
    forStart: ShortDate | undefined;
    forEnd: ShortDate | undefined;
  };

  private get currentDraft() {
    const { draft } = this;

    return draft &&
      draft.forStart === this.args.start &&
      draft.forEnd === this.args.end
      ? draft
      : undefined;
  }

  /** The applied range (upstream's props, not the draft). */
  get appliedStart(): ShortDate {
    return this.args.start ?? 'now-15m';
  }

  get appliedEnd(): ShortDate {
    return this.args.end ?? 'now';
  }

  get start(): ShortDate {
    return this.currentDraft?.start ?? this.args.start ?? 'now-15m';
  }

  get end(): ShortDate {
    return this.currentDraft?.end ?? this.args.end ?? 'now';
  }

  get isInvalid(): boolean {
    return isRangeInvalid(
      this.start,
      this.end,
      this.args.minDate,
      this.args.maxDate
    );
  }

  get hasChanged(): boolean {
    return this.currentDraft?.hasChanged ?? false;
  }

  get isDisabled(): boolean {
    return Boolean(this.args.isDisabled);
  }

  /** Upstream `isDisabled.display`. */
  get disabledDisplay(): string | ComponentLike | undefined {
    const { isDisabled } = this.args;
    return typeof isDisabled === 'object' && isDisabled !== null
      ? isDisabled.display || undefined
      : undefined;
  }

  get disabledDisplayText(): string | undefined {
    const display = this.disabledDisplay;
    return typeof display === 'string' ? display : undefined;
  }

  get commonlyUsedRanges(): DurationRange[] {
    return (
      this.args.commonlyUsedRanges ?? this.timeOptions.commonDurationRanges
    );
  }

  /**
   * Upstream: a commonly used range or a range relative to now ("Last 15
   * minutes") shows as one pretty duration button until it is clicked.
   */
  get showPrettyDurationState(): boolean {
    // Ember EUI: opt-in (upstream always shows it)
    if (!this.args.showPrettyDuration) return false;

    const override = this.prettyDurationOverride;

    if (
      override &&
      override.forStart === this.args.start &&
      override.forEnd === this.args.end
    ) {
      return override.show;
    }

    return showPrettyDuration(
      this.appliedStart,
      this.appliedEnd,
      this.commonlyUsedRanges
    );
  }

  private setPrettyDuration(show: boolean) {
    this.prettyDurationOverride = {
      show,
      forStart: this.args.start,
      forEnd: this.args.end
    };
  }

  /** The pretty duration (or `isDisabled.display`) button replaces the range. */
  get showPrettyDurationButton(): boolean {
    return Boolean(
      this.disabledDisplay ||
        (this.showPrettyDurationState &&
          !this.isStartDatePopoverOpen &&
          !this.isEndDatePopoverOpen)
    );
  }

  get prettyDurationText(): string {
    return prettyDuration(this.euiI18n, {
      timeFrom: this.start,
      timeTo: this.end,
      quickRanges: this.commonlyUsedRanges,
      dateFormat: this.dateFormat
    });
  }

  /** The pretty duration button's tooltip: the full range (upstream). */
  get formattedFullRange(): string {
    if (this.isInvalid) return '';

    const startMoment = dateMath.parse(this.start);
    const endMoment = dateMath.parse(this.end, { roundUp: true });

    return `${startMoment?.format(this.dateFormat)} – ${endMoment?.format(
      this.dateFormat
    )}`;
  }

  /** Upstream `offset={euiTheme.base * 0.5}`. */
  get prettyDurationTooltipOffset(): number {
    return this.context.upstream.euiTheme.base * 0.5;
  }

  @cached
  get prettyDurationTextClass(): string {
    return euiClass(this.context, euiTextTruncate());
  }

  /** Upstream `hidePrettyDuration`: show the range with the start popover open. */
  @action
  hidePrettyDuration() {
    this.setPrettyDuration(false);
    this.isStartDatePopoverOpen = true;
  }

  @action
  onPrettyDurationFocus(event: FocusEvent) {
    this.args.onFocus?.(event);
  }

  @action
  onStartDatePopoverToggle() {
    this.isStartDatePopoverOpen = !this.isStartDatePopoverOpen;
  }

  @action
  onStartDatePopoverClose() {
    this.isStartDatePopoverOpen = false;
  }

  @action
  onEndDatePopoverToggle() {
    this.isEndDatePopoverOpen = !this.isEndDatePopoverOpen;
  }

  @action
  onEndDatePopoverClose() {
    this.isEndDatePopoverOpen = false;
  }

  /** Upstream shows the auto refresh button in the field while refreshing. */
  get showAutoRefreshAppend(): boolean {
    return !this.isPaused;
  }

  /** Upstream: the `checkCircle` icon on the right while an update is pending. */
  get hasChangedIcon(): boolean {
    return this.hasChanged && !this.isInvalid;
  }

  /** Upstream spreads `updateButtonProps.showTooltip` over its own. */
  get updateButtonShowTooltip(): boolean {
    return (
      this.updateButtonProps.showTooltip ??
      (!this.isStartDatePopoverOpen && !this.isEndDatePopoverOpen)
    );
  }

  private setDraft(start: ShortDate, end: ShortDate, hasChanged: boolean) {
    this.draft = {
      start,
      end,
      hasChanged,
      forStart: this.args.start,
      forEnd: this.args.end
    };
  }

  get timeOptions() {
    return useI18nTimeOptions(this.euiI18n);
  }

  setTime({ start, end }: DurationRange) {
    this.setDraft(
      start,
      end,
      !(this.appliedStart === start && this.appliedEnd === end)
    );

    if (!this.showUpdateButton) {
      this.args.onTimeChange({
        start,
        end,
        isQuickSelection: false,
        isInvalid: isRangeInvalid(
          start,
          end,
          this.args.minDate,
          this.args.maxDate
        )
      });
    }
  }

  applyTime() {
    this.args.onTimeChange({
      start: this.start,
      end: this.end,
      isQuickSelection: false,
      isInvalid: false
    });
  }

  @action
  applyQuickTime({ start, end }: DurationRange) {
    this.setDraft(start, end, false);
    this.setPrettyDuration(
      showPrettyDuration(start, end, this.commonlyUsedRanges)
    );

    this.args.onTimeChange({
      start,
      end,
      isQuickSelection: true,
      isInvalid: false
    });
  }

  @action
  setStart(start: ShortDate) {
    this.setTime({ start, end: this.end });
  }

  @action
  setEnd(end: ShortDate) {
    this.setTime({ start: this.start, end });
  }

  @action
  handleClickUpdateButton() {
    if (!this.hasChanged && this.args.onRefresh) {
      void this.args.onRefresh({
        start: this.start,
        end: this.end,
        refreshInterval: this.refreshInterval
      });
    } else {
      this.applyTime();
    }

    if (this.currentDraft) {
      this.draft = { ...this.currentDraft, hasChanged: false };
    }
  }

  get context() {
    return getEuiThemeContext(this);
  }

  /** Upstream `renderTimeWindowButtons`: not with `@isAutoRefreshOnly`. */
  get timeWindowConfig(): EuiTimeWindowButtonsConfig | undefined {
    const { showTimeWindowButtons } = this.args;
    if (!showTimeWindowButtons || this.isAutoRefreshOnly) return undefined;
    return typeof showTimeWindowButtons === 'boolean'
      ? {}
      : showTimeWindowButtons;
  }

  /** Upstream renders `EuiAutoRefresh` instead of the range. */
  get showAutoRefreshOnly() {
    return Boolean(this.isAutoRefreshOnly && this.args.onRefreshChange);
  }

  /** Upstream spreads `updateButtonProps` last over its own props. */
  get updateButtonProps(): EuiSuperUpdateButtonProps {
    return this.args.updateButtonProps ?? {};
  }

  get updateButtonIconOnly() {
    return (
      this.updateButtonProps.iconOnly ?? this.showUpdateButton === 'iconOnly'
    );
  }

  get updateButtonSize() {
    return this.updateButtonProps.size ?? (this.args.compressed ? 's' : 'm');
  }

  get updateButtonTestSubj() {
    return (
      this.updateButtonProps['data-test-subj'] ??
      'superDatePickerApplyTimeButton'
    );
  }

  /** EuiAutoRefresh reports the picked units too (upstream). */
  onAutoRefreshChange = (change: {
    refreshInterval: number;
    isPaused: boolean;
    intervalUnits: RefreshUnitsOptions;
  }) => {
    const { refreshInterval, isPaused, intervalUnits } = change;
    this.args.onRefreshChange?.({ refreshInterval, isPaused, intervalUnits });
  };

  /** Upstream forces `auto` width when only the quick select shows. */
  get resolvedWidth(): 'restricted' | 'full' | 'auto' {
    if (this.args.isQuickSelectOnly) return 'auto';
    const width = this.width;
    return width === 'full' || width === 'auto' ? width : 'restricted';
  }

  @cached
  get styles() {
    return useEuiBorealisStyles(this.context, euiSuperDatePickerStyles);
  }

  /** Root: flex row with the gap, the width and the special cases. */
  @cached
  get classes() {
    const styles = this.styles;
    const width = this.resolvedWidth;
    const needsUpdating =
      this.hasChanged && !this.isDisabled && !this.isInvalid;
    return [
      'euiSuperDatePicker',
      needsUpdating && 'euiSuperDatePicker--needsUpdating',
      euiClass(
        this.context,
        { boxSizing: 'border-box' },
        styles.euiSuperDatePicker,
        styles.widths[width],
        !this.showUpdateButton && styles.noUpdateButton[width],
        this.isAutoRefreshOnly && styles.isAutoRefreshOnly[width],
        this.args.isQuickSelectOnly && styles.isQuickSelectOnly
      )
    ]
      .filter(Boolean)
      .join(' ');
  }

  /**
   * The range wrapper: grows, and carries the form state (disabled, then
   * invalid, then needs updating, else default) for the layout inside.
   */
  @cached
  get layoutCss() {
    const { states } = this.styles;
    const state = this.isDisabled
      ? states.disabled
      : this.isInvalid
        ? states.invalid
        : this.hasChanged
          ? states.needsUpdating
          : states.default;
    return [states.euiSuperDatePicker__formControlLayout, state];
  }

  @cached
  get rangeCss() {
    return [this.styles.euiSuperDatePicker__range, ...this.layoutCss];
  }

  get prettyDurationTooltipCss() {
    return this.styles.euiSuperDatePicker__prettyDurationTooltip;
  }

  /** Start/end popovers grow to share the range (upstream `rangeInput`). */
  get rangeInputCss() {
    return this.styles.euiSuperDatePicker__rangeInput;
  }

  /** Upstream shows the layout spinner only without the update button. */
  get isLayoutLoading() {
    return Boolean(this.args.isLoading && !this.showUpdateButton);
  }

  /**
   * Calls `@onRefresh` every `@refreshInterval` ms while not `@isPaused`.
   * A returned promise delays the next call until it settles; a rejected
   * one stops the refreshing.
   */
  autoRefresh = modifier(
    (
      _element: Element,
      [onRefresh, isPaused, refreshInterval]: [
        EuiSuperDatePickerArgs['onRefresh'],
        boolean,
        number
      ]
    ) => {
      if (!onRefresh || isPaused || !(refreshInterval > 0)) return;

      let stopped = false;
      let timer: ReturnType<typeof setTimeout>;

      const tick = async () => {
        try {
          await onRefresh({ start: this.start, end: this.end, refreshInterval });
        } catch {
          stopped = true;
        }

        if (!stopped) timer = setTimeout(() => void tick(), refreshInterval);
      };

      timer = setTimeout(() => void tick(), refreshInterval);

      return () => {
        stopped = true;
        clearTimeout(timer);
      };
    }
  );

  <template>
    <div
      class={{this.classes}}
      {{this.autoRefresh @onRefresh this.isPaused this.refreshInterval}}
      ...attributes
    >
      {{#if this.showAutoRefreshOnly}}
        <EuiAutoRefresh
          @isPaused={{this.isPaused}}
          @refreshInterval={{this.refreshInterval}}
          @minInterval={{@refreshMinInterval}}
          @intervalUnits={{@refreshIntervalUnits}}
          @onRefreshChange={{this.onAutoRefreshChange}}
          @fullWidth={{eq this.resolvedWidth "full"}}
          @compressed={{@compressed}}
          @isDisabled={{this.isDisabled}}
        />
      {{else}}
        {{#let
          (component
            EuiQuickSelectPopover
            start=this.start
            end=this.end
            applyTime=this.applyQuickTime
            timeOptions=this.timeOptions
            isDisabled=this.isDisabled
            compressed=@compressed
            commonlyUsedRanges=this.commonlyUsedRanges
            recentlyUsedRanges=@recentlyUsedRanges
            dateFormat=this.dateFormat
            onRefreshChange=@onRefreshChange
            isPaused=this.isPaused
            refreshInterval=this.refreshInterval
            refreshMinInterval=@refreshMinInterval
            intervalUnits=@refreshIntervalUnits
            customQuickSelectPanels=@customQuickSelectPanels
            hasCustomQuickSelectRender=(has-block "customQuickSelectRender")
            buttonProps=@quickSelectButtonProps
          )
          (component
            EuiAutoRefreshButton
            refreshInterval=this.refreshInterval
            minInterval=@refreshMinInterval
            intervalUnits=@refreshIntervalUnits
            isDisabled=this.isDisabled
            isPaused=this.isPaused
            onRefreshChange=this.onAutoRefreshChange
            shortHand=true
          )
          as |QuickSelect AutoRefreshButton|
        }}
          {{#if this.showPrettyDurationButton}}
            <EuiFormControlLayout
              @compressed={{@compressed}}
              @isInvalid={{this.isInvalid}}
              @isLoading={{this.isLayoutLoading}}
              @isDisabled={{this.isDisabled}}
              @fullWidth={{true}}
              @css={{this.layoutCss}}
              @isAppendProvided={{this.showAutoRefreshAppend}}
            >
              <:prepend>
                <QuickSelect>
                  <:customQuickSelectRender as |panels|>
                    {{yield panels to="customQuickSelectRender"}}
                  </:customQuickSelectRender>
                </QuickSelect>
              </:prepend>
              <:field>
                {{#unless @isQuickSelectOnly}}
                  <EuiToolTip
                    @css={{this.prettyDurationTooltipCss}}
                    @content={{this.formattedFullRange}}
                    @display="block"
                    @offset={{this.prettyDurationTooltipOffset}}
                  >
                    <EuiFormControlButton
                      class="euiSuperDatePicker__prettyFormat
                        {{if
                          this.isDisabled
                          'euiSuperDatePicker__prettyFormat--disabled'
                        }}"
                      @compressed={{@compressed}}
                      @isDisabled={{this.isDisabled}}
                      data-test-subj="superDatePickerShowDatesButton"
                      {{on "click" this.hidePrettyDuration}}
                      {{on "focus" this.onPrettyDurationFocus}}
                    >
                      {{#if this.disabledDisplay}}
                        {{#if this.disabledDisplayText}}
                          {{this.disabledDisplayText}}
                        {{else}}
                          {{#let this.disabledDisplay as |Display|}}
                            {{! @glint-expect-error: a string is handled above }}
                            <Display />
                          {{/let}}
                        {{/if}}
                      {{else}}
                        <span
                          class={{this.prettyDurationTextClass}}
                        >{{this.prettyDurationText}}</span>
                      {{/if}}
                    </EuiFormControlButton>
                  </EuiToolTip>
                {{/unless}}
              </:field>
              <:append>
                <AutoRefreshButton />
              </:append>
            </EuiFormControlLayout>
          {{else}}
            <EuiDatePickerRange
              @css={{this.rangeCss}}
              @fullWidth={{true}}
              @compressed={{@compressed}}
              @isInvalid={{this.isInvalid}}
              @isLoading={{this.isLayoutLoading}}
              @disabled={{this.isDisabled}}
              @delimiter={{if @isQuickSelectOnly ""}}
              @icon={{if this.hasChangedIcon "checkCircle"}}
              @iconSide={{if this.hasChangedIcon "right"}}
              @isAppendProvided={{this.showAutoRefreshAppend}}
            >
              <:prepend>
                <QuickSelect>
                  <:customQuickSelectRender as |panels|>
                    {{yield panels to="customQuickSelectRender"}}
                  </:customQuickSelectRender>
                </QuickSelect>
              </:prepend>

              <:startDateControl>
                {{#unless @isQuickSelectOnly}}
                  <EuiDatePopoverButton
                    @className="euiSuperDatePicker__startPopoverButton"
                    @css={{this.rangeInputCss}}
                    @value={{this.start}}
                    @compressed={{@compressed}}
                    @position="start"
                    @isDisabled={{this.isDisabled}}
                    @dateFormat={{this.dateFormat}}
                    @timeFormat={{this.timeFormat}}
                    @utcOffset={{@utcOffset}}
                    @onChange={{this.setStart}}
                    @isInvalid={{this.isInvalid}}
                    @timeOptions={{this.timeOptions}}
                    @needsUpdating={{this.hasChanged}}
                    @locale={{@locale}}
                    @minDate={{@minDate}}
                    @maxDate={{@maxDate}}
                    @canRoundRelativeUnits={{@canRoundRelativeUnits}}
                    @timeZoneDisplayProps={{@timeZoneDisplayProps}}
                    @onFocus={{@onFocus}}
                    @isOpen={{this.isStartDatePopoverOpen}}
                    @onPopoverToggle={{this.onStartDatePopoverToggle}}
                    @onPopoverClose={{this.onStartDatePopoverClose}}
                  />
                {{/unless}}
              </:startDateControl>

              <:endDateControl>
                {{#unless @isQuickSelectOnly}}
                  <EuiDatePopoverButton
                    @className="euiSuperDatePicker__endPopoverButton"
                    @css={{this.rangeInputCss}}
                    @value={{this.end}}
                    @compressed={{@compressed}}
                    @position="end"
                    @isDisabled={{this.isDisabled}}
                    @dateFormat={{this.dateFormat}}
                    @timeFormat={{this.timeFormat}}
                    @utcOffset={{@utcOffset}}
                    @onChange={{this.setEnd}}
                    @isInvalid={{this.isInvalid}}
                    @timeOptions={{this.timeOptions}}
                    @roundUp={{true}}
                    @needsUpdating={{this.hasChanged}}
                    @locale={{@locale}}
                    @minDate={{@minDate}}
                    @maxDate={{@maxDate}}
                    @canRoundRelativeUnits={{@canRoundRelativeUnits}}
                    @timeZoneDisplayProps={{@timeZoneDisplayProps}}
                    @onFocus={{@onFocus}}
                    @isOpen={{this.isEndDatePopoverOpen}}
                    @onPopoverToggle={{this.onEndDatePopoverToggle}}
                    @onPopoverClose={{this.onEndDatePopoverClose}}
                  />
                {{/unless}}
              </:endDateControl>

              <:append>
                <AutoRefreshButton />
              </:append>
            </EuiDatePickerRange>
          {{/if}}
        {{/let}}

        {{#if this.timeWindowConfig}}
          <EuiTimeWindowButtons
            @applyTime={{this.applyQuickTime}}
            @start={{this.appliedStart}}
            @end={{this.appliedEnd}}
            @compressed={{@compressed}}
            @isDisabled={{or this.isDisabled this.isInvalid}}
            @showZoomOut={{this.timeWindowConfig.showZoomOut}}
            @showZoomIn={{this.timeWindowConfig.showZoomIn}}
            @showShiftArrows={{this.timeWindowConfig.showShiftArrows}}
            @zoomFactor={{this.timeWindowConfig.zoomFactor}}
          />
        {{/if}}

        {{#if this.showUpdateButton}}
          <EuiSuperUpdateButton
            @size={{this.updateButtonSize}}
            @onClick={{this.handleClickUpdateButton}}
            @isLoading={{@isLoading}}
            @isDisabled={{or this.isDisabled this.isInvalid}}
            @needsUpdate={{this.hasChanged}}
            @showTooltip={{this.updateButtonShowTooltip}}
            @fill={{this.updateButtonProps.fill}}
            @iconOnly={{this.updateButtonIconOnly}}
            @color={{this.updateButtonProps.color}}
            @iconType={{this.updateButtonProps.iconType}}
            @label={{this.updateButtonProps.children}}
            @minWidth={{this.updateButtonProps.minWidth}}
            @className={{this.updateButtonProps.className}}
            @toolTipProps={{this.updateButtonProps.toolTipProps}}
            @responsive={{this.updateButtonProps.responsive}}
            @element={{this.updateButtonProps.element}}
            @fullWidth={{this.updateButtonProps.fullWidth}}
            @hasAriaDisabled={{this.updateButtonProps.hasAriaDisabled}}
            @iconSide={{this.updateButtonProps.iconSide}}
            @iconSize={{this.updateButtonProps.iconSize}}
            @isSelected={{this.updateButtonProps.isSelected}}
            data-test-subj={{this.updateButtonTestSubj}}
          />
        {{/if}}
      {{/if}}
    </div>
  </template>
}
