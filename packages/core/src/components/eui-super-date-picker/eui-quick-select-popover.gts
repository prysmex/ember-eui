import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { action } from '@ember/object';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiQuickSelectPopoverStyles } from '../../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import EuiFormPrepend from '../eui-form-prepend.gts';
import EuiPopover from '../eui-popover.gts';
import EuiRefreshInterval from '../eui-refresh-interval.gts';
import EuiToolTip from '../eui-tool-tip.gts';
import { or } from 'ember-truth-helpers';
import EuiQuickSelectPanel from './eui-quick-select-popover/eui-quick-select-panel.gts';
import EuiCommonlyUsedTimeRanges from './eui-quick-select-popover/eui-commonly-used-time-ranges.gts';
import EuiQuickSelect from './eui-quick-select-popover/eui-quick-select.gts';
import EuiRecentlyUsed from './eui-quick-select-popover/eui-recently-used.gts';
import { useI18nTimeOptions } from './utils/time-options.ts';

import type EuiI18n from '../../services/eui-i18n';
import type { EuiCommonlyUsedTimeRangesSignature } from './eui-quick-select-popover/eui-commonly-used-time-ranges';
import type { EuiQuickSelectSignature } from './eui-quick-select-popover/eui-quick-select';
import type { EuiRecentlyUsedSignature } from './eui-quick-select-popover/eui-recently-used';
import type {
  ApplyRefreshInterval,
  ApplyTime,
  Milliseconds,
  QuickSelectPanel,
  RefreshUnitsOptions
} from './types/global';
import type { TOC } from '@ember/component/template-only';
import type { ComponentLike } from '@glint/template';

/**
 * The default panels of the quick select popover, yielded to the
 * `<:customQuickSelectRender>` block (upstream
 * `CustomQuickSelectRenderOptions`). Each is a component without arguments;
 * `refreshInterval` and `customQuickSelectPanels` render nothing when the
 * picker has no `@onRefreshChange` / `@customQuickSelectPanels`.
 */
export interface CustomQuickSelectRenderOptions {
  quickSelect: ComponentLike;
  commonlyUsedRanges: ComponentLike;
  recentlyUsedRanges: ComponentLike;
  refreshInterval: ComponentLike;
  customQuickSelectPanels: ComponentLike;
}

