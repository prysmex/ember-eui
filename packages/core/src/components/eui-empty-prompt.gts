import { concat } from '@ember/helper';

import { eq,gte } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiIcon from './eui-icon.gts';
import EuiPanel from './eui-panel.gts';
import EuiSpacer from './eui-spacer.gts';
import EuiText from './eui-text.gts';
import EuiTextColor from './eui-text-color.gts';
import EuiTitle from './eui-title.gts';

import type { EuiIconSignature } from './eui-icon';
import type { EuiPanelSignature } from './eui-panel';
import type { EuiTitleSignature } from './eui-title';
import type { TemplateOnlyComponent } from '@ember/component/template-only';
import type { ComponentLike } from '@glint/template';

/**
 * A message filling an empty page or section: an icon, a title, some text
 * and actions, e.g. when a list has no items yet or a page failed to load.
 */
export interface EuiEmptyPromptSignature {
  Element: EuiPanelSignature['Element'];
  Args: {
    /**
     * `'vertical'` centers everything in a column; `'horizontal'` puts the
     * icon beside the text. Defaults to `'vertical'`.
     */
    layout?: 'vertical' | 'horizontal';
    /** Padding around the content, any `EuiPanel` padding size. Defaults to `'l'`. */
    paddingSize?: EuiPanelSignature['Args']['paddingSize'];
    /**
     * Background, any `EuiPanel` color (`'plain'`, `'subdued'`, `'danger'`,
     * …). Defaults to `'transparent'`.
     */
    color?: EuiPanelSignature['Args']['color'];
    /** Adds a border around the prompt. */
    hasBorder?: EuiPanelSignature['Args']['hasBorder'];
    /** Large icon above the title, e.g. `'search'` or `'logoKibana'`. */
    iconType?: EuiIconSignature['Args']['type'];
    /** Color of the icon. Defaults to `@color`, or `'subdued'`. */
    iconColor?: EuiIconSignature['Args']['color'];
    /** Title, e.g. "No dashboards yet". */
    title?: string;
    /** Size of the title, any `EuiTitle` size. Defaults to `'m'`. */
    titleSize?: EuiTitleSignature['Args']['size'];
    /** Text explaining the situation and what to do. */
    body?: string;
    /**
     * Components rendered as the prompt's actions (e.g. a primary
     * `EuiButton` and an `EuiButtonEmpty`), laid out in a row or column.
     * Use the `<:content>` block for full control.
     */
    actions?: ComponentLike[];
    /** Text in a footer, e.g. a link to the docs. Use the `<:footer>` block for markup. */
    footer?: string;
  };
  Blocks: {
    /** Custom content instead of the `@iconType` icon, e.g. an `EuiImage`. */
    icon?: [];
    /** Replaces the title, body and actions with your own content. */
    content?: [];
    /** The footer, instead of `@footer`. */
    footer?: [];
  };
}

const EuiEmptyPrompt: TemplateOnlyComponent<EuiEmptyPromptSignature> =
  <template>
    {{#let (argOrDefault @layout "vertical") as |layout|}}
      <EuiPanel
        class={{classNames
          (if
            layout (concat "euiEmptyPrompt--" layout) "euiEmptyPrompt--vertical"
          )
          componentName="EuiEmptyPrompt"
          paddingSize=(argOrDefault @paddingSize "l")
        }}
        @paddingSize="none"
        @color={{argOrDefault @color "transparent"}}
        @hasBorder={{@hasBorder}}
        @hasShadow={{false}}
        ...attributes
      >
        <div class="euiEmptyPrompt__main">
          {{#if (has-block "icon")}}
            <div class="euiEmptyPrompt__icon">{{yield to="icon"}}</div>
          {{else if @iconType}}
            <div class="euiEmptyPrompt__icon">
              <EuiIcon
                @type={{@iconType}}
                @size="xxl"
                @color={{if @iconColor @iconColor (if @color @color "subdued")}}
              />
            </div>
          {{/if}}
          <div class="euiEmptyPrompt__content">
            {{#if (has-block "content")}}
              <div class="euiEmptyPrompt__contentInner">{{yield
                  to="content"
                }}</div>
            {{else}}
              <div class="euiEmptyPrompt__contentInner">
                {{#if @title}}
                  <EuiTitle
                    @size={{argOrDefault @titleSize "m"}}
                  >{{@title}}</EuiTitle>
                {{/if}}
                {{#if @body}}
                  <EuiTextColor @color="subdued">
                    {{#if @title}}
                      <EuiSpacer @size="m" />
                    {{/if}}
                    <EuiText>
                      {{@body}}
                    </EuiText>
                  </EuiTextColor>
                {{/if}}
                {{#if @actions.length}}
                  <EuiSpacer size="l" />
                {{/if}}
                {{#if (gte @actions.length 2)}}
                  <EuiFlexGroup
                    class="euiEmptyPrompt__actions"
                    @gutterSize="m"
                    @alignItems="center"
                    @justifyContent="center"
                    @direction={{if (eq layout "vertical") "column" "row"}}
                  >
                    {{#each @actions as |oneAction|}}
                      <EuiFlexItem @grow={{false}}>
                        {{oneAction}}
                      </EuiFlexItem>
                    {{/each}}
                  </EuiFlexGroup>
                {{else}}
                  <EuiSpacer size="l" />
                  {{#each @actions as |oneAction|}}
                    {{oneAction}}
                  {{/each}}
                {{/if}}
              </div>
            {{/if}}
          </div>
        </div>

        {{#if (has-block "footer")}}
          <div class="euiEmptyPrompt__footer">
            {{yield to="footer"}}
          </div>
        {{else}}
          {{#if @footer}}
            <div class="euiEmptyPrompt__footer">
              {{@footer}}
            </div>
          {{/if}}
        {{/if}}
      </EuiPanel>
    {{/let}}
  </template>;

export default EuiEmptyPrompt;
