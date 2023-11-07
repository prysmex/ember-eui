import classNames from '../helpers/class-names';
import { gte, eq } from 'ember-truth-helpers';
import EuiPanel from './eui-panel.gts';
import type { EuiPanelSignature } from './eui-panel.gts';
import EuiIcon from './eui-icon.gts';
import type { EuiIconSignature } from './eui-icon.gts';
import EuiTitle from './eui-title.gts';
import type { EuiTitleSignature } from './eui-title.gts';
import EuiTextColor from './eui-text-color.gts';
import EuiSpacer from './eui-spacer.gts';
import EuiText from './eui-text.gts';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import { concat } from '@ember/helper';
import argOrDefault from '../helpers/arg-or-default';
import type { ComponentLike } from '@glint/template';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiEmptyPromptSignature {
  Element: EuiPanelSignature['Element'];
  Args: {
    layout?: 'vertical' | 'horizontal';
    paddingSize?: EuiPanelSignature['Args']['paddingSize'];
    color?: EuiPanelSignature['Args']['color'];
    hasBorder?: EuiPanelSignature['Args']['hasBorder'];
    iconType?: EuiIconSignature['Args']['type'];
    iconColor?: EuiIconSignature['Args']['color'];
    title?: string;
    titleSize?: EuiTitleSignature['Args']['size'];
    body?: string;
    actions?: ComponentLike[];
    footer?: string;
  };
  Blocks: {
    icon?: [];
    content?: [];
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
                {{#if (gte @actions.length 2)}}
                  <EuiSpacer size="l" />
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