/** Upstream: each custom panel's content gets `applyTime`. */
const CustomPanels: TOC<{
  Args: { panels?: QuickSelectPanel[]; applyTime: ApplyTime };
}> = <template>
  {{#each @panels key="title" as |panel|}}
    <EuiQuickSelectPanel @title={{panel.title}}>
      <panel.content @applyTime={{@applyTime}} />
    </EuiQuickSelectPanel>
  {{/each}}
</template>;

const RefreshIntervalPanel: TOC<{
  Args: {
    applyRefreshInterval?: ApplyRefreshInterval;
    onRefreshChange?: ApplyRefreshInterval;
    isPaused?: boolean;
    refreshInterval?: number;
    minInterval?: number;
    intervalUnits?: RefreshUnitsOptions;
  };
}> = <template>
  {{#if (or @applyRefreshInterval @onRefreshChange)}}
    <EuiRefreshInterval
      @applyRefreshInterval={{@applyRefreshInterval}}
      @onRefreshChange={{@onRefreshChange}}
      @isPaused={{@isPaused}}
      @refreshInterval={{@refreshInterval}}
      @minInterval={{@minInterval}}
      @intervalUnits={{@intervalUnits}}
    />
  {{/if}}
</template>;

const CommonlyUsed: TOC<{
  Args: EuiCommonlyUsedTimeRangesSignature['Args'];
}> = <template>
  {{#if @commonlyUsedRanges.length}}
    <EuiCommonlyUsedTimeRanges
      @applyTime={{@applyTime}}
      @commonlyUsedRanges={{@commonlyUsedRanges}}
    />
  {{/if}}
</template>;

/** @private EuiSuperDatePicker's quick select popover. */
export interface EuiQuickSelectPopoverSignature {
  Args: {
    /** Applies a new `{ start, end }` range. */
    applyTime: ApplyTime;
    /** Disables it. */
    isDisabled?: boolean;
    /** Compressed prepend button (follows the picker's `@compressed`). */
    compressed?: boolean;
    /** Ranges listed as "Commonly used". */
    commonlyUsedRanges: EuiCommonlyUsedTimeRangesSignature['Args']['commonlyUsedRanges'];
    /** Ranges listed as "Recently used". */
    recentlyUsedRanges?: EuiRecentlyUsedSignature['Args']['recentlyUsedRanges'];
    /** Start of the range (date math or ISO date). */
    start: string;
    /** End of the range. */
    end: string;
    /** Time units and tenses for the quick select. */
    timeOptions: EuiQuickSelectSignature['Args']['timeOptions'];
    /** Shows the refresh interval section, calling this on change. */
    applyRefreshInterval?: ApplyRefreshInterval;
    /**
     * Like `@applyRefreshInterval`, but also called with the chosen
     * `intervalUnits` (upstream `onRefreshChange`).
     */
    onRefreshChange?: ApplyRefreshInterval;
    /** Smallest refresh interval in milliseconds. */
    refreshMinInterval?: Milliseconds;
    /** Unit of the refresh interval instead of the rounded one. */
    intervalUnits?: RefreshUnitsOptions;
    /** Extra panels, after the default ones. */
    customQuickSelectPanels?: QuickSelectPanel[];
    /**
     * Renders the `<:customQuickSelectRender>` block (the picker always
     * passes one through).
     */
    hasCustomQuickSelectRender?: boolean;
    /** Whether auto refresh is paused. */
    isPaused?: boolean;
    /** The refresh interval in milliseconds. */
    refreshInterval?: number;
  };
  Blocks: {
    /** Replaces the popover's content; yields the default panels. */
    customQuickSelectRender: [CustomQuickSelectRenderOptions];
  };
}

export default class EuiQuickSelectPopover extends Component<EuiQuickSelectPopoverSignature> {
  @service declare euiI18n: EuiI18n;
  @tracked isOpen = false;

  get context() {
    return getEuiThemeContext(this);
  }

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

  @action
  toggle() {
    this.isOpen = !this.isOpen;
  }

  @action
  close() {
    this.isOpen = false;
  }

  get timeOptions() {
    return this.args.timeOptions || useI18nTimeOptions(this.euiI18n);
  }

  get buttonLabel() {
    return this.euiI18n.lookupToken(
      'euiQuickSelectPopover.buttonLabel',
      'Date quick select'
    );
  }

  @cached
  get contentClass() {
    const styles = useEuiBorealisStyles(
      this.context,
      euiQuickSelectPopoverStyles
    );
    return `euiQuickSelectPopover ${euiClass(
      this.context,
      { boxSizing: 'border-box' },
      styles.euiQuickSelectPopover
    )}`;
  }

  <template>
    <EuiPopover
      @isOpen={{this.isOpen}}
      @closePopover={{this.close}}
      @anchorPosition="downLeft"
      @anchorClassName="euiQuickSelectPopover__anchor"
    >
      <:button>
        <EuiToolTip
          @content={{this.buttonLabel}}
          @disableScreenReaderOutput={{true}}
        >
          <EuiFormPrepend
            @element="button"
            @compressed={{@compressed}}
            @isDisabled={{@isDisabled}}
            @iconLeft="calendar"
            @iconRight="chevronSingleDown"
            @onClick={{this.toggle}}
            class="euiQuickSelectPopover__button"
            aria-label={{this.buttonLabel}}
            data-test-subj="superDatePickerToggleQuickMenuButton"
          />
        </EuiToolTip>
      </:button>

      <:content>
        <div
          class={{this.contentClass}}
          data-test-subj="superDatePickerQuickMenu"
        >
          {{#let
            (component
              EuiQuickSelect
              applyTime=this.applyTime
              start=@start
              end=@end
              timeOptions=this.timeOptions
            )
            (component
              CommonlyUsed
              applyTime=this.applyTime
              commonlyUsedRanges=@commonlyUsedRanges
            )
            (component
              EuiRecentlyUsed
              applyTime=this.applyTime
              recentlyUsedRanges=@recentlyUsedRanges
            )
            (component
              RefreshIntervalPanel
              applyRefreshInterval=@applyRefreshInterval
              onRefreshChange=@onRefreshChange
              isPaused=@isPaused
              refreshInterval=@refreshInterval
              minInterval=@refreshMinInterval
              intervalUnits=@intervalUnits
            )
            (component
              CustomPanels
              panels=@customQuickSelectPanels
              applyTime=this.applyTime
            )
            as
            |QuickSelect CommonlyUsedRanges RecentlyUsedRanges RefreshInterval CustomQuickSelectPanels|
          }}
            {{#if @hasCustomQuickSelectRender}}
              {{yield
                (hash
                  quickSelect=QuickSelect
                  commonlyUsedRanges=CommonlyUsedRanges
                  recentlyUsedRanges=RecentlyUsedRanges
                  refreshInterval=RefreshInterval
                  customQuickSelectPanels=CustomQuickSelectPanels
                )
                to="customQuickSelectRender"
              }}
            {{else}}
              <QuickSelect />
              <CommonlyUsedRanges />
              <RecentlyUsedRanges />
              <RefreshInterval />
              <CustomQuickSelectPanels />
            {{/if}}
          {{/let}}
        </div>
      </:content>
    </EuiPopover>
  </template>
}
