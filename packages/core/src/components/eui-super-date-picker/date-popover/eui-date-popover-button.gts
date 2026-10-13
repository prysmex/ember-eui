import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import set from 'ember-set-helper/helpers/set';
import { not } from 'ember-truth-helpers';

import { getEuiThemeContext } from '../../../utils/emotion/consume.ts';
import { buttonReset } from '../../../utils/eui/form-controls.ts';
import { euiDatePopoverButtonStyles } from '../../../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../../../utils/eui/styles.ts';
import EuiPopover from '../../eui-popover.gts';
import { useFormatTimeString } from '../utils/index.ts';
import { useI18nTimeOptions } from '../utils/time-options.ts';
import EuiDatePopoverContent from './eui-date-popover-content.gts';

import type EuiI18n from '../../../services/eui-i18n';
import type { EuiCss } from '../../../utils/eui/styles.ts';
import type { EuiDatePopoverContentSignature } from './eui-date-popover-content';
import type { EuiTimeZoneDisplayProps } from './eui-time-zone-display.gts';
import type { Moment } from 'moment';

interface EuiDatePopoverButtonArgs {
  /** Extra class(es). */
  className?: string;
  /** moment format of absolute dates. */
  dateFormat?: string;
  /** Disables it. */
  isDisabled?: boolean;
  /** Invalid styling. */
  isInvalid?: boolean;
  /** Whether the popover is open. */
  isOpen?: boolean;
  /** Highlights that it changed and needs applying. */
  needsUpdating?: boolean;
  /** moment locale. */
  locale?: EuiDatePopoverContentSignature['Args']['locale'];
  /** `'start'` or `'end'` of the range. */
  position?: 'start' | 'end';
  /** Rounds relative dates up (for the end of a range). */
  roundUp?: boolean;
  /** moment format of times. */
  timeFormat?: string;
  /** The date (date math or ISO date). */
  value: string;
  /** UTC offset in minutes. */
  utcOffset?: number;
  /** Compressed styling. */
  compressed?: boolean;
  /** Time units and tenses for the quick select. */
  timeOptions?: EuiDatePopoverContentSignature['Args']['timeOptions'];
  /** Called with the new value. */
  onChange: EuiDatePopoverContentSignature['Args']['onChange'];
  /** Earliest selectable day of the absolute tab's calendar. */
  minDate?: Moment;
  /** Latest selectable day of the absolute tab's calendar. */
  maxDate?: Moment;
  /** `false` keeps relative units as typed. Defaults to `true`. */
  canRoundRelativeUnits?: boolean;
  /** Shows the time zone in the absolute and relative tabs. */
  timeZoneDisplayProps?: EuiTimeZoneDisplayProps;
  /** Called when the button gets focus (upstream `buttonProps.onFocus`). */
  onFocus?: (event: FocusEvent) => void;
  /**
   * Extra styles for the popover root (upstream passes the super date
   * picker's range input styles this way).
   */
  css?: EuiCss;
}

/** @private The start or end date button of EuiSuperDatePicker. */
export interface EuiDatePopoverButtonSignature {
  Element: HTMLButtonElement;
  Args: EuiDatePopoverButtonArgs;
  Blocks: {
    button: [
      {
        classes: string;
        formattedValue: string;
        open: () => void;
        close: () => void;
      }
    ];
  };
}

export default class EuiDatePopoverButton extends Component<EuiDatePopoverButtonSignature> {
  @service declare euiI18n: EuiI18n;
  @tracked isOpen = false;

  get dateFormat() {
    //date with seconds and such
    return this.args.dateFormat ?? 'YYYY-MM-DDTHH:mm:ss.SSSZ';
  }

  get formattedValue() {
    const roundUp = this.args.roundUp ?? false;
    const locale = this.args.locale ?? 'en';

    return useFormatTimeString(
      this.args.value,
      this.dateFormat,
      roundUp,
      locale,
      this.euiI18n,
      this.args.canRoundRelativeUnits ?? true
    );
  }

