import Component from '@glimmer/component';
import type { EuiButtomBarArgs } from './eui-bottom-bar';
import argOrDefault, { argOrDefaultDecorator } from '../helpers/arg-or-default';
import EuiTabs from './eui-tabs';
import EuiTab from './eui-tab';
import EuiFlexItem from './eui-flex-item';
import EuiFlexGroup from './eui-flex-group';
import EuiBreadcrumbs from './eui-breadcrumbs';
import EuiSpacer from './eui-spacer';
import EuiTitle from './eui-title';
import EuiIcon from './eui-icon';
import EuiText from './eui-text';
import { and, or, not } from 'ember-truth-helpers';
import useIsWithinBreakpoints from '../modifiers/use-is-within-breakpoints';
import useState from '../helpers/use-state';

import classNames from '../helpers/class-names';
import euiPageRestrictWidth from '../helpers/eui-page-restrict-width';
import { concat } from '@ember/helper';
import { paddingSizeMapping } from '../utils/css-mappings/eui-page-content-body';
import style from 'ember-style-modifier/modifiers/style';

export const TEMPLATES = [
  'default',
  'centeredBody',
  'centeredContent',
  'empty'
] as const;

export type EuiPageTemplateProps = {
  template?: (typeof TEMPLATES)[number];
  /**
  //  * Gets passed along to the #EuiBottomBar component if `bottomBar` has contents





  //  */
  bottomBarProps?: EuiButtomBarArgs;
  //  * Stretches or restricts the height to 100% of the parent;
  //  * `true`: scrolls the EuiPageContentBody;
  //  * `noscroll`: removes all scroll ability;
  //  * Only works when `template = 'default | empty'` and breakpoint is `m` and above
  //  */
  fullHeight?: boolean;
  /**
   * Minimum height in which to enforce scrolling
   */
  minHeight?: number;
};

export default class EuiPageTemplate extends Component<EuiPageTemplateProps> {
  // Defaults
  @argOrDefaultDecorator(460) minHeight!: number;
  @argOrDefaultDecorator(false) fullHeight!: boolean;
  @argOrDefaultDecorator('default') template!: (typeof TEMPLATES)[number];

  get classes() {
    return 'euiPageTemplate '.concat(this.fullHeightClass);
  }

  get fullHeightClass() {
    return this.fullHeight && this.canFullHeight
      ? 'eui-fullHeight eui-yScroll'
      : '';
  }

  get canFullHeight() {
    return this.template === 'default' || this.template === 'empty';
  }

