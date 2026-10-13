import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import { or } from 'ember-truth-helpers';

import { randomId } from '../../-private/random-id.ts';
import EuiButtonGroup from '../eui-button-group.gts';
import EuiToolTip from '../eui-tool-tip.gts';
import { useEuiTimeWindow } from './utils/time-window.ts';

import type EuiI18n from '../../services/eui-i18n';
import type { ApplyTime, ShortDate } from './types/global';
import type { EuiTimeWindowButtonsConfig } from './utils/time-window.ts';

export type { EuiTimeWindowButtonsConfig };

/**
 * @private EuiSuperDatePicker's time window controls (upstream
 * `EuiTimeWindowButtons`): a segmented group to shift the window back and
 * forward by its own duration, and to zoom it out (or in).
 */
export interface EuiTimeWindowButtonsSignature {
  Args: EuiTimeWindowButtonsConfig & {
    /** Applies a new `{ start, end }` range. */
    applyTime: ApplyTime;
    /** Start of the range. */
    start: ShortDate;
    /** End of the range. */
    end: ShortDate;
    /** Small (`s`) buttons. */
    compressed?: boolean;
    /** Disables every button and drops the tooltips. */
    isDisabled?: boolean;
  };
}

export default class EuiTimeWindowButtons extends Component<EuiTimeWindowButtonsSignature> {
  @service declare euiI18n: EuiI18n;

  previousId = `previous_${randomId()}`;
  zoomInId = `zoom_in_${randomId()}`;
  zoomOutId = `zoom_out_${randomId()}`;
  nextId = `next_${randomId()}`;

  get showZoomOut() {
    return this.args.showZoomOut ?? true;
  }

  get showZoomIn() {
    return this.args.showZoomIn ?? false;
  }

  get showShiftArrows() {
    return this.args.showShiftArrows ?? true;
  }

  get isVisible() {
    return this.showZoomIn || this.showZoomOut || this.showShiftArrows;
  }

  get buttonSize() {
    return this.args.compressed ? 's' : 'm';
  }

  get timeWindow() {
    return useEuiTimeWindow(
      this.euiI18n,
      this.args.start,
      this.args.end,
      this.args.applyTime,
      { zoomFactor: this.args.zoomFactor }
    );
  }

  t = (token: string, fallback: string, values?: Record<string, unknown>) =>
    this.euiI18n.lookupToken(`euiTimeWindowButtons.${token}`, fallback, values);

  get groupLabel() {
    return this.t('label', 'Time window controls');
  }

  get previousLabel() {
    return this.t('previousLabel', 'Previous');
  }

  get nextLabel() {
    return this.t('nextLabel', 'Next');
  }

  get zoomInLabel() {
    return this.t('zoomInLabel', 'Zoom in');
  }

  get zoomOutLabel() {
    return this.t('zoomOutLabel', 'Zoom out');
  }

  /** Tooltips: none while disabled (upstream `content={!isDisabled && …}`). */
  get previousTooltip() {
    if (this.args.isDisabled) return undefined;
    const { isInvalid, displayInterval } = this.timeWindow;
    return isInvalid
      ? this.t('invalidShiftLabel', 'Cannot shift invalid time window')
      : this.t('previousDescription', 'Previous {displayInterval}', {
          displayInterval
        });
  }

  get nextTooltip() {
    if (this.args.isDisabled) return undefined;
    const { isInvalid, displayInterval } = this.timeWindow;
    return isInvalid
      ? this.t('invalidShiftLabel', 'Cannot shift invalid time window')
      : this.t('nextDescription', 'Next {displayInterval}', {
          displayInterval
        });
  }

  get zoomInTooltip() {
    if (this.args.isDisabled) return undefined;
    const { isInvalid, isWindowDurationZero } = this.timeWindow;
    return isInvalid
      ? this.t('invalidZoomInLabel', 'Cannot zoom in invalid time window')
      : isWindowDurationZero
        ? this.t('cannotZoomInLabel', 'Cannot zoom in any further')
        : this.zoomInLabel;
  }

  get zoomOutTooltip() {
    if (this.args.isDisabled) return undefined;
    return this.timeWindow.isInvalid
      ? this.t('invalidZoomOutLabel', 'Cannot zoom out invalid time window')
      : this.zoomOutLabel;
  }

  get zoomInTooltipIsLabel() {
    return this.zoomInTooltip === this.zoomInLabel;
  }

  get zoomOutTooltipIsLabel() {
    return this.zoomOutTooltip === this.zoomOutLabel;
  }

  stepBackward = () => this.timeWindow.stepBackward();
  stepForward = () => this.timeWindow.stepForward();
  expandWindow = () => this.timeWindow.expandWindow();
  shrinkWindow = () => this.timeWindow.shrinkWindow();

  <template>
    {{#if this.isVisible}}
      <EuiButtonGroup
        @legend={{this.groupLabel}}
        @variant="segmented"
        @buttonSize={{this.buttonSize}}
        @showDividers={{true}}
        @wrap={{false}}
        @className="euiSuperDatePicker__timeWindowButtons"
        data-test-subj="timeWindowButtons"
        as |group|
      >
        {{#if this.showShiftArrows}}
          <EuiToolTip @content={{this.previousTooltip}}>
            <group.ButtonIcon
              id={{this.previousId}}
              @iconType="chevronSingleLeft"
              @iconSize="m"
              @isDisabled={{or this.timeWindow.isWindowDurationZero @isDisabled}}
              {{on "click" this.stepBackward}}
              aria-label={{this.previousLabel}}
              data-test-subj="timeWindowButtonsPrevious"
            />
          </EuiToolTip>
        {{/if}}
        {{#if this.showZoomIn}}
          <EuiToolTip
            @content={{this.zoomInTooltip}}
            @disableScreenReaderOutput={{this.zoomInTooltipIsLabel}}
          >
            <group.ButtonIcon
              id={{this.zoomInId}}
              @iconType="magnifyPlus"
              @iconSize="m"
              @isDisabled={{or this.timeWindow.isWindowDurationZero @isDisabled}}
              {{on "click" this.shrinkWindow}}
              aria-label={{this.zoomInLabel}}
              data-test-subj="timeWindowButtonsZoomIn"
            />
          </EuiToolTip>
        {{/if}}
        {{#if this.showZoomOut}}
          <EuiToolTip
            @content={{this.zoomOutTooltip}}
            @disableScreenReaderOutput={{this.zoomOutTooltipIsLabel}}
          >
            <group.ButtonIcon
              id={{this.zoomOutId}}
              @iconType="magnifyMinus"
              @iconSize="m"
              @isDisabled={{@isDisabled}}
              {{on "click" this.expandWindow}}
              aria-label={{this.zoomOutLabel}}
              data-test-subj="timeWindowButtonsZoomOut"
            />
          </EuiToolTip>
        {{/if}}
        {{#if this.showShiftArrows}}
          <EuiToolTip @content={{this.nextTooltip}}>
            <group.ButtonIcon
              id={{this.nextId}}
              @iconType="chevronSingleRight"
              @iconSize="m"
              @isDisabled={{or this.timeWindow.isWindowDurationZero @isDisabled}}
              {{on "click" this.stepForward}}
              aria-label={{this.nextLabel}}
              data-test-subj="timeWindowButtonsNext"
            />
          </EuiToolTip>
        {{/if}}
      </EuiButtonGroup>
    {{/if}}
  </template>
}
