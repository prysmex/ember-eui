import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

import style from 'ember-style-modifier/modifiers/style';
// import { tabbable } from 'tabbable';
// import {
//   anchorPositionMapping,
//   displayMapping
// } from '../../utils/css-mappings/eui-popover';
// import { paddingSizeMapping } from '../../utils/css-mappings/eui-panel';
// import { scheduleOnce, later, cancel } from '@ember/runloop';
// import { assert } from '@ember/debug';
// import { htmlSafe } from '@ember/template';
import { and, eq,or } from 'ember-truth-helpers';

// import { action } from '@ember/object';
// import { tracked } from '@glimmer/tracking';
// import {
//   getTransitionTimings,
//   getWaitDuration,
//   performOnFrame
// } from '../../utils/transition';
// import { findPopoverPosition, getElementZIndex } from '../../utils/popover';
// import { EuiPopoverPosition } from '../../utils/popover/types';
// import { cascadingMenuKeys } from '../../utils/accesibility';
import argOrDefault, { argOrDefaultDecorator } from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import inlineStyles from '../helpers/inline-styles';
import useIsWithinBreakpoints from '../modifiers/use-is-within-breakpoints';
import EuiBottomBar from './eui-bottom-bar.gts';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiPage from './eui-page.gts';
import EuiPageBody from './eui-page-body.gts';
import EuiPageContent from './eui-page-content.gts';
import EuiPageContentBody from './eui-page-content-body.gts';
import EuiPageHeader from './eui-page-header.gts';
import EuiPageSideBar from './eui-page-side-bar.gts';

import type { EuiBreakpointSize } from '../utils/breakpoint';
import type { EuiButtomBarArgs } from './eui-bottom-bar.gts';
import type { EuiPageBodySignature } from './eui-page-body.gts';
import type { EuiPageContentSignature } from './eui-page-content.gts';
import type { EuiPageContentBodySignature } from './eui-page-content-body.gts';
import type { EuiPageHeaderSignature } from './eui-page-header.gts';
import type { EuiPageSideBarSignature } from './eui-page-side-bar.gts';

export const TEMPLATES = [
  'default',
  'centeredBody',
  'centeredContent',
  'empty'
] as const;

const BREAKPOINTS: EuiBreakpointSize[] = ['m', 'l', 'xl'];

interface NormalProps {
  className?: string;
}

export type EuiPageTemplateProps = {
  template?: (typeof TEMPLATES)[number];

  pageBodyProps: NormalProps & EuiPageBodySignature['Args'];
  pageContentProps: NormalProps & EuiPageContentSignature['Args'];
  pageContentBodyProps: NormalProps & EuiPageContentBodySignature['Args'];

  pageHeader: NormalProps & EuiPageHeaderSignature['Args'];

  pageSideBarProps: NormalProps & EuiPageSideBarSignature['Args'];

  /**
   * Adds a bottom bar to the page template
   */
  bottomBar?: any;

  /**
   * Adds a bottom bar to the page template
   */
  hasBottomBarBlock?: boolean;

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

  restrictWidth?: boolean | number | string;

  grow?: boolean;
  paddingSize?: EuiPageSideBarSignature['Args']['paddingSize'];
  hasPageSideBarBlock?: boolean;
  hasPageHeaderPageTitleBlock?: boolean;
  hasPageHeaderDefaultBlock?: boolean;
  hasPageHeaderRightSideItemsBlock?: boolean;
  hasPageHeaderDescriptionBlock?: boolean;
  hasPageHeader?: boolean;
  hasPageContent?: boolean;
  hasPageContentBody?: boolean;
};

export interface EuiPageTemplateSignature {
  Element: HTMLElement;
  Args: EuiPageTemplateProps;
  Blocks: {
    default: [];
    pageSideBar: [];
    pageHeaderPageTitle: [];
    pageHeaderDefault: [];
    pageHeaderDescription: [];
    pageHeaderRightSideItems: EuiPageHeaderSignature['Blocks']['rightSideItems'];
    bottomBar: [];
  };
}

export default class EuiPageTemplate extends Component<EuiPageTemplateSignature> {
  // Defaults
  @argOrDefaultDecorator(false) fullHeight!: boolean;
  @argOrDefaultDecorator('default') template!: (typeof TEMPLATES)[number];

