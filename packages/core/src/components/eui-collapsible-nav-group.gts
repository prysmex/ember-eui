import { concat } from '@ember/helper';

import { element } from 'ember-element-helper';
import { and, or } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import EuiAccordion from './eui-accordion.gts';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiIcon from './eui-icon.gts';

import type { EuiAccordionSignature } from './eui-accordion';
import type { EuiIconSignature } from './eui-icon';
import type { EuiTitleSignature } from './eui-title';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiCollapsibleNavGroupSignature {
  Element: EuiAccordionSignature['Element'];
  Args: {
    /** Id of the group. Defaults to a random id. */
    id?: string;
    /** Tag of the title, e.g. `'h2'` or `'div'`. Defaults to `'h3'`. */
    titleElement?: string;
    /**
     * Makes the group an accordion that opens and closes from its title
     * (needs a `<:title>` block).
     */
    isCollapsible?: boolean;
    /** Whether a collapsible group starts open. Defaults to `true`. */
    initialIsOpen?: boolean;
    /** Icon before the title; anything `EuiIcon`'s `@type` accepts. */
    iconType?: EuiIconSignature['Args']['type'];
    /** Size of the icon. Defaults to `'l'`. */
    iconSize?: EuiIconSignature['Args']['size'];
    /** Same as `@titleElement`, limited to `EuiTitle`'s tags. Defaults to `'h3'`. */
    titleTagName?: EuiTitleSignature['Args']['tagName'];
    /** Size of the title, any `EuiTitle` size. Defaults to `'xxs'`. */
    titleSize?: EuiTitleSignature['Args']['size'];
    /**
     * Background of the group: `'none'`, `'light'` or `'dark'`.
     * Defaults to `'none'`.
     */
    background?: string;
  };
  Blocks: {
    /** Unused, use `<:title>` and `<:content>`. */
    default: [];
    /** The group's title; without it the group has no heading. */
    title: [];
    /** The group's links, e.g. an `EuiListGroup`. */
    content: [];
  };
}

const EuiCollapsibleNavGroup: TemplateOnlyComponent<EuiCollapsibleNavGroupSignature> =
  <template>
    {{#let
      (argOrDefault @id (randomId)) (or @titleElement @titleTagName "h3")
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
                  {{#let (element titleElement) as |TitleElement|}}
                    <TitleElement
                      id={{titleID}}
                      class={{classNames
                        "euiCollapsibleNavGroup__title"
                        componentName="EuiTitle"
                        size=(argOrDefault @titleSize "xxs")
                      }}
                    >
                      {{yield to="title"}}
                    </TitleElement>
                  {{/let}}
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
                    {{#let (element titleElement) as |TitleElement|}}
                      <TitleElement
                        id={{titleID}}
                        class={{classNames
                          "euiCollapsibleNavGroup__title"
                          componentName="EuiTitle"
                          size=(argOrDefault @titleSize "xxs")
                        }}
                      >
                        {{yield to="title"}}
                      </TitleElement>
                    {{/let}}
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
