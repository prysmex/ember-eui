import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

import set from 'ember-set-helper/helpers/set';
import { gt, not } from 'ember-truth-helpers';

import EuiButtonEmpty from '../eui-button-empty.gts';
import EuiHorizontalRule from '../eui-horizontal-rule.gts';
import EuiIcon from '../eui-icon.gts';
import EuiPopover from '../eui-popover.gts';
import EuiRecentlyUsed from '../eui-super-date-picker/eui-quick-select-popover/eui-recently-used.gts';
import EuiCommonlyUsedTimeRanges from './eui-quick-select-popover/eui-commonly-used-time-ranges.gts';
import EuiQuickSelect from './eui-quick-select-popover/eui-quick-select.gts';

import type { EuiRecentlyUsedSignature } from '../eui-super-date-picker/eui-quick-select-popover/eui-recently-used.gts';
import type { EuiCommonlyUsedTimeRangesSignature } from './eui-quick-select-popover/eui-commonly-used-time-ranges.gts';
import type { EuiQuickSelectSignature } from './eui-quick-select-popover/eui-quick-select.gts';
import type { ApplyTime } from './types/global';

export interface EuiQuickSelectPopoverSignature {
  Args: {
    applyTime: ApplyTime;
    isDisabled?: boolean;
    commonlyUsedRanges: EuiCommonlyUsedTimeRangesSignature['Args']['commonlyUsedRanges'];
    recentlyUsedRanges?: EuiRecentlyUsedSignature['Args']['recentlyUsedRanges'];
    start: string;
    end: string;
    timeOptions: EuiQuickSelectSignature['Args']['timeOptions'];
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
          <EuiQuickSelect
            @applyTime={{this.applyTime}}
            @start={{@start}}
            @end={{@end}}
            @timeOptions={{@timeOptions}}
          />

          {{#if (gt @commonlyUsedRanges.length 0)}}
            <EuiHorizontalRule @margin="s" />
            <EuiCommonlyUsedTimeRanges
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
