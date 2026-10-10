import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

import style from 'ember-style-modifier/modifiers/style';
import { and, eq, or } from 'ember-truth-helpers';

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

  /** Props for the `EuiPageBody`, overriding layout defaults. */
  pageBodyProps?: NormalProps & EuiPageBodySignature['Args'];
  /**
   * Props for the `EuiPageContent`: `{ className, hasBorder, hasShadow,
   * color, borderRadius, grow, role }`.
   */
  pageContentProps?: NormalProps & EuiPageContentSignature['Args'];
  /** Props for the `EuiPageContentBody`, overriding layout defaults. */
  pageContentBodyProps?: NormalProps & EuiPageContentBodySignature['Args'];

  /**
   * The page header, as EuiPageHeader args: `{ pageTitle, iconType,
   * description, tabs, responsive, bottomBorder }`. Use the
   * `<:pageHeader…>` blocks for its title, description and actions.
   */
  pageHeader?: NormalProps & EuiPageHeaderSignature['Args'];

  /** Props for the side bar, including `sticky` and `paddingSize`. */
  pageSideBarProps?: NormalProps & EuiPageSideBarSignature['Args'];

  /** @deprecated Has no effect, use the `<:bottomBar>` block. */
  bottomBar?: any;

  /** @private Render the `<:bottomBar>` block. Defaults to `true`. */
  hasBottomBarBlock?: boolean;

  /** Props for the bottom bar; override the layout defaults. */
  bottomBarProps?: NormalProps & EuiButtomBarArgs;
  /**
   * Stretches the page to the window's height and scrolls the content
   * instead of the page (templates `'default'` and `'empty'`, on medium
   * screens and up). Use `'noscroll'` to fill the height without adding
   * a scrolling wrapper around the content. Defaults to `false`.
   */
  fullHeight?: boolean | 'noscroll';
  /** Minimum height of the page, in px or any CSS height. Defaults to `460`. */
  minHeight?: number | string;

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
  @argOrDefaultDecorator(false) fullHeight!: boolean | 'noscroll';
  @argOrDefaultDecorator('default') template!: (typeof TEMPLATES)[number];

  @tracked isWithinBreakpoints = false;

  setIsWithinBreakpoints = (value: boolean) => {
    this.isWithinBreakpoints = value;
  };

  get minHeight() {
    const minHeight = this.args.minHeight ?? 460;

    if (typeof minHeight === 'number') {
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
    return [this.fullHeightClass, this.args.pageBodyProps?.className]
      .filter(Boolean)
      .join(' ');
  }

  get pageContentPropsClass() {
    return [this.yScrollClass, this.args.pageContentProps?.className]
      .filter(Boolean)
      .join(' ');
  }

  get pageContentBodyPropsClass() {
    return [this.fullHeightClass, this.args.pageContentBodyProps?.className]
      .filter(Boolean)
      .join(' ');
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
                @sticky={{argOrDefault @pageSideBarProps.sticky true}}
                @paddingSize={{argOrDefault
                  @pageSideBarProps.paddingSize
                  paddingSize
                }}
              >
                {{yield to="pageSideBar"}}
              </EuiPageSideBar>
              <EuiPageBody
                class={{this.pageBodyPropsClass}}
                @paddingSize={{argOrDefault
                  @pageBodyProps.paddingSize
                  paddingSize
                }}
                @tagName={{@pageBodyProps.tagName}}
                @restrictWidth={{@pageBodyProps.restrictWidth}}
                @borderRadius={{@pageBodyProps.borderRadius}}
                @panelled={{@pageBodyProps.panelled}}
                @color={{@pageBodyProps.color}}
                @hasBorder={{@pageBodyProps.hasBorder}}
                @hasShadow={{@pageBodyProps.hasShadow}}
                @style={{@pageBodyProps.style}}
              >
                {{#if hasPageHeader}}
                  <EuiPageHeader
                    class={{@pageHeader.className}}
                    @restrictWidth={{argOrDefault
                      @pageHeader.restrictWidth
                      this.restrictWidth
                    }}
                    @responsive={{@pageHeader.responsive}}
                    @iconType={{@pageHeader.iconType}}
                    @tabs={{@pageHeader.tabs}}
                    @pageTitle={{@pageHeader.pageTitle}}
                    @description={{@pageHeader.description}}
                    @hasPageTitleBlock={{hasPageHeaderPageTitleBlock}}
                    @hasDefaultBlock={{hasPageHeaderDefaultBlock}}
                    @hasDescriptionBlock={{hasPageHeaderDescriptionBlock}}
                    @hasRightSideItemsBlock={{hasPageHeaderRightSideItemsBlock}}
                    @paddingSize={{@pageHeader.paddingSize}}
                    @bottomBorder={{@pageHeader.bottomBorder}}
                    @alignItems={{@pageHeader.alignItems}}
                    @breadcrumbs={{@pageHeader.breadcrumbs}}
                    @pageTitleProps={{@pageHeader.pageTitleProps}}
                    @style={{@pageHeader.style}}
                  >
                    <:pageTitle>
                      {{#if hasPageHeaderPageTitleBlock}}{{yield
                          to="pageHeaderPageTitle"
                        }}{{/if}}
                    </:pageTitle>
                    <:default>
                      {{#if hasPageHeaderDefaultBlock}}{{yield
                          to="pageHeaderDefault"
                        }}{{/if}}
                    </:default>
                    <:description>
                      {{#if hasPageHeaderDescriptionBlock}}{{yield
                          to="pageHeaderDescription"
                        }}{{/if}}
                    </:description>
                    <:rightSideItems as |item|>
                      {{#if hasPageHeaderRightSideItemsBlock}}{{yield
                          item
                          to="pageHeaderRightSideItems"
                        }}{{/if}}
                    </:rightSideItems>
                  </EuiPageHeader>
                {{/if}}

                <EuiPageContent
                  class={{this.pageContentPropsClass}}
                  @verticalPosition={{argOrDefault
                    @pageContentProps.verticalPosition
                    "center"
                  }}
                  @horizontalPosition={{argOrDefault
                    @pageContentProps.horizontalPosition
                    "center"
                  }}
                  @paddingSize={{argOrDefault
                    @pageContentProps.paddingSize
                    paddingSize
                  }}
                  @role={{@pageContentProps.role}}
                  @hasBorder={{@pageContentProps.hasBorder}}
                  @hasShadow={{@pageContentProps.hasShadow}}
                  @color={{@pageContentProps.color}}
                  @borderRadius={{@pageContentProps.borderRadius}}
                  @grow={{@pageContentProps.grow}}
                >
                  <EuiPageContentBody
                    class={{this.pageContentBodyPropsClass}}
                    @restrictWidth={{argOrDefault
                      @pageContentBodyProps.restrictWidth
                      this.restrictWidth
                    }}
                    @paddingSize={{@pageContentBodyProps.paddingSize}}
                    @style={{@pageContentBodyProps.style}}
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
                @restrictWidth={{argOrDefault
                  @pageBodyProps.restrictWidth
                  this.restrictWidth
                }}
                @tagName={{@pageBodyProps.tagName}}
                @paddingSize={{@pageBodyProps.paddingSize}}
                @borderRadius={{@pageBodyProps.borderRadius}}
                @panelled={{@pageBodyProps.panelled}}
                @color={{@pageBodyProps.color}}
                @hasBorder={{@pageBodyProps.hasBorder}}
                @hasShadow={{@pageBodyProps.hasShadow}}
                @style={{@pageBodyProps.style}}
              >
                {{#if hasPageHeader}}
                  <EuiPageHeader
                    class={{@pageHeader.className}}
                    @restrictWidth={{argOrDefault
                      @pageHeader.restrictWidth
                      false
                    }}
                    @bottomBorder={{argOrDefault @pageHeader.bottomBorder true}}
                    @paddingSize={{argOrDefault @pageHeader.paddingSize "none"}}
                    @responsive={{@pageHeader.responsive}}
                    @iconType={{@pageHeader.iconType}}
                    @tabs={{@pageHeader.tabs}}
                    @pageTitle={{@pageHeader.pageTitle}}
                    @description={{@pageHeader.description}}
                    @hasPageTitleBlock={{hasPageHeaderPageTitleBlock}}
                    @hasDefaultBlock={{hasPageHeaderDefaultBlock}}
                    @hasDescriptionBlock={{hasPageHeaderDescriptionBlock}}
                    @hasRightSideItemsBlock={{hasPageHeaderRightSideItemsBlock}}
                    @alignItems={{@pageHeader.alignItems}}
                    @breadcrumbs={{@pageHeader.breadcrumbs}}
                    @pageTitleProps={{@pageHeader.pageTitleProps}}
                    @style={{@pageHeader.style}}
                  >
                    <:pageTitle>
                      {{#if hasPageHeaderPageTitleBlock}}{{yield
                          to="pageHeaderPageTitle"
                        }}{{/if}}
                    </:pageTitle>
                    <:default>
                      {{#if hasPageHeaderDefaultBlock}}{{yield
                          to="pageHeaderDefault"
                        }}{{/if}}
                    </:default>
                    <:description>
                      {{#if hasPageHeaderDescriptionBlock}}{{yield
                          to="pageHeaderDescription"
                        }}{{/if}}
                    </:description>
                    <:rightSideItems as |item|>
                      {{#if hasPageHeaderRightSideItemsBlock}}{{yield
                          item
                          to="pageHeaderRightSideItems"
                        }}{{/if}}
                    </:rightSideItems>
                  </EuiPageHeader>
                {{/if}}
                <EuiPageBody>
                  <EuiPageContent
                    class={{this.pageContentPropsClass}}
                    @verticalPosition={{argOrDefault
                      @pageContentProps.verticalPosition
                      "center"
                    }}
                    @horizontalPosition={{argOrDefault
                      @pageContentProps.horizontalPosition
                      "center"
                    }}
                    @hasBorder={{@pageContentProps.hasBorder}}
                    @hasShadow={{@pageContentProps.hasShadow}}
                    @color={{@pageContentProps.color}}
                    @borderRadius={{@pageContentProps.borderRadius}}
                    @grow={{@pageContentProps.grow}}
                    @role={{@pageContentProps.role}}
                    @paddingSize={{argOrDefault
                      @pageContentProps.paddingSize
                      paddingSize
                    }}
                  >
                    <EuiPageContentBody
                      class={{this.pageContentBodyPropsClass}}
                      @paddingSize={{argOrDefault
                        @pageContentBodyProps.paddingSize
                        "none"
                      }}
                      @restrictWidth={{argOrDefault
                        @pageContentBodyProps.restrictWidth
                        this.restrictWidth
                      }}
                      @style={{@pageContentBodyProps.style}}
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
                @sticky={{argOrDefault @pageSideBarProps.sticky true}}
                @paddingSize={{argOrDefault
                  @pageSideBarProps.paddingSize
                  paddingSize
                }}
              >
                {{yield to="pageSideBar"}}
              </EuiPageSideBar>
              <EuiPageBody
                @panelled={{argOrDefault @pageBodyProps.panelled true}}
                @paddingSize={{argOrDefault
                  @pageBodyProps.paddingSize
                  paddingSize
                }}
                class={{this.pageBodyPropsClass}}
                @tagName={{@pageBodyProps.tagName}}
                @restrictWidth={{@pageBodyProps.restrictWidth}}
                @borderRadius={{@pageBodyProps.borderRadius}}
                @color={{@pageBodyProps.color}}
                @hasBorder={{@pageBodyProps.hasBorder}}
                @hasShadow={{@pageBodyProps.hasShadow}}
                @style={{@pageBodyProps.style}}
              >
                {{#if hasPageHeader}}
                  <EuiPageHeader
                    class={{@pageHeader.className}}
                    @restrictWidth={{argOrDefault
                      @pageHeader.restrictWidth
                      this.restrictWidth
                    }}
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
                    @bottomBorder={{@pageHeader.bottomBorder}}
                    @alignItems={{@pageHeader.alignItems}}
                    @breadcrumbs={{@pageHeader.breadcrumbs}}
                    @pageTitleProps={{@pageHeader.pageTitleProps}}
                    @style={{@pageHeader.style}}
                  >
                    <:pageTitle>
                      {{#if hasPageHeaderPageTitleBlock}}{{yield
                          to="pageHeaderPageTitle"
                        }}{{/if}}
                    </:pageTitle>
                    <:default>
                      {{#if hasPageHeaderDefaultBlock}}{{yield
                          to="pageHeaderDefault"
                        }}{{/if}}
                    </:default>
                    <:description>
                      {{#if hasPageHeaderDescriptionBlock}}{{yield
                          to="pageHeaderDescription"
                        }}{{/if}}
                    </:description>
                    <:rightSideItems as |item|>
                      {{#if hasPageHeaderRightSideItemsBlock}}{{yield
                          item
                          to="pageHeaderRightSideItems"
                        }}{{/if}}
                    </:rightSideItems>
                  </EuiPageHeader>
                {{/if}}
                <EuiPageContent
                  @verticalPosition={{argOrDefault
                    @pageContentProps.verticalPosition
                    "center"
                  }}
                  @horizontalPosition={{argOrDefault
                    @pageContentProps.horizontalPosition
                    "center"
                  }}
                  @hasShadow={{argOrDefault @pageContentProps.hasShadow false}}
                  @color={{argOrDefault @pageContentProps.color "subdued"}}
                  @paddingSize={{argOrDefault
                    @pageContentProps.paddingSize
                    paddingSize
                  }}
                  class={{this.pageContentPropsClass}}
                  @role={{@pageContentProps.role}}
                  @hasBorder={{@pageContentProps.hasBorder}}
                  @borderRadius={{@pageContentProps.borderRadius}}
                  @grow={{@pageContentProps.grow}}
                >
                  <EuiPageContentBody
                    @restrictWidth={{argOrDefault
                      @pageContentBodyProps.restrictWidth
                      this.restrictWidth
                    }}
                    class={{this.pageContentBodyPropsClass}}
                    @paddingSize={{@pageContentBodyProps.paddingSize}}
                    @style={{@pageContentBodyProps.style}}
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
              <EuiPageBody
                class={{this.pageBodyPropsClass}}
                @tagName={{@pageBodyProps.tagName}}
                @restrictWidth={{@pageBodyProps.restrictWidth}}
                @paddingSize={{@pageBodyProps.paddingSize}}
                @borderRadius={{@pageBodyProps.borderRadius}}
                @panelled={{@pageBodyProps.panelled}}
                @color={{@pageBodyProps.color}}
                @hasBorder={{@pageBodyProps.hasBorder}}
                @hasShadow={{@pageBodyProps.hasShadow}}
                @style={{@pageBodyProps.style}}
              >
                {{#if hasPageHeader}}
                  <EuiPageHeader
                    class={{@pageHeader.className}}
                    @restrictWidth={{argOrDefault
                      @pageHeader.restrictWidth
                      this.restrictWidth
                    }}
                    @paddingSize={{argOrDefault
                      @pageHeader.paddingSize
                      paddingSize
                    }}
                    @responsive={{@pageHeader.responsive}}
                    @iconType={{@pageHeader.iconType}}
                    @tabs={{@pageHeader.tabs}}
                    @pageTitle={{@pageHeader.pageTitle}}
                    @description={{@pageHeader.description}}
                    @hasPageTitleBlock={{hasPageHeaderPageTitleBlock}}
                    @hasDefaultBlock={{hasPageHeaderDefaultBlock}}
                    @hasDescriptionBlock={{hasPageHeaderDescriptionBlock}}
                    @hasRightSideItemsBlock={{hasPageHeaderRightSideItemsBlock}}
                    @bottomBorder={{@pageHeader.bottomBorder}}
                    @alignItems={{@pageHeader.alignItems}}
                    @breadcrumbs={{@pageHeader.breadcrumbs}}
                    @pageTitleProps={{@pageHeader.pageTitleProps}}
                    @style={{@pageHeader.style}}
                  >
                    <:pageTitle>
                      {{#if hasPageHeaderPageTitleBlock}}{{yield
                          to="pageHeaderPageTitle"
                        }}{{/if}}
                    </:pageTitle>
                    <:default>
                      {{#if hasPageHeaderDefaultBlock}}{{yield
                          to="pageHeaderDefault"
                        }}{{/if}}
                    </:default>
                    <:description>
                      {{#if hasPageHeaderDescriptionBlock}}{{yield
                          to="pageHeaderDescription"
                        }}{{/if}}
                    </:description>
                    <:rightSideItems as |item|>
                      {{#if hasPageHeaderRightSideItemsBlock}}{{yield
                          item
                          to="pageHeaderRightSideItems"
                        }}{{/if}}
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
                    @verticalPosition={{argOrDefault
                      @pageContentProps.verticalPosition
                      "center"
                    }}
                    @horizontalPosition={{argOrDefault
                      @pageContentProps.horizontalPosition
                      "center"
                    }}
                    @hasShadow={{argOrDefault
                      @pageContentProps.hasShadow
                      false
                    }}
                    @color={{argOrDefault @pageContentProps.color "subdued"}}
                    @paddingSize={{argOrDefault
                      @pageContentProps.paddingSize
                      paddingSize
                    }}
                    class={{this.pageContentPropsClass}}
                    @role={{@pageContentProps.role}}
                    @hasBorder={{@pageContentProps.hasBorder}}
                    @borderRadius={{@pageContentProps.borderRadius}}
                    @grow={{@pageContentProps.grow}}
                  >
                    <EuiPageContentBody
                      @restrictWidth={{argOrDefault
                        @pageContentBodyProps.restrictWidth
                        this.restrictWidth
                      }}
                      class={{this.pageContentBodyPropsClass}}
                      @paddingSize={{@pageContentBodyProps.paddingSize}}
                      @style={{@pageContentBodyProps.style}}
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
                @sticky={{argOrDefault @pageSideBarProps.sticky true}}
                @paddingSize={{argOrDefault
                  @pageSideBarProps.paddingSize
                  paddingSize
                }}
              >
                {{yield to="pageSideBar"}}
              </EuiPageSideBar>
              <EuiPageBody
                @paddingSize={{argOrDefault
                  @pageBodyProps.paddingSize
                  paddingSize
                }}
                class={{this.pageBodyPropsClass}}
                @tagName={{@pageBodyProps.tagName}}
                @restrictWidth={{@pageBodyProps.restrictWidth}}
                @borderRadius={{@pageBodyProps.borderRadius}}
                @panelled={{@pageBodyProps.panelled}}
                @color={{@pageBodyProps.color}}
                @hasBorder={{@pageBodyProps.hasBorder}}
                @hasShadow={{@pageBodyProps.hasShadow}}
                @style={{@pageBodyProps.style}}
              >
                {{#if hasPageHeader}}
                  <EuiPageHeader
                    class={{@pageHeader.className}}
                    @restrictWidth={{argOrDefault
                      @pageHeader.restrictWidth
                      this.restrictWidth
                    }}
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
                    @bottomBorder={{@pageHeader.bottomBorder}}
                    @alignItems={{@pageHeader.alignItems}}
                    @breadcrumbs={{@pageHeader.breadcrumbs}}
                    @pageTitleProps={{@pageHeader.pageTitleProps}}
                    @style={{@pageHeader.style}}
                  >
                    <:pageTitle>
                      {{#if hasPageHeaderPageTitleBlock}}{{yield
                          to="pageHeaderPageTitle"
                        }}{{/if}}
                    </:pageTitle>
                    <:default>
                      {{#if hasPageHeaderDefaultBlock}}{{yield
                          to="pageHeaderDefault"
                        }}{{/if}}
                    </:default>
                    <:description>
                      {{#if hasPageHeaderDescriptionBlock}}{{yield
                          to="pageHeaderDescription"
                        }}{{/if}}
                    </:description>
                    <:rightSideItems as |item|>
                      {{#if hasPageHeaderRightSideItemsBlock}}{{yield
                          item
                          to="pageHeaderRightSideItems"
                        }}{{/if}}
                    </:rightSideItems>
                  </EuiPageHeader>
                {{/if}}
                <EuiPageContent
                  @hasBorder={{argOrDefault @pageContentProps.hasBorder false}}
                  @hasShadow={{argOrDefault @pageContentProps.hasShadow false}}
                  @paddingSize={{argOrDefault
                    @pageContentProps.paddingSize
                    "none"
                  }}
                  @color={{argOrDefault @pageContentProps.color "transparent"}}
                  @borderRadius={{argOrDefault
                    @pageContentProps.borderRadius
                    "none"
                  }}
                  class={{this.pageContentPropsClass}}
                  @role={{@pageContentProps.role}}
                  @verticalPosition={{@pageContentProps.verticalPosition}}
                  @horizontalPosition={{@pageContentProps.horizontalPosition}}
                  @grow={{@pageContentProps.grow}}
                >
                  <EuiPageContentBody
                    @restrictWidth={{argOrDefault
                      @pageContentBodyProps.restrictWidth
                      this.restrictWidth
                    }}
                    class={{this.pageContentBodyPropsClass}}
                    @paddingSize={{@pageContentBodyProps.paddingSize}}
                    @style={{@pageContentBodyProps.style}}
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
                @restrictWidth={{argOrDefault
                  @pageBodyProps.restrictWidth
                  this.restrictWidth
                }}
                class={{this.pageBodyPropsClass}}
                @tagName={{@pageBodyProps.tagName}}
                @paddingSize={{@pageBodyProps.paddingSize}}
                @borderRadius={{@pageBodyProps.borderRadius}}
                @panelled={{@pageBodyProps.panelled}}
                @color={{@pageBodyProps.color}}
                @hasBorder={{@pageBodyProps.hasBorder}}
                @hasShadow={{@pageBodyProps.hasShadow}}
                @style={{@pageBodyProps.style}}
              >
                {{#if hasPageHeader}}
                  <EuiPageHeader
                    class={{@pageHeader.className}}
                    @bottomBorder={{argOrDefault @pageHeader.bottomBorder true}}
                    @restrictWidth={{argOrDefault
                      @pageHeader.restrictWidth
                      false
                    }}
                    @paddingSize={{argOrDefault @pageHeader.paddingSize "none"}}
                    @responsive={{@pageHeader.responsive}}
                    @iconType={{@pageHeader.iconType}}
                    @tabs={{@pageHeader.tabs}}
                    @pageTitle={{@pageHeader.pageTitle}}
                    @description={{@pageHeader.description}}
                    @hasPageTitleBlock={{hasPageHeaderPageTitleBlock}}
                    @hasDefaultBlock={{hasPageHeaderDefaultBlock}}
                    @hasDescriptionBlock={{hasPageHeaderDescriptionBlock}}
                    @hasRightSideItemsBlock={{hasPageHeaderRightSideItemsBlock}}
                    @alignItems={{@pageHeader.alignItems}}
                    @breadcrumbs={{@pageHeader.breadcrumbs}}
                    @pageTitleProps={{@pageHeader.pageTitleProps}}
                    @style={{@pageHeader.style}}
                  >
                    <:pageTitle>
                      {{#if hasPageHeaderPageTitleBlock}}{{yield
                          to="pageHeaderPageTitle"
                        }}{{/if}}
                    </:pageTitle>
                    <:default>
                      {{#if hasPageHeaderDefaultBlock}}{{yield
                          to="pageHeaderDefault"
                        }}{{/if}}
                    </:default>
                    <:description>
                      {{#if hasPageHeaderDescriptionBlock}}{{yield
                          to="pageHeaderDescription"
                        }}{{/if}}
                    </:description>
                    <:rightSideItems as |item|>
                      {{#if hasPageHeaderRightSideItemsBlock}}{{yield
                          item
                          to="pageHeaderRightSideItems"
                        }}{{/if}}
                    </:rightSideItems>
                  </EuiPageHeader>
                {{/if}}
                <EuiPageContent
                  @hasBorder={{argOrDefault @pageContentProps.hasBorder false}}
                  @hasShadow={{argOrDefault @pageContentProps.hasShadow false}}
                  @paddingSize={{argOrDefault
                    @pageContentProps.paddingSize
                    "none"
                  }}
                  @color={{argOrDefault @pageContentProps.color "transparent"}}
                  @borderRadius={{argOrDefault
                    @pageContentProps.borderRadius
                    "none"
                  }}
                  class={{this.pageContentPropsClass}}
                  @role={{@pageContentProps.role}}
                  @verticalPosition={{@pageContentProps.verticalPosition}}
                  @horizontalPosition={{@pageContentProps.horizontalPosition}}
                  @grow={{@pageContentProps.grow}}
                >
                  <EuiPageContentBody
                    @restrictWidth={{argOrDefault
                      @pageContentBodyProps.restrictWidth
                      false
                    }}
                    class={{this.pageContentBodyPropsClass}}
                    @paddingSize={{argOrDefault
                      @pageContentBodyProps.paddingSize
                      "none"
                    }}
                    @style={{@pageContentBodyProps.style}}
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
                @sticky={{argOrDefault @pageSideBarProps.sticky true}}
                @paddingSize={{argOrDefault
                  @pageSideBarProps.paddingSize
                  paddingSize
                }}
              >
                {{yield to="pageSideBar"}}
              </EuiPageSideBar>
              <EuiPageBody
                @panelled={{argOrDefault @pageBodyProps.panelled true}}
                @paddingSize={{argOrDefault @pageBodyProps.paddingSize "none"}}
                class={{this.pageBodyPropsClass}}
                @tagName={{@pageBodyProps.tagName}}
                @restrictWidth={{@pageBodyProps.restrictWidth}}
                @borderRadius={{@pageBodyProps.borderRadius}}
                @color={{@pageBodyProps.color}}
                @hasBorder={{@pageBodyProps.hasBorder}}
                @hasShadow={{@pageBodyProps.hasShadow}}
                @style={{@pageBodyProps.style}}
              >
                <EuiPageBody
                  class={{this.pageBodyPropsClass}}
                  @paddingSize={{paddingSize}}
                  @tagName="div"
                >
                  {{#if hasPageHeader}}
                    <EuiPageHeader
                      class={{@pageHeader.className}}
                      @bottomBorder={{argOrDefault
                        @pageHeader.bottomBorder
                        true
                      }}
                      @restrictWidth={{argOrDefault
                        @pageHeader.restrictWidth
                        this.restrictWidth
                      }}
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
                      @alignItems={{@pageHeader.alignItems}}
                      @breadcrumbs={{@pageHeader.breadcrumbs}}
                      @pageTitleProps={{@pageHeader.pageTitleProps}}
                      @style={{@pageHeader.style}}
                    >
                      <:pageTitle>
                        {{#if hasPageHeaderPageTitleBlock}}{{yield
                            to="pageHeaderPageTitle"
                          }}{{/if}}
                      </:pageTitle>
                      <:default>
                        {{#if hasPageHeaderDefaultBlock}}{{yield
                            to="pageHeaderDefault"
                          }}{{/if}}
                      </:default>
                      <:description>
                        {{#if hasPageHeaderDescriptionBlock}}{{yield
                            to="pageHeaderDescription"
                          }}{{/if}}
                      </:description>
                      <:rightSideItems as |item|>
                        {{#if hasPageHeaderRightSideItemsBlock}}{{yield
                            item
                            to="pageHeaderRightSideItems"
                          }}{{/if}}
                      </:rightSideItems>
                    </EuiPageHeader>
                  {{/if}}
                  <EuiPageContent
                    @hasShadow={{argOrDefault
                      @pageContentProps.hasShadow
                      false
                    }}
                    @hasBorder={{argOrDefault
                      @pageContentProps.hasBorder
                      false
                    }}
                    @color={{argOrDefault
                      @pageContentProps.color
                      "transparent"
                    }}
                    @borderRadius={{argOrDefault
                      @pageContentProps.borderRadius
                      "none"
                    }}
                    @paddingSize={{argOrDefault
                      @pageContentProps.paddingSize
                      "none"
                    }}
                    class={{this.pageContentPropsClass}}
                    @role={{@pageContentProps.role}}
                    @verticalPosition={{@pageContentProps.verticalPosition}}
                    @horizontalPosition={{@pageContentProps.horizontalPosition}}
                    @grow={{@pageContentProps.grow}}
                  >
                    <EuiPageContentBody
                      @restrictWidth={{argOrDefault
                        @pageContentBodyProps.restrictWidth
                        this.restrictWidth
                      }}
                      class={{this.pageContentBodyPropsClass}}
                      @paddingSize={{@pageContentBodyProps.paddingSize}}
                      @style={{@pageContentBodyProps.style}}
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
                    class={{@bottomBarProps.className}}
                    @paddingSize={{argOrDefault
                      @bottomBarProps.paddingSize
                      paddingSize
                    }}
                    @position={{argOrDefault
                      @bottomBarProps.position
                      (if
                        (and this.canFullHeight this.fullHeight)
                        "static"
                        "sticky"
                      )
                    }}
                    @affordForDisplacement={{@bottomBarProps.affordForDisplacement}}
                    @bodyClassName={{@bottomBarProps.bodyClassName}}
                    @landmarkHeading={{@bottomBarProps.landmarkHeading}}
                    @top={{@bottomBarProps.top}}
                    @right={{@bottomBarProps.right}}
                    @left={{@bottomBarProps.left}}
                    @bottom={{@bottomBarProps.bottom}}
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
              <EuiPageBody
                class={{this.pageBodyPropsClass}}
                @tagName={{@pageBodyProps.tagName}}
                @restrictWidth={{@pageBodyProps.restrictWidth}}
                @paddingSize={{@pageBodyProps.paddingSize}}
                @borderRadius={{@pageBodyProps.borderRadius}}
                @panelled={{@pageBodyProps.panelled}}
                @color={{@pageBodyProps.color}}
                @hasBorder={{@pageBodyProps.hasBorder}}
                @hasShadow={{@pageBodyProps.hasShadow}}
                @style={{@pageBodyProps.style}}
              >
                {{#if hasPageHeader}}
                  <EuiPageHeader
                    class={{@pageHeader.className}}
                    @restrictWidth={{argOrDefault
                      @pageHeader.restrictWidth
                      this.restrictWidth
                    }}
                    @bottomBorder={{@pageHeader.bottomBorder}}
                    @paddingSize={{argOrDefault
                      @pageHeader.paddingSize
                      paddingSize
                    }}
                    @responsive={{@pageHeader.responsive}}
                    @iconType={{@pageHeader.iconType}}
                    @tabs={{@pageHeader.tabs}}
                    @pageTitle={{@pageHeader.pageTitle}}
                    @description={{@pageHeader.description}}
                    @hasPageTitleBlock={{hasPageHeaderPageTitleBlock}}
                    @hasDefaultBlock={{hasPageHeaderDefaultBlock}}
                    @hasDescriptionBlock={{hasPageHeaderDescriptionBlock}}
                    @hasRightSideItemsBlock={{hasPageHeaderRightSideItemsBlock}}
                    @alignItems={{@pageHeader.alignItems}}
                    @breadcrumbs={{@pageHeader.breadcrumbs}}
                    @pageTitleProps={{@pageHeader.pageTitleProps}}
                    @style={{@pageHeader.style}}
                  >
                    <:pageTitle>
                      {{#if hasPageHeaderPageTitleBlock}}{{yield
                          to="pageHeaderPageTitle"
                        }}{{/if}}
                    </:pageTitle>
                    <:default>
                      {{#if hasPageHeaderDefaultBlock}}{{yield
                          to="pageHeaderDefault"
                        }}{{/if}}
                    </:default>
                    <:description>
                      {{#if hasPageHeaderDescriptionBlock}}{{yield
                          to="pageHeaderDescription"
                        }}{{/if}}
                    </:description>
                    <:rightSideItems as |item|>
                      {{#if hasPageHeaderRightSideItemsBlock}}{{yield
                          item
                          to="pageHeaderRightSideItems"
                        }}{{/if}}
                    </:rightSideItems>
                  </EuiPageHeader>
                {{/if}}
                <EuiPageContent
                  @hasBorder={{if
                    (eq @pageContentProps.hasBorder undefined)
                    (if hasPageHeader undefined false)
                    @pageContentProps.hasBorder
                  }}
                  @hasShadow={{argOrDefault @pageContentProps.hasShadow false}}
                  @paddingSize={{argOrDefault
                    @pageContentProps.paddingSize
                    "none"
                  }}
                  @color={{argOrDefault @pageContentProps.color "plain"}}
                  @borderRadius={{argOrDefault
                    @pageContentProps.borderRadius
                    "none"
                  }}
                  class={{this.pageContentPropsClass}}
                  @role={{@pageContentProps.role}}
                  @verticalPosition={{@pageContentProps.verticalPosition}}
                  @horizontalPosition={{@pageContentProps.horizontalPosition}}
                  @grow={{@pageContentProps.grow}}
                >
                  <EuiPageContentBody
                    @restrictWidth={{argOrDefault
                      @pageContentBodyProps.restrictWidth
                      this.restrictWidth
                    }}
                    @paddingSize={{argOrDefault
                      @pageContentBodyProps.paddingSize
                      paddingSize
                    }}
                    class={{this.pageContentBodyPropsClass}}
                    @style={{@pageContentBodyProps.style}}
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
                    class={{@bottomBarProps.className}}
                    @paddingSize={{argOrDefault
                      @bottomBarProps.paddingSize
                      paddingSize
                    }}
                    @position={{argOrDefault
                      @bottomBarProps.position
                      (if
                        (and this.canFullHeight this.fullHeight)
                        "static"
                        "sticky"
                      )
                    }}
                    @affordForDisplacement={{@bottomBarProps.affordForDisplacement}}
                    @bodyClassName={{@bottomBarProps.bodyClassName}}
                    @landmarkHeading={{@bottomBarProps.landmarkHeading}}
                    @top={{@bottomBarProps.top}}
                    @right={{@bottomBarProps.right}}
                    @left={{@bottomBarProps.left}}
                    @bottom={{@bottomBarProps.bottom}}
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
