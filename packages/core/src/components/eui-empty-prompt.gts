import classNames from '@ember-eui/core/helpers/class-names';
import { gte, eq } from 'ember-truth-helpers';
import EuiPanel from '@ember-eui/core/components/eui-panel';
import EuiIcon from '@ember-eui/core/components/eui-icon';
import EuiTitle from '@ember-eui/core/components/eui-title';
import EuiTextColor from '@ember-eui/core/components/eui-text-color';
import EuiSpacer from '@ember-eui/core/components/eui-spacer';
import EuiText from '@ember-eui/core/components/eui-text';
import EuiFlexGroup from '@ember-eui/core/components/eui-flex-group';
import EuiFlexItem from '@ember-eui/core/components/eui-flex-item';
import { concat } from '@ember/helper';
import argOrDefault from '@ember-eui/core/helpers/arg-or-default';

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
                  {{#each @actions as |action|}}
                    <EuiFlexItem @grow={{false}}>
                      {{action}}
                    </EuiFlexItem>
                  {{/each}}
                </EuiFlexGroup>
              {{else}}
                <EuiSpacer size="l" />
                {{#each @actions as |action|}}
                  {{action}}
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
</template>
