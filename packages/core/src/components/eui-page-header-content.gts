import Component from '@glimmer/component';
import { array } from '@ember/helper';
import { on } from '@ember/modifier';

import optional from 'ember-composable-helpers/helpers/optional';
import style from 'ember-style-modifier/modifiers/style';
import { and, eq, not, or } from 'ember-truth-helpers';

import argOrDefault, { argOrDefaultDecorator } from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import inlineStyles from '../helpers/inline-styles';
import useState from '../helpers/use-state';
import useIsWithinBreakpoints from '../modifiers/use-is-within-breakpoints';
import EuiBreadcrumbs from './eui-breadcrumbs.gts';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiIcon from './eui-icon.gts';
import EuiSpacer from './eui-spacer.gts';
import EuiTab from './eui-tab.gts';
import EuiTabs from './eui-tabs.gts';
import EuiText from './eui-text.gts';
import EuiTitle from './eui-title.gts';

import type { paddingSizeMapping } from '../utils/css-mappings/eui-page-content-body';
import type { EuiButtomBarArgs } from './eui-bottom-bar';
import type { EuiBreadcrumbsSignature } from './eui-breadcrumbs';
import type { EuiIconSignature } from './eui-icon';
import type { IEuiTab } from './eui-tab';
import type { WithBoundArgs } from '@glint/template';

export const TEMPLATES = [
  'default',
  'centeredBody',
  'centeredContent',
  'empty'
] as const;

type Tab = IEuiTab & {
  label?: string;
  onClick?: () => void;
};

export type EuiPageHeaderContentProps = {
  template?: (typeof TEMPLATES)[number];
  /**
   * Gets passed along to the #EuiBottomBar component if `bottomBar` has contents
   */
  bottomBarProps?: EuiButtomBarArgs;
  /* Stretches or restricts the height to 100% of the parent;
   * `true`: scrolls the EuiPageContentBody;
   * `noscroll`: removes all scroll ability;
   * Only works when `template = 'default | empty'` and breakpoint is `m` and above
   */
  fullHeight?: boolean;
  /**
   * Minimum height in which to enforce scrolling
   */
  minHeight?: number;

  /**
   * Restrict the width of the page content body
   */
  restrictWidth?: boolean | string;

  /**
   * Adds a bottom border to the page header
   */
  bottomBorder?: boolean;

  /**
   * Adds a bottom border to the page content body
   */
  bodyBottomBorder?: boolean;

  /**
   * Adds a bottom border to the page content body
   */
  bodyProps?: {
    /**
     * Adds padding to the page content body
     */
    paddingSize?: keyof typeof paddingSizeMapping;
  };
  /**
   * Adds a bottom border to the page content body
   */
  contentProps?: {
    /**
     * Adds padding to the page content body
     */
    paddingSize?: keyof typeof paddingSizeMapping;
  };

  alignItems?: 'top' | 'bottom' | 'center' | 'stretch';

  responsive?: boolean | 'reverse';

  hasDescriptionBlock?: boolean;

  hasRightSideItemsBlock?: boolean;

  hasPageTitleBlock?: boolean;

  hasDefaultBlock?: boolean;

  pageTitle?: string;

  breadcrumbs?: EuiBreadcrumbsSignature['Args']['breadcrumbs'];

  breadcrumbProps?: {
    className?: string;
  };

  rightSideGroupProps?: {
    className?: string;
  };

  pageTitleProps?: {
    className?: string;
  };

  iconType?: EuiIconSignature['Args']['type'];

  description?: string;

  iconProps?: {
    className?: string;
  };

  tabs?: Tab[];
};

export interface EuiPageHeaderContentSignature {
  Element: HTMLDivElement;
  Args: EuiPageHeaderContentProps;
  Blocks: {
    default: [];
    pageTitle: [];
    description: [];
    rightSideItems: [WithBoundArgs<typeof EuiFlexItem, 'grow'>?];
  };
}

export default class EuiPageHeaderContent extends Component<EuiPageHeaderContentSignature> {
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
                      (component EuiFlexItem grow=false)
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
                        @id={{tab.id}}
                        @disabled={{tab.disabled}}
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
                        @iconClasses={{classNames
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
                        @id={{tab.id}}
                        @disabled={{tab.disabled}}
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
                        @iconClasses={{classNames
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
                    class={{classNames
                      "euiPageHeaderContent__rightSideItems"
                      @rightSideGroupProps.className
                    }}
                  >
                    {{yield
                      (component EuiFlexItem grow=false)
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
                      @id={{tab.id}}
                      @disabled={{tab.disabled}}
                      @isSelected={{tab.isSelected}}
                      @href={{tab.href}}
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
            {{!@glint-expect-error}}
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
                      @id={{tab.id}}
                      @disabled={{tab.disabled}}
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
                      @iconClasses={{classNames
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
                          @id={{tab.id}}
                          @disabled={{tab.disabled}}
                          @isSelected={{tab.isSelected}}
                          @href={{tab.href}}
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
                  class={{classNames
                    "euiPageHeaderContent__rightSideItems"
                    @rightSideGroupProps.className
                  }}
                >
                  {{yield
                    (component EuiFlexItem grow=false)
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