  onFocus = (event: FocusEvent) => this.args.onFocus?.(event);

  get timeOptions() {
    return this.args.timeOptions || useI18nTimeOptions(this.euiI18n);
  }

  get anchorPosition() {
    return this.args.position === 'start' ? 'downLeft' : 'downRight';
  }

  get position() {
    return this.args.position ?? 'start';
  }

  get context() {
    return getEuiThemeContext(this);
  }

  @cached
  get styles() {
    return useEuiBorealisStyles(this.context, euiDatePopoverButtonStyles);
  }

  /** Upstream state classes plus the button styles. */
  @cached
  get classes() {
    const context = this.context;
    return [
      'euiDatePopoverButton',
      `euiDatePopoverButton--${this.position}`,
      this.args.compressed && 'euiDatePopoverButton--compressed',
      this.isOpen && 'euiDatePopoverButton-isSelected',
      this.args.isInvalid && 'euiDatePopoverButton-isInvalid',
      this.args.needsUpdating && 'euiDatePopoverButton-needsUpdating',
      this.args.isDisabled && 'euiDatePopoverButton-disabled',
      this.args.className,
      euiClass(
        context,
        buttonReset,
        {
          fontFamily: context.upstream.euiTheme.font.family
        },
        this.styles.euiDatePopoverButton
      )
    ]
      .filter(Boolean)
      .join(' ');
  }

  /** Popover root: the caller's styles, and a narrower "now" (upstream). */
  @cached
  get rootCss() {
    return [this.args.css, this.args.value === 'now' && this.styles.now];
  }

  /** Upstream's tooltip anchor fills the range cell; so does our anchor. */
  @cached
  get anchorClass() {
    return euiClass(this.context, this.styles.tooltipAnchor);
  }

  /** Upstream title: the date, or why it is invalid / needs updating. */
  get title() {
    const title = this.formattedValue;

    if (this.args.isInvalid) {
      return this.euiI18n.lookupToken(
        'euiDatePopoverButton.invalidTitle',
        'Invalid date: {title}',
        { title }
      );
    }

    if (this.args.needsUpdating) {
      return this.euiI18n.lookupToken(
        'euiDatePopoverButton.outdatedTitle',
        'Update needed: {title}',
        { title }
      );
    }

    return title;
  }

  <template>
    <EuiPopover
      @isOpen={{this.isOpen}}
      @closePopover={{set this "isOpen" false}}
      @anchorPosition={{this.anchorPosition}}
      @anchorClassName={{this.anchorClass}}
      @panelPaddingSize="none"
      @display="block"
      @rootCss={{this.rootCss}}
    >
      <:button>
        {{#if (has-block "button")}}
          {{yield
            (hash
              classes=this.classes
              formattedValue=this.formattedValue
              open=(set this "isOpen" true)
              close=(set this "isOpen" false)
            )
            to="button"
          }}
        {{else}}
          <button
            type="button"
            class={{this.classes}}
            title={{this.title}}
            disabled={{@isDisabled}}
            data-test-subj="superDatePicker{{this.position}}DatePopoverButton"
            ...attributes
            {{on "click" (set this "isOpen" (not this.isOpen))}}
            {{on "focus" this.onFocus}}
          >
            {{this.formattedValue}}
          </button>
        {{/if}}
      </:button>

      <:content>
        <EuiDatePopoverContent
          @position={{this.position}}
          @value={{@value}}
          @roundUp={{@roundUp}}
          @dateFormat={{this.dateFormat}}
          @timeFormat={{@timeFormat}}
          @locale={{@locale}}
          @utcOffset={{@utcOffset}}
          @timeOptions={{this.timeOptions}}
          @onChange={{@onChange}}
          @minDate={{@minDate}}
          @maxDate={{@maxDate}}
          @canRoundRelativeUnits={{@canRoundRelativeUnits}}
          @timeZoneDisplayProps={{@timeZoneDisplayProps}}
        />
      </:content>
    </EuiPopover>
  </template>
}
