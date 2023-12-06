import type { TemplateOnlyComponent } from '@ember/component/template-only';

import uniqueId from 'ember-unique-id-helper-polyfill/helpers/unique-id';
import EuiTitle from '../../eui-title.gts';
import EuiI18n from '../../eui-i18n.gts';
import EuiFlexGrid from '../../eui-flex-grid.gts';
import EuiFlexItem from '../../eui-flex-item.gts';
import EuiLink from '../../eui-link.gts';
import { on } from '@ember/modifier';
import { fn, hash } from '@ember/helper';
import type { DurationRange } from '../types/global';

export interface EuiRecentlyUsedSignature {
  Args: {
    recentlyUsedRanges?: DurationRange[];
    applyTime: (args: { start: string; end: string }) => void;
  };
}

const EuiRecentlyUsed: TemplateOnlyComponent<EuiRecentlyUsedSignature> =
  <template>
    {{#let (uniqueId) as |legendId|}}
      <fieldset>
        <EuiTitle id={{legendId}} @tagName="legend" @size="xxxs">
          <EuiI18n
            @token="euiRecentlyUsed.legend"
            @default="Recently used date ranges"
            as |Token|
          >
            <Token as |value|>
              {{value}}
            </Token>
          </EuiI18n>
        </EuiTitle>
        <div class="euiQuickSelectPopover__section">
          <EuiFlexGrid
            aria-labelledby={{legendId}}
            @gutterSize="s"
            @columns={{2}}
            @direction="column"
            @responsive={{false}}
            @tagName="ul"
          >
            {{#each @recentlyUsedRanges as |range|}}
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
                  {{range.label}}
                </EuiLink>
              </EuiFlexItem>
            {{/each}}
          </EuiFlexGrid>
        </div>
      </fieldset>
    {{/let}}
  </template>;

export default EuiRecentlyUsed;
