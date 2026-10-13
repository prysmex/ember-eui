import Component from '@glimmer/component';
import { fn, hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import { randomId } from '../../../-private/random-id.ts';
import EuiFlexGrid from '../../eui-flex-grid.gts';
import EuiFlexItem from '../../eui-flex-item.gts';
import EuiLink from '../../eui-link.gts';
import { prettyDuration } from '../utils/pretty-duration.ts';
import EuiQuickSelectPanel from './eui-quick-select-panel.gts';

import type EuiI18n from '../../../services/eui-i18n';
import type { DurationRange } from '../types/global';

/** @private The "Recently used" list of the quick select popover. */
export interface EuiRecentlyUsedSignature {
  Args: {
    /** Ranges listed as "Recently used". */
    recentlyUsedRanges?: DurationRange[];
    /** Applies a new `{ start, end }` range. */
    applyTime: (args: { start: string; end: string }) => void;
    /** Commonly used ranges: a matching range shows its label. */
    commonlyUsedRanges?: DurationRange[];
    /** moment format of absolute dates. */
    dateFormat?: string;
  };
}

export default class EuiRecentlyUsed extends Component<EuiRecentlyUsedSignature> {
  @service declare euiI18n: EuiI18n;

  legendId = randomId();

  get title() {
    return this.euiI18n.lookupToken(
      'euiRecentlyUsed.legend',
      'Recently used date ranges'
    );
  }

  get ranges() {
    return this.args.recentlyUsedRanges ?? [];
  }

  /** Upstream renders each range as a `PrettyDuration`. */
  label = (range: DurationRange) =>
    prettyDuration(this.euiI18n, {
      timeFrom: range.start,
      timeTo: range.end,
      quickRanges: this.args.commonlyUsedRanges,
      dateFormat: this.args.dateFormat ?? 'MMM D, YYYY @ HH:mm:ss.SSS'
    });

  <template>
    {{! upstream renders nothing without ranges }}
    {{#if this.ranges.length}}
      <EuiQuickSelectPanel
        @tagName="fieldset"
        @title={{this.title}}
        @titleId={{this.legendId}}
      >
        <EuiFlexGrid
          aria-labelledby={{this.legendId}}
          @gutterSize="s"
          @columns={{1}}
          @direction="column"
          @responsive={{false}}
          @tagName="ul"
        >
          {{#each this.ranges as |range|}}
            <EuiFlexItem
              class="euiQuickSelectPopover__sectionItem"
              @tagName="li"
            >
              <EuiLink
                {{on
                  "click"
                  (fn @applyTime (hash start=range.start end=range.end))
                }}
              >
                {{this.label range}}
              </EuiLink>
            </EuiFlexItem>
          {{/each}}
        </EuiFlexGrid>
      </EuiQuickSelectPanel>
    {{/if}}
  </template>
}