  @tracked isWithinBreakpoints = false;

  setIsWithinBreakpoints = (value: boolean) => {
    this.isWithinBreakpoints = value;
  };

  get minHeight() {
    const minHeight = this.args.minHeight ?? 460;

    if (typeof this.args.minHeight === 'number') {
      return `${minHeight}px`;
    }

    return minHeight;
  }

  get restrictWidth() {
    const width = this.args.restrictWidth ?? true;

    if (typeof this.args.restrictWidth === 'number') {
      return `${width}px`;
    }

    return width;
  }

  get classes() {
    return `euiPageTemplate ${this.fullHeightClass}`;
  }

  get fullHeightClass() {
    return this.fullHeight && this.canFullHeight ? 'eui-fullHeight ' : '';
  }

  get yScrollClass() {
    return this.fullHeight && this.canFullHeight ? 'eui-yScroll ' : '';
  }

  get canFullHeight() {
    return (
      this.isWithinBreakpoints &&
      (this.template === 'default' || this.template === 'empty')
    );
  }

  get pageBodyPropsClass() {
    return `${this.fullHeightClass} ${this.args.pageBodyProps?.className}`;
  }

  get pageContentPropsClass() {
    return `${this.yScrollClass} ${this.args.pageContentProps?.className}`;
  }

  get pageContentBodyPropsClass() {
    return `${this.fullHeightClass} ${this.args.pageContentBodyProps?.className}`;
  }

