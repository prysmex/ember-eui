import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { useFormatTimeString } from '../utils';
import type { LocaleSpecifier } from 'moment';
import { inject as service } from '@ember/service';
import type EuiI18n from '../../../services/eui-i18n';
import EuiDatePopoverContent from './eui-date-popover-content.gts';
import type { EuiDatePopoverContentSignature } from './eui-date-popover-content.gts';
import EuiPopover from '../../eui-popover.gts';
import classNames from '../../../helpers/class-names';
import { concat } from '@ember/helper';
import { on } from '@ember/modifier';
import set from 'ember-set-helper/helpers/set';
import { not } from 'ember-truth-helpers';

interface EuiDatePopoverButtonArgs {
  className?: string;
  dateFormat: string;
  isDisabled?: boolean;
  isInvalid?: boolean;
  isOpen: boolean;
  needsUpdating?: boolean;
  locale?: EuiDatePopoverContentSignature['Args']['locale'];
  position: 'start' | 'end';
  roundUp?: boolean;
  timeFormat: string;
  value: string;
  utcOffset?: number;
  compressed?: boolean;
  timeOptions: EuiDatePopoverContentSignature['Args']['timeOptions'];
  onChange: EuiDatePopoverContentSignature['Args']['onChange'];
}

export interface EuiDatePopoverButtonSignature {
  Element: HTMLButtonElement;
  Args: EuiDatePopoverButtonArgs;
}

export default class EuiDatePopoverButton extends Component<EuiDatePopoverButtonSignature> {
  @service declare euiI18n: EuiI18n;
  @tracked isOpen = false;

  get formattedValue() {
    const roundUp = this.args.roundUp ?? false;
    const locale = this.args.locale ?? 'en';

    return useFormatTimeString(
      this.args.value,
      this.args.dateFormat,
      roundUp,
      locale,
      this.euiI18n
    );
  }

  get anchorPosition() {
    return this.args.position === 'start' ? 'downLeft' : 'downRight';
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
        </:button>

        <:content>
          <EuiDatePopoverContent
            @position={{@position}}
            @value={{@value}}
            @roundUp={{@roundUp}}
            @dateFormat={{@dateFormat}}
            @timeFormat={{@timeFormat}}
            @locale={{@locale}}
            @utcOffset={{@utcOffset}}
            @timeOptions={{@timeOptions}}
            @onChange={{@onChange}}
          />
        </:content>
      </EuiPopover>
    {{/let}}
  </template>
}
