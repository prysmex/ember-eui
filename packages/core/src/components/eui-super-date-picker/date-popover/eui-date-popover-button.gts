import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { concat, hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import set from 'ember-set-helper/helpers/set';
import { not } from 'ember-truth-helpers';

import classNames from '../../../helpers/class-names.ts';
import EuiPopover from '../../eui-popover.gts';
import { useFormatTimeString } from '../utils/index.ts';
import { useI18nTimeOptions } from '../utils/time-options.ts';
import EuiDatePopoverContent from './eui-date-popover-content.gts';

import type EuiI18n from '../../../services/eui-i18n';
import type { EuiDatePopoverContentSignature } from './eui-date-popover-content';

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
      this.euiI18n
    );
  }

  get timeOptions() {
    return this.args.timeOptions || useI18nTimeOptions(this.euiI18n);
  }

  get anchorPosition() {
    return this.args.position === 'start' ? 'downLeft' : 'downRight';
  }

  get position() {
    return this.args.position ?? 'start';
  }

  <template>
    {{#let
      (classNames
        "euiDatePopoverButton"
        (concat "euiDatePopoverButton--" @position)
        (if @compressed "euiDatePopoverButton--compressed")
        (if this.isOpen "euiDatePopoverButton-isSelected")
        (if @isInvalid "euiDatePopoverButton-isInvalid")
        (if @needsUpdating "euiDatePopoverButton-needsUpdating")
        (if @isDisabled "euiDatePopoverButton-disabled")
      )
      as |classes|
    }}
      <EuiPopover
        @isOpen={{this.isOpen}}
        @closePopover={{set this "isOpen" false}}
        @anchorPosition={{this.anchorPosition}}
        @panelPaddingSize="none"
        @display="block"
      >
        <:button>
          {{#if (has-block "button")}}
            {{yield
              (hash
                classes=classes
                formattedValue=this.formattedValue
                open=(set this "isOpen" true)
                close=(set this "isOpen" false)
              )
              to="button"
            }}
          {{else}}
            <button
              type="button"
              class={{classes}}
              title={{this.formattedValue}}
              disabled={{@isDisabled}}
              ...attributes
              {{on "click" (set this "isOpen" (not this.isOpen))}}
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
          />
        </:content>
      </EuiPopover>
    {{/let}}
  </template>
}
