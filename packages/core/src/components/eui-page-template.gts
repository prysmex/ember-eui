import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

import style from 'ember-style-modifier/modifiers/style';
// import { tabbable } from 'tabbable';
// import {
//   anchorPositionMapping,
//   displayMapping
// } from '../../utils/css-mappings/eui-popover.ts';
// import { paddingSizeMapping } from '../../utils/css-mappings/eui-panel.ts';
// import { scheduleOnce, later, cancel } from '@ember/runloop';
// import { assert } from '@ember/debug';
// import { htmlSafe } from '@ember/template';
import { and, eq, or } from 'ember-truth-helpers';

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
import argOrDefault, {
  argOrDefaultDecorator
} from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import inlineStyles from '../helpers/inline-styles.ts';
import useIsWithinBreakpoints from '../modifiers/use-is-within-breakpoints.ts';
import EuiBottomBar from './eui-bottom-bar.gts';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiPage from './eui-page.gts';
import EuiPageBody from './eui-page-body.gts';
import EuiPageContent from './eui-page-content.gts';
import EuiPageContentBody from './eui-page-content-body.gts';
import EuiPageHeader from './eui-page-header.gts';
import EuiPageSideBar from './eui-page-side-bar.gts';

import type { EuiBreakpointSize } from '../utils/breakpoint.ts';
import type { EuiButtomBarArgs } from './eui-bottom-bar';
import type { EuiPageBodySignature } from './eui-page-body';
import type { EuiPageContentSignature } from './eui-page-content';
import type { EuiPageContentBodySignature } from './eui-page-content-body';
import type { EuiPageHeaderSignature } from './eui-page-header';
import type { EuiPageSideBarSignature } from './eui-page-side-bar';

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
  /**
   * Layout: `'default'` (header and content), `'centeredBody'` (content
   * panel centered in the page), `'centeredContent'` (content centered in
   * the body, e.g. an empty prompt) or `'empty'` (no panels).
   * Defaults to `'default'`.
   */
  template?: (typeof TEMPLATES)[number];

  /** Props for the `EuiPageBody`: `{ className }`. */
  pageBodyProps: NormalProps & EuiPageBodySignature['Args'];
  /**
   * Props for the `EuiPageContent`: `{ className, hasBorder, hasShadow,
   * color, borderRadius, grow, role }`.
   */
  pageContentProps: NormalProps & EuiPageContentSignature['Args'];
  /** Props for the `EuiPageContentBody`: `{ className }`. */
  pageContentBodyProps: NormalProps & EuiPageContentBodySignature['Args'];

  /**
   * The page header, as EuiPageHeader args: `{ pageTitle, iconType,
   * description, tabs, responsive, bottomBorder }`. Use the
   * `<:pageHeader…>` blocks for its title, description and actions.
   */
  pageHeader: NormalProps & EuiPageHeaderSignature['Args'];

  /** Props for the `EuiPageSideBar`: `{ className }`. */
  pageSideBarProps: NormalProps & EuiPageSideBarSignature['Args'];

  /** @deprecated Has no effect, use the `<:bottomBar>` block. */
  bottomBar?: any;

  /** @private Render the `<:bottomBar>` block. Defaults to `true`. */
  hasBottomBarBlock?: boolean;

  /** @deprecated Has no effect. */
  bottomBarProps?: EuiButtomBarArgs;
  /**
   * Stretches the page to the window's height and scrolls the content
   * instead of the page (templates `'default'` and `'empty'`, on medium
   * screens and up). Defaults to `false`.
   */
  fullHeight?: boolean;
  /** Minimum height of the page, in px or any CSS height. Defaults to `460`. */
  minHeight?: number;

  /**
   * Max width of the header and content: `true` for EUI's default, a number
   * in px or any CSS width. Defaults to `true`.
   */
  restrictWidth?: boolean | number | string;

  /** Fills the window's height. Defaults to `true`. */
  grow?: boolean;
  /** Padding of the page's sections: `'none'`, `'s'`, `'m'` or `'l'`. Defaults to `'l'`. */
  paddingSize?: EuiPageSideBarSignature['Args']['paddingSize'];
  /** @private Render the `<:pageSideBar>` block. Defaults to `true`. */
  hasPageSideBarBlock?: boolean;
  /** @private Render the `<:pageHeaderPageTitle>` block. Defaults to `true`. */
  hasPageHeaderPageTitleBlock?: boolean;
  /** @private Render the `<:pageHeaderDefault>` block. Defaults to `true`. */
  hasPageHeaderDefaultBlock?: boolean;
  /** @private Render the `<:pageHeaderRightSideItems>` block. Defaults to `true`. */
  hasPageHeaderRightSideItemsBlock?: boolean;
  /** @private Render the `<:pageHeaderDescription>` block. Defaults to `true`. */
  hasPageHeaderDescriptionBlock?: boolean;
  /** @deprecated Has no effect. */
  hasPageHeader?: boolean;
  /** @deprecated Has no effect. */
  hasPageContent?: boolean;
  /** @deprecated Has no effect. */
  hasPageContentBody?: boolean;
};

/**
 * A whole page layout in one component: side bar, header, content and
 * bottom bar, arranged by `@template`.
 */
export interface EuiPageTemplateSignature {
  Element: HTMLElement;
  Args: EuiPageTemplateProps;
  Blocks: {
    /** The page's content. */
    default: [];
    /** A side bar, e.g. an `EuiSideNav`. */
    pageSideBar: [];
    /** The header's title, instead of `pageHeader.pageTitle`. */
    pageHeaderPageTitle: [];
    /** Extra header content. */
    pageHeaderDefault: [];
    /** The header's description. */
    pageHeaderDescription: [];
    /** Header actions; yields an item to wrap each in, see EuiPageHeader. */
    pageHeaderRightSideItems: EuiPageHeaderSignature['Blocks']['rightSideItems'];
    /** Content of a bottom bar (EuiBottomBar), e.g. save/cancel buttons. */
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
              <EuiPageSideBar
                class={{@pageSideBarProps.className}}
                @sticky={{true}}
                @paddingSize={{paddingSize}}
              >
                {{yield to="pageSideBar"}}
              </EuiPageSideBar>
              <EuiPageBody
                @paddingSize={{paddingSize}}
                class={{this.pageBodyPropsClass}}
              >
                {{#if hasPageHeader}}
                  <EuiPageHeader
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
