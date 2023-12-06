import { concat } from '@ember/helper';

import { element } from 'ember-element-helper';
import { and, notEq } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import uniqueId from 'ember-unique-id-helper-polyfill/helpers/unique-id';
import EuiAccordion from './eui-accordion.gts';
import type { EuiAccordionSignature } from './eui-accordion.gts';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiIcon from './eui-icon.gts';
import type { EuiIconSignature } from './eui-icon.gts';
import EuiTitle from './eui-title.gts';
import type { EuiTitleSignature } from './eui-title.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiCollapsibleNavGroupSignature {
  Element: EuiAccordionSignature['Element'];
  Args: {
    id?: string;
    titleElement?: string;
    isCollapsible?: boolean;
    initialIsOpen?: boolean;
    iconType?: EuiIconSignature['Args']['type'];
    iconSize?: EuiIconSignature['Args']['size'];
    titleTagName?: EuiTitleSignature['Args']['tagName'];
    titleSize?: EuiTitleSignature['Args']['size'];
    background?: string;
  };
  Blocks: {
    default: [];
    title: [];
    content: [];
  };
}

const EuiCollapsibleNavGroup: TemplateOnlyComponent<EuiCollapsibleNavGroupSignature> =
  <template>
    {{#let
      (argOrDefault @id (uniqueId)) (argOrDefault @titleElement "h3")
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
                        <h3
                          id={{titleID}}
                          class="euiCollapsibleNavGroup__title"
                        >
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
  </template>;

export default EuiCollapsibleNavGroup;
