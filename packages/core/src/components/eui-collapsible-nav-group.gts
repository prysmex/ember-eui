import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import { concat } from '@ember/helper';
import { and, notEq } from 'ember-truth-helpers';
import EuiAccordion from './eui-accordion';
import EuiFlexGroup from './eui-flex-group';
import EuiFlexItem from './eui-flex-item';
import EuiIcon from './eui-icon';
import EuiTitle from './eui-title';
import { guidFor } from '@ember/object/internals';
import { element } from 'ember-element-helper';

<template>
  {{#let
    (argOrDefault @id (guidFor)) (argOrDefault @titleElement "h3")
    as |groupID titleElement|
  }}
    {{#let (concat groupID "__title") as |titleID|}}
      {{#if (and @isCollapsible (has-block "title"))}}
        <EuiAccordion
          id={{groupID}}
          class={{classNames
            (if (has-block "title") "euiCollapsibleNavGroup--withHeading")
            componentName="EuiCollapsibleNavGroup"
            backgroundColor=(argOrDefault @background "none")
          }}
          @buttonClassName="euiCollapsibleNavGroup__heading"
          @initialIsOpen={{argOrDefault @initialIsOpen true}}
          @arrowDisplay="right"
          ...attributes
        >
          <:buttonContent>
            <EuiFlexGroup
              @gutterSize="m"
              @alignItems="center"
              @responsive={{false}}
            >
              {{#if @iconType}}
                <EuiFlexItem @grow={{false}}>
                  <EuiIcon
                    @type={{@iconType}}
                    @size={{argOrDefault @iconSize "l"}}
                  />
                </EuiFlexItem>
              {{/if}}
              <EuiFlexItem>
                <EuiTitle
                  id={{concat groupID "__title"}}
                  @tagName={{argOrDefault @titleTagName "h3"}}
                  @size={{argOrDefault @titleSize "xxs"}}
                >
                  {{#if (not-eq titleElement "h3")}}
                    {{#let (element titleElement) as |TitleElement|}}
                      <TitleElement
                        id={{titleID}}
                        class="euiCollapsibleNavGroup__title"
                      >
                        {{yield to="title"}}
                      </TitleElement>
                    {{/let}}
                  {{else}}
                    <h3 id={{titleID}} class="euiCollapsibleNavGroup__title">
                      {{yield to="title"}}
                    </h3>
                  {{/if}}
                </EuiTitle>
              </EuiFlexItem>
            </EuiFlexGroup>
          </:buttonContent>
          <:content>
            {{#if (has-block "content")}}
              <div class="euiCollapsibleNavGroup__children">
                {{yield to="content"}}
              </div>
            {{/if}}
          </:content>
        </EuiAccordion>
      {{else}}
        <div
          id={{groupID}}
          class={{classNames
            (if (has-block "title") "euiCollapsibleNavGroup--withHeading")
            componentName="EuiCollapsibleNavGroup"
            backgroundColor=(argOrDefault @background "none")
          }}
          ...attributes
        >
          {{#if (has-block "title")}}
            <div class="euiCollapsibleNavGroup__heading">
              <EuiFlexGroup
                @gutterSize="m"
                @alignItems="center"
                @responsive={{false}}
              >
                {{#if @iconType}}
                  <EuiFlexItem @grow={{false}}>
                    <EuiIcon
                      @type={{@iconType}}
                      @size={{argOrDefault @iconSize "l"}}
                    />
                  </EuiFlexItem>
                {{/if}}
                <EuiFlexItem>
                  <EuiTitle
                    id={{concat groupID "__title"}}
                    @tagName={{argOrDefault @titleTagName "h3"}}
                    @size={{argOrDefault @titleSize "xxs"}}
                  >
                    {{#if (notEq titleElement "h3")}}
                      {{#let (element titleElement) as |TitleElement|}}
                        <TitleElement
                          id={{titleID}}
                          class="euiCollapsibleNavGroup__title"
                        >
                          {{yield to="title"}}
                        </TitleElement>
                      {{/let}}
                    {{else}}
                      <h3 id={{titleID}} class="euiCollapsibleNavGroup__title">
                        {{yield to="title"}}
                      </h3>
                    {{/if}}
                  </EuiTitle>
                </EuiFlexItem>
              </EuiFlexGroup>
            </div>
          {{/if}}
          {{#if (has-block "content")}}
            <div class="euiCollapsibleNavGroup__children">
              {{yield to="content"}}
            </div>
          {{/if}}
        </div>
      {{/if}}
    {{/let}}
  {{/let}}
</template>