  <template>
    {{#let
      (argOrDefault @responsive true)
      (argOrDefault @alignItems "top")
      (useState false)
      (and (argOrDefault @hasDescriptionBlock true) (has-block "description"))
      (and
        (argOrDefault @hasRightSideItemsBlock true) (has-block "rightSideItems")
      )
      (or
        (and (argOrDefault @hasPageTitleBlock true) (has-block "pageTitle"))
        @pageTitle
      )
      (and (argOrDefault @hasDefaultBlock true) (has-block "default"))
      as |responsive alignItems isResponsiveBreakpoint hasDescriptionBlock hasRightSideItemsBlock hasPageTitleBlock hasDefaultBlock|
    }}
      <div
        class={{classNames
          "euiPageHeaderContent"
          (if @restrictWidth "euiPanel--restrictWidth-custom" "")
        }}
        {{style (inlineStyles width=@restrictWidth)}}
        {{useIsWithinBreakpoints
          sizes=(array "xs" "s")
          isActive=(not (not responsive))
          setIsWithinBreakpointsValue=isResponsiveBreakpoint.setState
        }}
        ...attributes
      >
        {{#if @breadcrumbs}}
          <EuiBreadcrumbs
            @breadcrumbs={{@breadcrumbs}}
            class={{@breadcrumbProps.className}}
          />
          <EuiSpacer @size="s" />
        {{/if}}
        {{#if (or (eq alignItems "top") isResponsiveBreakpoint.value)}}
          <EuiFlexGroup
            class="euiPageHeaderContent__top"
            @responsive={{not (not responsive)}}
            @alignItems={{if hasPageTitleBlock "flexStart" "baseline"}}
            @gutterSize="l"
          >
            {{#if (and isResponsiveBreakpoint.value (eq responsive "reverse"))}}
              {{#if hasRightSideItemsBlock}}
                <EuiFlexItem @grow={{false}}>
                  <EuiFlexGroup
                    @wrap={{true}}
                    @responsive={{false}}
                    class={{classNames
                      "euiPageHeaderContent__rightSideItems"
                      @rightSideGroupProps.className
                    }}
                  >
                    {{yield
                      (component "eui-flex-item" grow=false)
                      to="rightSideItems"
                    }}
                  </EuiFlexGroup>
                </EuiFlexItem>
              {{/if}}
              <EuiFlexItem>
                {{#if (and (not hasPageTitleBlock) @tabs)}}
                  <EuiTabs
                    @size="xl"
                    @display="condensed"
                    @bottomBorder={{false}}
                  >
                    {{#each @tabs as |tab|}}
                      <EuiTab
                        @isSelected={{tab.isSelected}}
                        @href={{tab.href}}
                        {{on "click" (optional tab.onClick)}}
                      >
                        {{tab.label}}
                      </EuiTab>
                    {{/each}}
                  </EuiTabs>
                {{/if}}
                {{#if hasPageTitleBlock}}
                  <EuiTitle
                    class={{@pageTitleProps.className}}
                    @size="l"
                    @tagName="h1"
                  >
                    {{#if @iconType}}
                      <EuiIcon
                        @size="xl"
                        @type={{@iconType}}
                        @iconClasses={{class-names
                          "euiPageHeaderContent__titleIcon"
                          @iconProps.className
                        }}
                      />
                    {{/if}}

                    {{@pageTitle}}
                    {{yield to="pageTitle"}}

                  </EuiTitle>
                {{/if}}

                {{#if hasDescriptionBlock}}
                  {{#if (or hasPageTitleBlock @tabs)}}
                    <EuiSpacer />
                  {{/if}}
                  <EuiText @grow={{false}}>
                    {{@description}}
                    {{yield to="description"}}
                  </EuiText>
                {{/if}}
              </EuiFlexItem>
            {{else}}
              <EuiFlexItem>
                {{#if (and (not hasPageTitleBlock) @tabs)}}
                  <EuiTabs
                    @size="xl"
                    @display="condensed"
                    @bottomBorder={{false}}
                  >
                    {{#each @tabs as |tab|}}
                      <EuiTab
                        @isSelected={{tab.isSelected}}
                        {{on "click" (optional tab.onClick)}}
                      >
                        {{tab.label}}
                      </EuiTab>
                    {{/each}}
                  </EuiTabs>
                {{/if}}
                {{#if hasPageTitleBlock}}
                  <EuiTitle
                    class={{@pageTitleProps.className}}
                    @size="l"
                    @tagName="h1"
                  >
                    {{#if @iconType}}
                      <EuiIcon
                        @size="xl"
                        @type={{@iconType}}
                        @iconClasses={{class-names
                          "euiPageHeaderContent__titleIcon"
                          @iconProps.className
                        }}
                      />
                    {{/if}}

                    {{@pageTitle}}
                    {{yield to="pageTitle"}}
                  </EuiTitle>
                {{/if}}

                {{#if hasDescriptionBlock}}
                  {{#if (or hasPageTitleBlock @tabs)}}
                    <EuiSpacer />
                  {{/if}}
                  <EuiText @grow={{false}}>
                    {{@description}}
                    {{yield to="description"}}
                  </EuiText>
                {{/if}}
              </EuiFlexItem>
              {{#if hasRightSideItemsBlock}}
                <EuiFlexItem @grow={{false}}>
                  <EuiFlexGroup
                    @wrap={{true}}
                    @responsive={{false}}
                    class={{class-names
                      "euiPageHeaderContent__rightSideItems"
                      @rightSideGroupProps.className
                    }}
                  >
                    {{yield
                      (component "eui-flex-item" grow=false)
                      to="rightSideItems"
                    }}
                  </EuiFlexGroup>
                </EuiFlexItem>
              {{/if}}
            {{/if}}
          </EuiFlexGroup>
          {{#if (or hasDefaultBlock (and hasPageTitleBlock @tabs))}}
            <div class="euiPageHeaderContent__bottom">
              <EuiSpacer />
              {{yield to="default"}}
              {{#if hasPageTitleBlock}}
                <EuiTabs @size="l" @display="condensed" @bottomBorder={{false}}>
                  {{#each @tabs as |tab|}}
                    <EuiTab
                      @isSelected={{tab.isSelected}}
                      {{on "click" (optional tab.onClick)}}
                    >
                      {{tab.label}}
                    </EuiTab>
                  {{/each}}
                </EuiTabs>
              {{/if}}
            </div>
          {{/if}}
        {{else}}
          <EuiFlexGroup
            class="euiPageHeaderContent__top"
            @responsive={{not (not responsive)}}
            @alignItems={{if (eq alignItems "bottom") "flexEnd" alignItems}}
            @gutterSize="l"
          >
            <EuiFlexItem>
              {{#if (and (not hasPageTitleBlock) @tabs)}}
                <EuiTabs
                  @size="xl"
                  @display="condensed"
                  @bottomBorder={{false}}
                >
                  {{#each @tabs as |tab|}}
                    <EuiTab
                      @isSelected={{tab.isSelected}}
                      @href={{tab.href}}
                      {{on "click" (optional tab.onClick)}}
                    >
                      {{tab.label}}
                    </EuiTab>
                  {{/each}}
                </EuiTabs>
              {{/if}}
              {{#if hasPageTitleBlock}}
                <EuiTitle
                  class={{@pageTitleProps.className}}
                  @size="l"
                  @tagName="h1"
                >
                  {{#if @iconType}}
                    <EuiIcon
                      @size="xl"
                      @type={{@iconType}}
                      @iconClasses={{class-names
                        "euiPageHeaderContent__titleIcon"
                        @iconProps.className
                      }}
                    />
                  {{/if}}

                  {{@pageTitle}}
                  {{yield to="pageTitle"}}
                </EuiTitle>
              {{/if}}

              {{#if hasDescriptionBlock}}
                {{#if (or hasPageTitleBlock @tabs)}}
                  <EuiSpacer />
                {{/if}}
                <EuiText @grow={{false}}>
                  {{@description}}
                  {{yield to="description"}}
                </EuiText>
              {{/if}}
              {{#if (or hasDefaultBlock (and hasPageTitleBlock @tabs))}}
                <div class="euiPageHeaderContent__bottom">
                  <EuiSpacer />
                  {{yield to="default"}}
                  {{#if hasPageTitleBlock}}
                    <EuiTabs
                      @size="l"
                      @display="condensed"
                      @bottomBorder={{false}}
                    >
                      {{#each @tabs as |tab|}}
                        <EuiTab
                          @isSelected={{tab.isSelected}}
                          {{on "click" (optional tab.onClick)}}
                        >
                          {{tab.label}}
                        </EuiTab>
                      {{/each}}
                    </EuiTabs>
                  {{/if}}
                </div>
              {{/if}}
            </EuiFlexItem>
            {{#if hasRightSideItemsBlock}}
              <EuiFlexItem @grow={{false}}>
                <EuiFlexGroup
                  @wrap={{true}}
                  @responsive={{false}}
                  class={{class-names
                    "euiPageHeaderContent__rightSideItems"
                    @rightSideGroupProps.className
                  }}
                >
                  {{yield
                    (component "eui-flex-item" grow=false)
                    to="rightSideItems"
                  }}
                </EuiFlexGroup>
              </EuiFlexItem>
            {{/if}}
          </EuiFlexGroup>
        {{/if}}
      </div>
    {{/let}}
  </template>
}
