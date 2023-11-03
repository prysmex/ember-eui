import { action } from '@ember/object';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import set from 'ember-set-helper/helpers/set';
import EuiPopover from '../eui-popover.gts';
import EuiButtonEmpty from '../eui-button-empty.gts';
import EuiHorizontalRule from '../eui-horizontal-rule.gts';
import EuiIcon from '../eui-icon.gts';
import EuiRecentlyUsed from '../eui-super-date-picker/eui-quick-select-popover/eui-recently-used.gts';
import type { ApplyTime } from './types/global';
import { on } from '@ember/modifier';
import { gt, not } from 'ember-truth-helpers';
import type { DurationRange } from './types/global';

export interface EuiQuickSelectPopoverSignature {
  Args: {
    applyTime: ApplyTime;
    isDisabled?: boolean;
    commonlyUsedRanges?: DurationRange[];
    recentlyUsedRanges?: DurationRange[];
  };
}

export default class EuiQuickSelectPopover extends Component<EuiQuickSelectPopoverSignature> {
  @tracked isOpen = false;

  @action
  applyTime({
    start,
    end,
    keepPopoverOpen = false
  }: {
    start: string;
    end: string;
    quickSelect?: { timeTense: string; timeValue: number; timeUnits: string };
    keepPopoverOpen?: boolean;
  }) {
    this.args.applyTime({
      start,
      end
    });

    if (!keepPopoverOpen) {
      this.isOpen = false;
    }
  }

  <template>
    <EuiPopover
      @isOpen={{this.isOpen}}
      @closePopover={{set this "isOpen" false}}
      @anchorPosition="downLeft"
      @anchorClassName="euiQuickSelectPopover__anchor"
    >
      <:button>
        <EuiButtonEmpty
          class="euiFormControlLayout__prepend"
          @textClasses="euiQuickSelectPopover__buttonText"
          @size="xs"
          @iconType="arrowDown"
          @iconSide="right"
          @isDisabled={{@isDisabled}}
          {{on "click" (set this "isOpen" (not this.isOpen))}}
        >
          <EuiIcon @type="calendar" />
        </EuiButtonEmpty>
      </:button>

      <:content>
        <div class="euiQuickSelectPopover__content">
          <EuiSuperDatePicker::EuiQuickSelectPopover::EuiQuickSelect
            @applyTime={{this.applyTime}}
            @start={{@start}}
            @end={{@end}}
            @timeOptions={{@timeOptions}}
          />

          {{#if (gt @commonlyUsedRanges.length 0)}}
            <EuiHorizontalRule @margin="s" />
            <EuiSuperDatePicker::EuiQuickSelectPopover::EuiCommonlyUsedTimeRanges
              @applyTime={{this.applyTime}}
              @commonlyUsedRanges={{@commonlyUsedRanges}}
            />
          {{/if}}

          {{#if (gt @recentlyUsedRanges.length 0)}}
            <EuiHorizontalRule @margin="s" />
            <EuiRecentlyUsed
              @applyTime={{this.applyTime}}
              @recentlyUsedRanges={{@recentlyUsedRanges}}
            />
          {{/if}}

        </div>
      </:content>
    </EuiPopover>
  </template>
}
