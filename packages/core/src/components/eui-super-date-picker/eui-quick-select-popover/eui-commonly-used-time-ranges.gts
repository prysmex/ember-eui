import Component from '@glimmer/component';
import { fn, hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import { randomId } from '../../../-private/random-id.ts';
import EuiFlexGrid from '../../eui-flex-grid.gts';
import EuiFlexItem from '../../eui-flex-item.gts';
import EuiLink from '../../eui-link.gts';
import EuiQuickSelectPanel from './eui-quick-select-panel.gts';

import type EuiI18n from '../../../services/eui-i18n';
import type { DurationRange } from '../types/global';

/** @private The "Commonly used" list of the quick select popover. */
export interface EuiCommonlyUsedTimeRangesSignature {
  Args: {
    /** Applies a new `{ start, end }` range. */
    applyTime: (args: { start: string; end: string }) => void;
    /** Ranges listed as "Commonly used". */
    commonlyUsedRanges: DurationRange[];
  };
}

/** Upstream `data-test-subj`: the label with its first space replaced. */
const testSubj = (label?: string) =>
  label ? `superDatePickerCommonlyUsed_${label.replace(' ', '_')}` : undefined;

export default class EuiCommonlyUsedTimeRanges extends Component<EuiCommonlyUsedTimeRangesSignature> {
  @service declare euiI18n: EuiI18n;

  legendId = randomId();
  testSubj = testSubj;

  get title() {
    return this.euiI18n.lookupToken(
      'euiCommonlyUsedTimeRanges.legend',
      'Commonly used'
    );
  }

  <template>
    <EuiQuickSelectPanel
      @tagName="fieldset"
      @title={{this.title}}
      @titleId={{this.legendId}}
    >
      <EuiFlexGrid
        aria-labelledby={{this.legendId}}
        @gutterSize="s"
        @columns={{2}}
        @direction="column"
        @responsive={{false}}
        @tagName="ul"
      >
        {{#each @commonlyUsedRanges as |range|}}
          <EuiFlexItem
            class="euiQuickSelectPopover__sectionItem"
            @tagName="li"
          >
            <EuiLink
              data-test-subj={{this.testSubj range.label}}
              {{on "click" (fn @applyTime (hash start=range.start end=range.end))}}
            >
              {{range.label}}
            </EuiLink>
          </EuiFlexItem>
        {{/each}}
      </EuiFlexGrid>
    </EuiQuickSelectPanel>
  </template>
}