  <template>
    {{#let
      (argOrDefault @grow true)
      (argOrDefault @paddingSize "l")
      (and (argOrDefault @hasBottomBarBlock true) (has-block "bottomBar"))
      (and (argOrDefault @hasPageSideBarBlock true) (has-block "pageSideBar"))
      (and
        (argOrDefault @hasPageHeaderPageTitleBlock true)
        (has-block "pageHeaderPageTitle")
      )
      (and
        (argOrDefault @hasPageHeaderDefaultBlock true)
        (has-block "pageHeaderDefault")
      )
      (and
        (argOrDefault @hasPageHeaderRightSideItemsBlock true)
        (has-block "pageHeaderRightSideItems")
      )
      (and
        (argOrDefault @hasPageHeaderDescriptionBlock true)
        (has-block "pageHeaderDescription")
      )
      (modifier
        useIsWithinBreakpoints
        sizes=BREAKPOINTS
        isActive=true
        setIsWithinBreakpointsValue=this.setIsWithinBreakpoints
      )
      as |grow paddingSize hasBottomBarBlock hasPageSideBarBlock hasPageHeaderPageTitleBlock hasPageHeaderDefaultBlock hasPageHeaderRightSideItemsBlock hasPageHeaderDescriptionBlock isWithinBreakpointsModifier|
    }}
      {{#let
        (or
          @pageHeader
          hasPageHeaderPageTitleBlock
          hasPageHeaderDefaultBlock
          hasPageHeaderRightSideItemsBlock
          hasPageHeaderDescriptionBlock
        )
        as |hasPageHeader|
      }}
        {{#if (eq this.template "centeredBody")}}
          {{#if hasPageSideBarBlock}}
            <EuiPage
              class={{this.classes}}
              @paddingSize="none"
              @grow={{grow}}
              {{isWithinBreakpointsModifier}}
              {{style (inlineStyles min-height=this.minHeight)}}
              ...attributes
            >
              <EuiPageSideBar
                class={{@pageSideBarProps.className}}
                @sticky={{true}}
                @paddingSize={{paddingSize}}
              >
                {{yield to="pageSideBar"}}
              </EuiPageSideBar>
              <EuiPageBody
                class={{this.pageBodyPropsClass}}
                @paddingSize={{paddingSize}}
              >
                <EuiPageHeader
                  {{!@glint-expect-error}}
                  @restrictWidth={{this.restrictWidth}}
                  @responsive={{@pageHeader.responsive}}
                  @iconType={{@pageHeader.iconType}}
                  @tabs={{@pageHeader.tabs}}
                  @pageTitle={{@pageHeader.pageTitle}}
                  @description={{@pageHeader.description}}
                  @hasPageTitleBlock={{hasPageHeaderPageTitleBlock}}
                  @hasDefaultBlock={{hasPageHeaderDefaultBlock}}
                  @hasDescriptionBlock={{hasPageHeaderDescriptionBlock}}
                  @hasRightSideItemsBlock={{hasPageHeaderRightSideItemsBlock}}
                >
                  <:pageTitle>
                    {{yield to="pageHeaderPageTitle"}}
                  </:pageTitle>
                  <:default>
                    {{yield to="pageHeaderDefault"}}
                  </:default>
                  <:description>
                    {{yield to="pageHeaderDescription"}}
                  </:description>
                  <:rightSideItems as |item|>
                    {{yield item to="pageHeaderRightSideItems"}}
                  </:rightSideItems>
                </EuiPageHeader>

                <EuiPageContent
                  class={{this.pageContentPropsClass}}
                  @verticalPosition="center"
                  @horizontalPosition="center"
                  @paddingSize={{paddingSize}}
                >
                  <EuiPageContentBody
                    class={{this.pageContentBodyPropsClass}}
                    {{!@glint-expect-error}}
                    @restrictWidth={{this.restrictWidth}}
                  >
                    {{#if (and this.canFullHeight this.fullHeight)}}
                      <EuiFlexGroup
                        class="eui-fullHeight"
                        @gutterSize="none"
                        @direction="column"
                        @responsive={{false}}
                      >
                        <EuiFlexItem
                          class={{classNames
                            (if (eq this.fullHeight true) "eui-yScroll")
                            (if
                              (eq this.fullHeight "noscroll") "eui-fullHeight"
                            )
                          }}
                          @grow={{true}}
                        >
                          {{yield to="default"}}
                        </EuiFlexItem>
                      </EuiFlexGroup>
                    {{else}}
                      {{yield to="default"}}
                    {{/if}}
                  </EuiPageContentBody>
                </EuiPageContent>
              </EuiPageBody>
            </EuiPage>
          {{else}}
            <EuiPage
              class={{this.classes}}
              @paddingSize={{paddingSize}}
              @grow={{grow}}
              {{isWithinBreakpointsModifier}}
              {{style (inlineStyles min-height=this.minHeight)}}
              ...attributes
            >
              <EuiPageBody
                class={{this.pageBodyPropsClass}}
                {{!@glint-expect-error}}
                @restrictWidth={{this.restrictWidth}}
              >
                {{#if hasPageHeader}}
                  <EuiPageHeader
                    @restrictWidth={{false}}
                    @bottomBorder={{@pageHeader.bottomBorder}}
                    @paddingSize="none"
                    @responsive={{@pageHeader.responsive}}
                    @iconType={{@pageHeader.iconType}}
                    @tabs={{@pageHeader.tabs}}
                    @pageTitle={{@pageHeader.pageTitle}}
                    @description={{@pageHeader.description}}
                    @hasPageTitleBlock={{hasPageHeaderPageTitleBlock}}
                    @hasDefaultBlock={{hasPageHeaderDefaultBlock}}
                    @hasDescriptionBlock={{hasPageHeaderDescriptionBlock}}
                    @hasRightSideItemsBlock={{hasPageHeaderRightSideItemsBlock}}
                  >
                    <:pageTitle>
                      {{yield to="pageHeaderPageTitle"}}
                    </:pageTitle>
                    <:default>
                      {{yield to="pageHeaderDefault"}}
                    </:default>
                    <:description>
                      {{yield to="pageHeaderDescription"}}
                    </:description>
                    <:rightSideItems as |item|>
                      {{yield item to="pageHeaderRightSideItems"}}
                    </:rightSideItems>
                  </EuiPageHeader>
                {{/if}}
                <EuiPageBody>
                  <EuiPageContent
                    class={{this.pageContentPropsClass}}
                    @verticalPosition="center"
                    @horizontalPosition="center"
                    @hasBorder={{@pageContentProps.hasBorder}}
                    @hasShadow={{@pageContentProps.hasShadow}}
                    @color={{@pageContentProps.color}}
                    @borderRadius={{@pageContentProps.borderRadius}}
                    @grow={{@pageContentProps.grow}}
                    @role={{@pageContentProps.role}}
                    @paddingSize={{paddingSize}}
                  >
                    <EuiPageContentBody
                      class={{this.pageContentBodyPropsClass}}
                      @paddingSize="none"
                      {{!@glint-expect-error}}
                      @restrictWidth={{this.restrictWidth}}
                    >
                      {{#if (and this.canFullHeight this.fullHeight)}}
                        <EuiFlexGroup
                          class="eui-fullHeight"
                          @gutterSize="none"
                          @direction="column"
                          @responsive={{false}}
                        >
                          <EuiFlexItem
                            class={{classNames
                              (if (eq this.fullHeight true) "eui-yScroll")
                              (if
                                (eq this.fullHeight "noscroll") "eui-fullHeight"
                              )
                            }}
                            @grow={{true}}
                          >
                            {{yield to="default"}}
                          </EuiFlexItem>
                        </EuiFlexGroup>
                      {{else}}
                        {{yield to="default"}}
                      {{/if}}
                    </EuiPageContentBody>
                  </EuiPageContent>
                </EuiPageBody>
              </EuiPageBody>
            </EuiPage>
          {{/if}}
        {{else if (eq this.template "centeredContent")}}
          {{#if hasPageSideBarBlock}}
            <EuiPage
              class={{this.classes}}
              @paddingSize="none"
              @grow={{grow}}
              {{isWithinBreakpointsModifier}}
              {{style (inlineStyles min-height=this.minHeight)}}
              ...attributes
            >
              <EuiPageSideBar
                class={{@pageSideBarProps.className}}
                @sticky={{true}}
                @paddingSize={{paddingSize}}
              >
                {{yield to="pageSideBar"}}
              </EuiPageSideBar>
              <EuiPageBody
                @panelled={{true}}
                @paddingSize={{paddingSize}}
                class={{this.pageBodyPropsClass}}
              >
                {{#if hasPageHeader}}
                  <EuiPageHeader
                    {{!@glint-expect-error}}
                    @restrictWidth={{this.restrictWidth}}
                    @paddingSize={{@pageHeader.paddingSize}}
                    @responsive={{@pageHeader.responsive}}
                    @iconType={{@pageHeader.iconType}}
                    @tabs={{@pageHeader.tabs}}
                    @pageTitle={{@pageHeader.pageTitle}}
                    @description={{@pageHeader.description}}
                    @hasPageTitleBlock={{hasPageHeaderPageTitleBlock}}
                    @hasDefaultBlock={{hasPageHeaderDefaultBlock}}
                    @hasDescriptionBlock={{hasPageHeaderDescriptionBlock}}
                    @hasRightSideItemsBlock={{hasPageHeaderRightSideItemsBlock}}
                  >
                    <:pageTitle>
                      {{yield to="pageHeaderPageTitle"}}
                    </:pageTitle>
                    <:default>
                      {{yield to="pageHeaderDefault"}}
                    </:default>
                    <:description>
                      {{yield to="pageHeaderDescription"}}
                    </:description>
                    <:rightSideItems as |item|>
                      {{yield item to="pageHeaderRightSideItems"}}
                    </:rightSideItems>
                  </EuiPageHeader>
                {{/if}}
                <EuiPageContent
                  @verticalPosition="center"
                  @horizontalPosition="center"
                  @hasShadow={{false}}
                  @color="subdued"
                  @paddingSize={{paddingSize}}
                  class={{this.pageContentPropsClass}}
                >
                  <EuiPageContentBody
                    {{!@glint-expect-error}}
                    @restrictWidth={{this.restrictWidth}}
                    class={{this.pageContentBodyPropsClass}}
                  >
                    {{#if (and this.canFullHeight this.fullHeight)}}
                      <EuiFlexGroup
                        class="eui-fullHeight"
                        @gutterSize="none"
                        @direction="column"
                        @responsive={{false}}
                      >
                        <EuiFlexItem
                          class={{classNames
                            (if (eq this.fullHeight true) "eui-yScroll")
                            (if
                              (eq this.fullHeight "noscroll") "eui-fullHeight"
                            )
                          }}
                          @grow={{true}}
                        >
                          {{yield to="default"}}
                        </EuiFlexItem>
                      </EuiFlexGroup>
                    {{else}}
                      {{yield to="default"}}
                    {{/if}}
                  </EuiPageContentBody>
                </EuiPageContent>
              </EuiPageBody>
            </EuiPage>
          {{else}}
            <EuiPage
              class={{this.classes}}
              @paddingSize="none"
              @grow={{grow}}
              {{isWithinBreakpointsModifier}}
              {{style (inlineStyles min-height=this.minHeight)}}
              ...attributes
            >
              <EuiPageBody class={{this.pageBodyPropsClass}}>
                {{#if hasPageHeader}}
                  <EuiPageHeader
                    {{!@glint-expect-error}}
                    @restrictWidth={{this.restrictWidth}}
                    @paddingSize={{paddingSize}}
                    @responsive={{@pageHeader.responsive}}
                    @iconType={{@pageHeader.iconType}}
                    @tabs={{@pageHeader.tabs}}
                    @pageTitle={{@pageHeader.pageTitle}}
                    @description={{@pageHeader.description}}
                    @hasPageTitleBlock={{hasPageHeaderPageTitleBlock}}
                    @hasDefaultBlock={{hasPageHeaderDefaultBlock}}
                    @hasDescriptionBlock={{hasPageHeaderDescriptionBlock}}
                    @hasRightSideItemsBlock={{hasPageHeaderRightSideItemsBlock}}
                  >
                    <:pageTitle>
                      {{yield to="pageHeaderPageTitle"}}
                    </:pageTitle>
                    <:default>
                      {{yield to="pageHeaderDefault"}}
                    </:default>
                    <:description>
                      {{yield to="pageHeaderDescription"}}
                    </:description>
                    <:rightSideItems as |item|>
                      {{yield item to="pageHeaderRightSideItems"}}
                    </:rightSideItems>
                  </EuiPageHeader>
                {{/if}}
                {{!template-lint-disable}}
                <EuiPageContent
                  role={{null}}
                  @borderRadius="none"
                  @hasShadow={{false}}
                  @paddingSize={{paddingSize}}
                  style="display: flex"
                >
                  {{!template-lint-enable}}
                  <EuiPageContent
                    @verticalPosition="center"
                    @horizontalPosition="center"
                    @hasShadow={{false}}
                    @color="subdued"
                    @paddingSize={{paddingSize}}
                    class={{this.pageContentPropsClass}}
                  >
                    <EuiPageContentBody
                      {{!@glint-expect-error}}
                      @restrictWidth={{this.restrictWidth}}
                      class={{this.pageContentBodyPropsClass}}
                    >
                      {{#if (and this.canFullHeight this.fullHeight)}}
                        <EuiFlexGroup
                          class="eui-fullHeight"
                          @gutterSize="none"
                          @direction="column"
                          @responsive={{false}}
                        >
                          <EuiFlexItem
                            class={{classNames
                              (if (eq this.fullHeight true) "eui-yScroll")
                              (if
                                (eq this.fullHeight "noscroll") "eui-fullHeight"
                              )
                            }}
                            @grow={{true}}
                          >
                            {{yield to="default"}}
                          </EuiFlexItem>
                        </EuiFlexGroup>
                      {{else}}
                        {{yield to="default"}}
                      {{/if}}
                    </EuiPageContentBody>
                  </EuiPageContent>

                </EuiPageContent>
              </EuiPageBody>
            </EuiPage>
          {{/if}}
        {{else if (eq this.template "empty")}}
          {{#if hasPageSideBarBlock}}
            <EuiPage
              class={{this.classes}}
              @paddingSize="none"
              @grow={{grow}}
              {{isWithinBreakpointsModifier}}
              {{style (inlineStyles min-height=this.minHeight)}}
              ...attributes
            >
              <EuiPageSideBar @sticky={{true}} @paddingSize={{paddingSize}}>
                {{yield to="pageSideBar"}}
              </EuiPageSideBar>
              <EuiPageBody
                @paddingSize={{paddingSize}}
                class={{this.pageBodyPropsClass}}
              >
                {{#if hasPageHeader}}
                  <EuiPageHeader
                    {{!@glint-expect-error}}
                    @restrictWidth={{this.restrictWidth}}
                    @paddingSize={{@pageHeader.paddingSize}}
                    @responsive={{@pageHeader.responsive}}
                    @iconType={{@pageHeader.iconType}}
                    @tabs={{@pageHeader.tabs}}
                    @pageTitle={{@pageHeader.pageTitle}}
                    @description={{@pageHeader.description}}
                    @hasPageTitleBlock={{hasPageHeaderPageTitleBlock}}
                    @hasDefaultBlock={{hasPageHeaderDefaultBlock}}
                    @hasDescriptionBlock={{hasPageHeaderDescriptionBlock}}
                    @hasRightSideItemsBlock={{hasPageHeaderRightSideItemsBlock}}
                  >
                    <:pageTitle>
                      {{yield to="pageHeaderPageTitle"}}
                    </:pageTitle>
                    <:default>
                      {{yield to="pageHeaderDefault"}}
                    </:default>
                    <:description>
                      {{yield to="pageHeaderDescription"}}
                    </:description>
                    <:rightSideItems as |item|>
                      {{yield item to="pageHeaderRightSideItems"}}
                    </:rightSideItems>
                  </EuiPageHeader>
                {{/if}}
                <EuiPageContent
                  @hasBorder={{false}}
                  @hasShadow={{false}}
                  @paddingSize="none"
                  @color="transparent"
                  @borderRadius="none"
                  class={{this.pageContentPropsClass}}
                >
                  <EuiPageContentBody
                    {{!@glint-expect-error}}
                    @restrictWidth={{this.restrictWidth}}
                    class={{this.pageContentBodyPropsClass}}
                  >
                    {{#if (and this.canFullHeight this.fullHeight)}}
                      <EuiFlexGroup
                        class="eui-fullHeight"
                        @gutterSize="none"
                        @direction="column"
                        @responsive={{false}}
                      >
                        <EuiFlexItem
                          class={{classNames
                            (if (eq this.fullHeight true) "eui-yScroll")
                            (if
                              (eq this.fullHeight "noscroll") "eui-fullHeight"
                            )
                          }}
                          @grow={{true}}
                        >
                          {{yield to="default"}}
                        </EuiFlexItem>
                      </EuiFlexGroup>
                    {{else}}
                      {{yield to="default"}}
                    {{/if}}
                  </EuiPageContentBody>
                </EuiPageContent>
              </EuiPageBody>
            </EuiPage>
          {{else}}
            <EuiPage
              class={{this.classes}}
              @paddingSize={{paddingSize}}
              @grow={{grow}}
              {{isWithinBreakpointsModifier}}
              {{style (inlineStyles min-height=this.minHeight)}}
              ...attributes
            >
              <EuiPageBody
                {{!@glint-expect-error}}
                @restrictWidth={{this.restrictWidth}}
                class={{this.pageBodyPropsClass}}
              >
                {{#if hasPageHeader}}
                  <EuiPageHeader
                    @bottomBorder={{@pageHeader.bottomBorder}}
                    @restrictWidth={{false}}
                    @paddingSize={{@pageHeader.paddingSize}}
                    @responsive={{@pageHeader.responsive}}
                    @iconType={{@pageHeader.iconType}}
                    @tabs={{@pageHeader.tabs}}
                    @pageTitle={{@pageHeader.pageTitle}}
                    @description={{@pageHeader.description}}
                    @hasPageTitleBlock={{hasPageHeaderPageTitleBlock}}
                    @hasDefaultBlock={{hasPageHeaderDefaultBlock}}
                    @hasDescriptionBlock={{hasPageHeaderDescriptionBlock}}
                    @hasRightSideItemsBlock={{hasPageHeaderRightSideItemsBlock}}
                  >
                    <:pageTitle>
                      {{yield to="pageHeaderPageTitle"}}
                    </:pageTitle>
                    <:default>
                      {{yield to="pageHeaderDefault"}}
                    </:default>
                    <:description>
                      {{yield to="pageHeaderDescription"}}
                    </:description>
                    <:rightSideItems as |item|>
                      {{yield item to="pageHeaderRightSideItems"}}
                    </:rightSideItems>
                  </EuiPageHeader>
                {{/if}}
                <EuiPageContent
                  @hasBorder={{false}}
                  @hasShadow={{false}}
                  @paddingSize="none"
                  @color="transparent"
                  @borderRadius="none"
                  class={{this.pageContentPropsClass}}
                >
                  <EuiPageContentBody
                    @restrictWidth={{false}}
                    class={{this.pageContentBodyPropsClass}}
                  >
                    {{#if (and this.canFullHeight this.fullHeight)}}
                      <EuiFlexGroup
                        class="eui-fullHeight"
                        @gutterSize="none"
                        @direction="column"
                        @responsive={{false}}
                      >
                        <EuiFlexItem
                          class={{classNames
                            (if (eq this.fullHeight true) "eui-yScroll")
                            (if
                              (eq this.fullHeight "noscroll") "eui-fullHeight"
                            )
                          }}
                          @grow={{true}}
                        >
                          {{yield to="default"}}
                        </EuiFlexItem>
                      </EuiFlexGroup>
                    {{else}}
                      {{yield to="default"}}
                    {{/if}}
                  </EuiPageContentBody>
                </EuiPageContent>
              </EuiPageBody>
            </EuiPage>
          {{/if}}
        {{else}}
          {{#if hasPageSideBarBlock}}
            <EuiPage
              class={{this.classes}}
              @paddingSize="none"
              @grow={{grow}}
              {{isWithinBreakpointsModifier}}
              {{style (inlineStyles min-height=this.minHeight)}}
              ...attributes
            >
              <EuiPageSideBar
                class={{@pageSideBarProps.className}}
                @sticky={{true}}
                @paddingSize={{paddingSize}}
              >
                {{yield to="pageSideBar"}}
              </EuiPageSideBar>
              <EuiPageBody
                @panelled={{true}}
                @paddingSize="none"
                class={{this.pageBodyPropsClass}}
              >
                <EuiPageBody
                  class={{this.pageBodyPropsClass}}
                  @paddingSize={{paddingSize}}
                  @tagName="div"
                >
                  {{#if hasPageHeader}}
                    <EuiPageHeader
                      @bottomBorder={{@pageHeader.bottomBorder}}
                      {{!@glint-expect-error}}
                      @restrictWidth={{this.restrictWidth}}
                      @paddingSize={{@pageHeader.paddingSize}}
                      @responsive={{@pageHeader.responsive}}
                      @iconType={{@pageHeader.iconType}}
                      @tabs={{@pageHeader.tabs}}
                      @pageTitle={{@pageHeader.pageTitle}}
                      @description={{@pageHeader.description}}
                      @hasPageTitleBlock={{hasPageHeaderPageTitleBlock}}
                      @hasDefaultBlock={{hasPageHeaderDefaultBlock}}
                      @hasDescriptionBlock={{hasPageHeaderDescriptionBlock}}
                      @hasRightSideItemsBlock={{hasPageHeaderRightSideItemsBlock}}
                    >
                      <:pageTitle>
                        {{yield to="pageHeaderPageTitle"}}
                      </:pageTitle>
                      <:default>
                        {{yield to="pageHeaderDefault"}}
                      </:default>
                      <:description>
                        {{yield to="pageHeaderDescription"}}
                      </:description>
                      <:rightSideItems as |item|>
                        {{yield item to="pageHeaderRightSideItems"}}
                      </:rightSideItems>
                    </EuiPageHeader>
                  {{/if}}
                  <EuiPageContent
                    @hasShadow={{false}}
                    @hasBorder={{false}}
                    @color="transparent"
                    @borderRadius="none"
                    @paddingSize="none"
                    class={{this.pageContentPropsClass}}
                  >
                    <EuiPageContentBody
                      {{!@glint-expect-error}}
                      @restrictWidth={{this.restrictWidth}}
                      class={{this.pageContentBodyPropsClass}}
                    >
                      {{#if (and this.canFullHeight this.fullHeight)}}
                        <EuiFlexGroup
                          class="eui-fullHeight"
                          @gutterSize="none"
                          @direction="column"
                          @responsive={{false}}
                        >
                          <EuiFlexItem
                            class={{classNames
                              (if (eq this.fullHeight true) "eui-yScroll")
                              (if
                                (eq this.fullHeight "noscroll") "eui-fullHeight"
                              )
                            }}
                            @grow={{true}}
                          >
                            {{yield to="default"}}
                          </EuiFlexItem>
                        </EuiFlexGroup>
                      {{else}}
                        {{yield to="default"}}
                      {{/if}}
                    </EuiPageContentBody>
                  </EuiPageContent>
                </EuiPageBody>
                {{#if hasBottomBarBlock}}
                  <EuiBottomBar
                    @paddingSize={{paddingSize}}
                    @position={{if
                      (and this.canFullHeight this.fullHeight)
                      "static"
                      "sticky"
                    }}
                  >
                    <EuiPageContentBody
                      @paddingSize="none"
                      {{!@glint-expect-error}}
                      @restrictWidth={{this.restrictWidth}}
                    >
                      {{yield to="bottomBar"}}
                    </EuiPageContentBody>
                  </EuiBottomBar>
                {{/if}}
              </EuiPageBody>
            </EuiPage>
          {{else}}
            <EuiPage
              class={{this.classes}}
              @paddingSize="none"
              @grow={{grow}}
              {{isWithinBreakpointsModifier}}
              {{style (inlineStyles min-height=this.minHeight)}}
              ...attributes
            >
              <EuiPageBody class={{this.pageBodyPropsClass}}>
                {{#if hasPageHeader}}
                  <EuiPageHeader
                    {{!@glint-expect-error}}
                    @restrictWidth={{this.restrictWidth}}
                    @bottomBorder={{@pageHeader.bottomBorder}}
                    @paddingSize={{paddingSize}}
                    @responsive={{@pageHeader.responsive}}
                    @iconType={{@pageHeader.iconType}}
                    @tabs={{@pageHeader.tabs}}
                    @pageTitle={{@pageHeader.pageTitle}}
                    @description={{@pageHeader.description}}
                    @hasPageTitleBlock={{hasPageHeaderPageTitleBlock}}
                    @hasDefaultBlock={{hasPageHeaderDefaultBlock}}
                    @hasDescriptionBlock={{hasPageHeaderDescriptionBlock}}
                    @hasRightSideItemsBlock={{hasPageHeaderRightSideItemsBlock}}
                  >
                    <:pageTitle>
                      {{yield to="pageHeaderPageTitle"}}
                    </:pageTitle>
                    <:default>
                      {{yield to="pageHeaderDefault"}}
                    </:default>
                    <:description>
                      {{yield to="pageHeaderDescription"}}
                    </:description>
                    <:rightSideItems as |item|>
                      {{yield item to="pageHeaderRightSideItems"}}
                    </:rightSideItems>
                  </EuiPageHeader>
                {{/if}}
                <EuiPageContent
                  @hasBorder={{if hasPageHeader false}}
                  @hasShadow={{false}}
                  @paddingSize="none"
                  @color="plain"
                  @borderRadius="none"
                  class={{this.pageContentPropsClass}}
                >
                  <EuiPageContentBody
                    {{!@glint-expect-error}}
                    @restrictWidth={{this.restrictWidth}}
                    @paddingSize={{paddingSize}}
                    class={{this.pageContentBodyPropsClass}}
                  >
                    {{#if (and this.canFullHeight this.fullHeight)}}
                      <EuiFlexGroup
                        class="eui-fullHeight"
                        @gutterSize="none"
                        @direction="column"
                        @responsive={{false}}
                      >
                        <EuiFlexItem
                          class={{classNames
                            (if (eq this.fullHeight true) "eui-yScroll")
                            (if
                              (eq this.fullHeight "noscroll") "eui-fullHeight"
                            )
                          }}
                          @grow={{true}}
                        >
                          {{yield to="default"}}
                        </EuiFlexItem>
                      </EuiFlexGroup>
                    {{else}}
                      {{yield to="default"}}
                    {{/if}}
                  </EuiPageContentBody>
                </EuiPageContent>
                {{#if hasBottomBarBlock}}
                  <EuiBottomBar
                    @paddingSize={{paddingSize}}
                    @position={{if
                      (and this.canFullHeight this.fullHeight)
                      "static"
                      "sticky"
                    }}
                  >
                    <EuiPageContentBody
                      @paddingSize="none"
                      {{!@glint-expect-error}}
                      @restrictWidth={{this.restrictWidth}}
                    >
                      {{yield to="bottomBar"}}
                    </EuiPageContentBody>
                  </EuiBottomBar>
                {{/if}}
              </EuiPageBody>
            </EuiPage>
          {{/if}}
        {{/if}}
      {{/let}}
    {{/let}}
  </template>
}
