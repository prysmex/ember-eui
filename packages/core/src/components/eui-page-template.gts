import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { isDestroying } from '@ember/destroyable';
import { hash } from '@ember/helper';
import { guidFor } from '@ember/object/internals';

import { modifier as functionModifier } from 'ember-modifier';
import style from 'ember-style-modifier/modifiers/style';
import { and, eq, or } from 'ember-truth-helpers';

import argOrDefault, {
  argOrDefaultDecorator
} from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import inlineStyles from '../helpers/inline-styles.ts';
import useIsWithinBreakpoints from '../modifiers/use-is-within-breakpoints.ts';
import { deprecateRemovedUpstream } from '../-private/removed-upstream.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  euiBreakpointsMedia,
  euiOutsideBreakpointsMedia,
  euiPageBoxSizing
} from '../utils/eui/page-layout.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiFullHeight,
  euiPageInnerStyles,
  euiPageOuterStyles,
  euiYScroll
} from '../utils/eui/styles.generated.ts';
import EuiBottomBar from './eui-bottom-bar.gts';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiPage from './eui-page.gts';
import EuiPageBody from './eui-page-body.gts';
import EuiPageContent from './eui-page-content.gts';
import EuiPageContentBody from './eui-page-content-body.gts';
import EuiPageHeader from './eui-page-header.gts';
import EuiPageSection from './eui-page-section.gts';
import EuiPageSideBar from './eui-page-side-bar.gts';
import EuiPageTemplateBottomBar from './eui-page-template/bottom-bar.gts';
import EuiPageTemplateEmptyPrompt from './eui-page-template/empty-prompt.gts';
import EuiPageTemplateSidebar from './eui-page-template/sidebar.gts';

import type { EuiBreakpointSize } from '../utils/breakpoint.ts';
import type {
  EuiPageBreakpoint,
  EuiPagePaddingSize
} from '../utils/eui/page-layout.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import type { EuiButtomBarArgs } from './eui-bottom-bar';
import type { EuiPageBodySignature } from './eui-page-body';
import type { EuiPageContentSignature } from './eui-page-content';
import type { EuiPageContentBodySignature } from './eui-page-content-body';
import type { EuiPageHeaderSignature } from './eui-page-header';
import type { EuiPageSideBarSignature } from './eui-page-side-bar';
import type { EuiPageTemplateSidebarRegistry } from './eui-page-template/sidebar.gts';
import type { WithBoundArgs } from '@glint/template';

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

/** Upstream `mainProps`: what goes on the `<main>` content wrapper. */
export interface EuiPageTemplateMainProps {
  /** Its `id`. Defaults to a generated `EuiPageTemplateInner_…` id. */
  id?: string;
  /** Extra class names. */
  className?: string;
  /** Styles composed last into its class (upstream's `css`). */
  css?: EuiCss;
  /** Inline styles. */
  style?: Record<string, string>;
  role?: string;
  'aria-label'?: string;
  'aria-labelledby'?: string;
  'data-test-subj'?: string;
}

export type EuiPageTemplateProps = {
  /**
   * Shared by both APIs. Max width of the header and the sections'
   * content: `true` for EUI's default (1200px), a number in px or any CSS
   * width. Defaults to `true`.
   */
  restrictWidth?: boolean | number | string;
  /**
   * Shared by both APIs. Grows the page to fill its flex parent; with the
   * composable API it also makes the page at least as tall as the window.
   * Defaults to `true`.
   */
  grow?: boolean;
  /**
   * Shared by both APIs. Padding of the header, sections, sidebar and
   * bottom bar: `'none'`, `'xs'`, `'s'`, `'m'`, `'l'` or `'xl'` (`'xs'`
   * and `'xl'` with the composable API only). Defaults to `'l'`.
   */
  paddingSize?: EuiPagePaddingSize;
  /**
   * Shared by both APIs. Minimum height of the page, in px or any CSS
   * height. With the composable API and `@grow`, the page is at least
   * `max(minHeight, 100vh)`. Defaults to `460`.
   */
  minHeight?: number | string;

  /**
   * Composable API. Puts the main content on a plain panel and sections
   * and the header on plain backgrounds; `false` makes them transparent.
   * Defaults to panelled when there is a sidebar.
   */
  panelled?: boolean;
  /**
   * Composable API. Border under `T.Header`: `true` within the restricted
   * width, `'extended'` across the whole header. Defaults to `true` with a
   * sidebar, `'extended'` without.
   */
  bottomBorder?: boolean | 'extended';
  /**
   * Composable API. A border separating the main content from the
   * sidebar (on its inline start, or on top when stacked). Defaults to
   * `true` with a sidebar.
   */
  contentBorder?: boolean;
  /**
   * Composable API. Top padding of the page in px. Upstream defaults it
   * to the fixed headers' height (`--euiFixedHeadersOffset`); in Ember a
   * fixed `EuiHeader` already pads `<body>` by that height, so the default
   * is no extra padding (upstream's default would leave a header-sized gap).
   * Sticky sidebars still clear fixed headers.
   */
  offset?: number;
  /**
   * Composable API. Theme breakpoints (`'xs'`…`'xl'`) where the sidebar
   * stacks above the content and takes the full width. Defaults to
   * `['xs', 's']`.
   */
  responsive?: EuiPageBreakpoint[];
  /**
   * Composable API. `'row'` puts the sidebar beside the content
   * (stacking on `@responsive` breakpoints); `'column'` always stacks
   * it. Defaults to `'row'`.
   */
  direction?: 'row' | 'column';
  /** Composable API. Tag of the main content wrapper. Defaults to `'main'`. */
  component?: string;
  /**
   * Composable API. Attributes of the main content wrapper: `{ id,
   * className, css, style, role, 'aria-label', 'aria-labelledby',
   * 'data-test-subj' }`.
   */
  mainProps?: EuiPageTemplateMainProps;
  /** Composable API. Styles composed last into the page's class (upstream's `css`). */
  css?: EuiCss;

  /**
   * Legacy API. Layout: `'default'` (header and content),
   * `'centeredBody'` (content panel centered in the page),
   * `'centeredContent'` (content centered in the body, e.g. an empty
   * prompt) or `'empty'` (no panels). Defaults to `'default'`.
   */
  template?: (typeof TEMPLATES)[number];

  /** Legacy API. Props for the `EuiPageBody`, overriding layout defaults. */
  pageBodyProps?: NormalProps & EuiPageBodySignature['Args'];
  /**
   * Legacy API. Props for the `EuiPageContent`: `{ className, hasBorder,
   * hasShadow, color, borderRadius, grow, role }`.
   */
  pageContentProps?: NormalProps & EuiPageContentSignature['Args'];
  /** Legacy API. Props for the `EuiPageContentBody`, overriding layout defaults. */
  pageContentBodyProps?: NormalProps & EuiPageContentBodySignature['Args'];

  /**
   * Legacy API. The page header, as EuiPageHeader args: `{ pageTitle,
   * iconType, description, tabs, responsive, bottomBorder }`. Use the
   * `<:pageHeader…>` blocks for its title, description and actions.
   */
  pageHeader?: NormalProps & EuiPageHeaderSignature['Args'];

  /** Legacy API. Props for the side bar, including `sticky` and `paddingSize`. */
  pageSideBarProps?: NormalProps & EuiPageSideBarSignature['Args'];

  /** @deprecated Has no effect, use the `<:bottomBar>` block. */
  bottomBar?: any;

  /** @private Render the `<:bottomBar>` block. Defaults to `true`. */
  hasBottomBarBlock?: boolean;

  /** Legacy API. Props for the bottom bar; override the layout defaults. */
  bottomBarProps?: NormalProps & EuiButtomBarArgs;
  /**
   * Legacy API. Stretches the page to the window's height and scrolls the
   * content instead of the page (templates `'default'` and `'empty'`, on
   * medium screens and up). Use `'noscroll'` to fill the height without
   * adding a scrolling wrapper around the content. Defaults to `false`.
   */
  fullHeight?: boolean | 'noscroll';
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
 * The parts `EuiPageTemplate` yields (upstream's `EuiPageTemplate.Sidebar`,
 * `.Header`, `.Section`, `.EmptyPrompt` and `.BottomBar`), set up with the
 * template's settings. Args passed to a part override them.
 */
export interface EuiPageTemplateParts {
  /**
   * `EuiPageSidebar` with the template's `@paddingSize` and `@responsive`.
   * Only in the `<:sidebar>` block (it asserts elsewhere).
   */
  Sidebar: WithBoundArgs<
    typeof EuiPageTemplateSidebar,
    'paddingSize' | 'responsive'
  >;
  /** `EuiPageHeader` with the template's width, padding, bottom border and color. */
  Header: WithBoundArgs<
    typeof EuiPageHeader,
    'restrictWidth' | 'paddingSize' | 'bottomBorder' | 'color'
  >;
  /** `EuiPageSection` with the template's width, padding and color; it grows. */
  Section: WithBoundArgs<
    typeof EuiPageSection,
    'restrictWidth' | 'paddingSize' | 'color' | 'grow'
  >;
  /** A centered `EuiEmptyPrompt`, panelled when the content is. */
  EmptyPrompt: WithBoundArgs<typeof EuiPageTemplateEmptyPrompt, 'panelled' | 'grow'>;
  /** A sticky `EuiBottomBar` aligned with the template's width and padding. */
  BottomBar: WithBoundArgs<
    typeof EuiPageTemplateBottomBar,
    'restrictWidth' | 'paddingSize'
  >;
}

/**
 * A whole page layout. The composable API (upstream's) yields the page's
 * parts, which inherit the template's settings:
 *
 * ```hbs
 * <EuiPageTemplate @panelled={{true}}>
 *   <:sidebar as |T|><T.Sidebar>…</T.Sidebar></:sidebar>
 *   <:default as |T|>
 *     <T.Header @pageTitle="Users" />
 *     <T.Section>…</T.Section>
 *     <T.BottomBar>…</T.BottomBar>
 *   </:default>
 * </EuiPageTemplate>
 * ```
 *
 * The legacy API (`@template`, `@pageHeader`, `<:pageSideBar>`, …) is
 * deprecated: upstream removed it.
 */
export interface EuiPageTemplateSignature {
  Element: HTMLElement;
  Args: EuiPageTemplateProps;
  Blocks: {
    /**
     * The page's content. Composable API: yields the parts (`as |T|`), to
     * stack `T.Header`, `T.Section`, `T.EmptyPrompt`, `T.BottomBar` or any
     * content in the main element, in order.
     */
    default: [EuiPageTemplateParts];
    /**
     * Composable API. Sidebars (`T.Sidebar`, may be conditional), rendered
     * beside the main element. Any rendered `T.Sidebar` panels and borders
     * the content, like upstream.
     */
    sidebar: [Pick<EuiPageTemplateParts, 'Sidebar'>];
    /** Legacy API. A side bar, e.g. an `EuiSideNav`. */
    pageSideBar: [];
    /** Legacy API. The header's title, instead of `pageHeader.pageTitle`. */
    pageHeaderPageTitle: [];
    /** Legacy API. Extra header content. */
    pageHeaderDefault: [];
    /** Legacy API. The header's description. */
    pageHeaderDescription: [];
    /** Legacy API. Header actions; yields an item to wrap each in, see EuiPageHeader. */
    pageHeaderRightSideItems: EuiPageHeaderSignature['Blocks']['rightSideItems'];
    /** Legacy API. Content of a bottom bar (EuiBottomBar), e.g. save/cancel buttons. */
    bottomBar: [];
  };
}

const DEFAULT_RESPONSIVE: EuiPageBreakpoint[] = ['xs', 's'];

interface ComposableLayout {
  innerClass: string;
  headerBottomBorder: boolean | 'extended';
  emptyPromptPanelled: boolean | undefined;
}

export default class EuiPageTemplate extends Component<EuiPageTemplateSignature> {
  // Composable API (upstream EUI 123's EuiPageTemplate)

  /** Upstream's `pageInnerId`, unless `mainProps.id` is given. */
  generatedInnerId = `EuiPageTemplateInner_${guidFor(this)}`;

  /**
   * Whether the composable API is in use: a block taking the parts
   * (`as |T|`), a `<:sidebar>` block (checked in the template) or any arg
   * only the composable API has.
   */
  get hasComposableArgs(): boolean {
    const args = this.args;
    return [
      args.panelled,
      args.bottomBorder,
      args.contentBorder,
      args.offset,
      args.responsive,
      args.direction,
      args.component,
      args.mainProps,
      args.css
    ].some((value) => value !== undefined);
  }

  get composablePaddingSize(): EuiPagePaddingSize {
    return this.args.paddingSize ?? 'l';
  }

  get composableRestrictWidth(): boolean | number | string {
    return this.args.restrictWidth ?? true;
  }

  get responsive(): EuiPageBreakpoint[] {
    return this.args.responsive ?? DEFAULT_RESPONSIVE;
  }

  /** Header and section background: upstream's `panelled === false ? 'transparent' : 'plain'`. */
  get sectionColor(): 'transparent' | 'plain' {
    return this.args.panelled === false ? 'transparent' : 'plain';
  }

  get mainTag(): string {
    return this.args.component ?? 'main';
  }

  get mainStyle(): Record<string, string> {
    return this.args.mainProps?.style ?? {};
  }

  get mainId(): string {
    return this.args.mainProps?.id ?? this.generatedInnerId;
  }

  /** Upstream's page style: minimum height and the fixed headers' offset. */
  @cached
  get pageStyle(): Record<string, string> {
    const { minHeight = '460px', offset } = this.args;
    const min = typeof minHeight === 'number' ? `${minHeight}px` : minHeight;
    return {
      'min-block-size': (this.args.grow ?? true) ? `max(${min}, 100vh)` : min,
      // Ember difference: fixed EuiHeaders pad <body> (see `offset`).
      'padding-block-start':
        offset === undefined || offset === null ? '0px' : `${offset}px`
    };
  }

  /**
   * Upstream `_EuiPageOuter` (`euiPageOuterStyles`, static). Upstream
   * flips to a column while `useIsWithinBreakpoints(responsive)`; here
   * that is a media query over the same breakpoints.
   */
  @cached
  get outerClass(): string {
    const context = getEuiThemeContext(this);
    const styles = euiPageOuterStyles;
    const responding = euiBreakpointsMedia(context.upstream, this.responsive);
    return euiClass(
      context,
      euiPageBoxSizing,
      styles.euiPageOuter,
      styles[this.args.direction ?? 'row'],
      responding && { [responding]: styles.column },
      (this.args.grow ?? true) && styles.grow,
      this.args.css
    );
  }

  /**
   * The layout settings that depend on whether there is a sidebar
   * (upstream counts its `EuiPageTemplate.Sidebar` children; here the
   * rendered `T.Sidebar`s register, see `sidebarCount`). One cached object
   * per case.
   */
  layoutFor(hasSidebar: boolean): ComposableLayout {
    const { panelled, contentBorder, bottomBorder, mainProps } = this.args;
    const innerPanelled = panelled ?? hasSidebar;
    const innerBordered = contentBorder ?? hasSidebar;
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiPageInnerStyles);
    const responding = euiBreakpointsMedia(context.upstream, this.responsive);
    const desktop = euiOutsideBreakpointsMedia(
      context.upstream,
      this.responsive
    );
    // Upstream `_EuiPageInner`: a top border while responding, else left.
    const border = innerBordered && [
      responding
        ? desktop && { [desktop]: styles.border.left }
        : styles.border.left,
      responding && { [responding]: styles.border.top }
    ];

    return {
      innerClass: euiClass(
        context,
        euiPageBoxSizing,
        styles.euiPageInner,
        innerPanelled && styles.panelled,
        border,
        mainProps?.css
      ),
      headerBottomBorder: bottomBorder ?? (hasSidebar ? true : 'extended'),
      emptyPromptPanelled: innerPanelled ? true : panelled
    };
  }

  /**
   * Number of rendered `T.Sidebar`s. Written as they render or go away,
   * never read and written in one go, so a sidebar rendering does not
   * invalidate something already read in the same render.
   */
  @tracked sidebarCount = 0;
  #sidebars = 0;

  sidebarRegistry: EuiPageTemplateSidebarRegistry = {
    register: () => {
      this.sidebarCount = ++this.#sidebars;
      return () => {
        this.#sidebars--;
        if (!isDestroying(this)) this.sidebarCount = this.#sidebars;
      };
    }
  };

  /**
   * The rendered main element, where `T.BottomBar`s render (upstream's
   * `bottomBar.parent`: the bar is portaled to the end of the main
   * content). Set once the element is in the DOM, like upstream's
   * frame-delayed lookup.
   */
  @tracked mainElement: HTMLElement | null = null;

  registerMain = functionModifier((element: Element) => {
    this.mainElement = element as HTMLElement;
    return () => {
      if (!isDestroying(this) && this.mainElement === element) {
        this.mainElement = null;
      }
    };
  });

  /** Upstream: the layout depends on whether there are sidebars. */
  get layout(): ComposableLayout {
    return this.sidebarCount > 0
      ? this.layoutWithSidebar
      : this.layoutWithoutSidebar;
  }

  @cached
  get layoutWithSidebar(): ComposableLayout {
    return this.layoutFor(true);
  }

  @cached
  get layoutWithoutSidebar(): ComposableLayout {
    return this.layoutFor(false);
  }

  #warnedLegacy = false;

  /** Fires the legacy API's deprecation once per instance. */
  deprecateLegacyApi = (): string => {
    if (!this.#warnedLegacy) {
      this.#warnedLegacy = true;
      deprecateRemovedUpstream(
        'eui-page-template-legacy',
        "EuiPageTemplate's legacy API (`@template`, `@pageHeader`, `@page…Props`, `@bottomBarProps`, `@fullHeight` and the `<:pageSideBar>`, `<:pageHeader…>` and `<:bottomBar>` blocks)",
        'Use the composable API: `<EuiPageTemplate as |T|>` with `T.Header`, `T.Section`, `T.EmptyPrompt` and `T.BottomBar`, and `T.Sidebar` in a `<:sidebar as |T|>` block.'
      );
    }
    return '';
  };

  // Legacy API

  /**
   * The legacy branch only renders when the default block takes no
   * params (see the template's `has-block-params`), so nothing reads this.
   */
  legacyParts = undefined as unknown as EuiPageTemplateParts;

  /** The legacy layouts take `'none'`, `'s'`, `'m'` or `'l'`. */
  get legacyPaddingSize(): 'none' | 's' | 'm' | 'l' | undefined {
    return this.args.paddingSize as 'none' | 's' | 'm' | 'l' | undefined;
  }

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

  /**
   * Upstream's `eui-fullHeight` utility class. Upstream EuiProvider injects
   * the utility classes globally; here the class name stays as a hook and
   * the rule comes from the extracted `euiFullHeight` mixin.
   */
  @cached
  get fullHeightUtility() {
    return `eui-fullHeight ${euiClass(getEuiThemeContext(this), euiFullHeight() as string)}`;
  }

  /** Upstream's `eui-yScroll` utility class (`euiYScroll` mixin). */
  @cached
  get yScrollUtility() {
    const context = getEuiThemeContext(this);
    return `eui-yScroll ${euiClass(context, euiYScroll(context.upstream) as string)}`;
  }

  /** Upstream `_EuiPageBottomBar`: hides wide flex margins, never shrinks. */
  @cached
  get bottomBarClass() {
    return [
      euiClass(getEuiThemeContext(this), { overflow: 'hidden', flexShrink: 0 }),
      this.args.bottomBarProps?.className
    ]
      .filter(Boolean)
      .join(' ');
  }

  get fullHeightClass() {
    return this.fullHeight && this.canFullHeight
      ? `${this.fullHeightUtility} `
      : '';
  }

  get yScrollClass() {
    return this.fullHeight && this.canFullHeight
      ? `${this.yScrollUtility} `
      : '';
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
    {{#if
      (or
        (has-block-params "default")
        (has-block "sidebar")
        this.hasComposableArgs
      )
    }}
      {{#let
        (hash
          BottomBar=(component
            EuiPageTemplateBottomBar
            restrictWidth=this.composableRestrictWidth
            paddingSize=this.composablePaddingSize
            parent=this.mainElement
          )
          Section=(component
            EuiPageSection
            restrictWidth=this.composableRestrictWidth
            paddingSize=this.composablePaddingSize
            color=this.sectionColor
            grow=true
          )
        )
        as |parts|
      }}
        <div
          class="euiPageTemplate {{this.outerClass}}"
          {{style this.pageStyle}}
          ...attributes
        >
          {{! Sidebars render (and register) before anything reads the count. }}
          {{#if (has-block "sidebar")}}
            {{yield
              (hash
                Sidebar=(component
                  EuiPageTemplateSidebar
                  paddingSize=this.composablePaddingSize
                  responsive=this.responsive
                  registry=this.sidebarRegistry
                )
              )
              to="sidebar"
            }}
          {{/if}}
          {{#let (element this.mainTag) as |Main|}}
            <Main
              id={{this.mainId}}
              class="{{this.layout.innerClass}} {{@mainProps.className}}"
              role={{@mainProps.role}}
              aria-label={{@mainProps.aria-label}}
              aria-labelledby={{@mainProps.aria-labelledby}}
              data-test-subj={{@mainProps.data-test-subj}}
              {{style this.mainStyle}}
              {{this.registerMain}}
            >
              {{yield
                (hash
                  Sidebar=(component
                    EuiPageTemplateSidebar
                    paddingSize=this.composablePaddingSize
                    responsive=this.responsive
                  )
                  Header=(component
                    EuiPageHeader
                    restrictWidth=this.composableRestrictWidth
                    paddingSize=this.composablePaddingSize
                    bottomBorder=this.layout.headerBottomBorder
                    color=this.sectionColor
                  )
                  Section=parts.Section
                  EmptyPrompt=(component
                    EuiPageTemplateEmptyPrompt
                    panelled=this.layout.emptyPromptPanelled
                    grow=true
                  )
                  BottomBar=parts.BottomBar
                )
                to="default"
              }}
            </Main>
          {{/let}}
        </div>
      {{/let}}
    {{else}}
    {{this.deprecateLegacyApi}}
    {{#let
      (argOrDefault @grow true)
      (argOrDefault this.legacyPaddingSize "l")
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
                        class={{this.fullHeightUtility}}
                        @gutterSize="none"
                        @direction="column"
                        @responsive={{false}}
                      >
                        <EuiFlexItem
                          class={{classNames
                            (if (eq this.fullHeight true) this.yScrollUtility)
                            (if
                              (eq this.fullHeight "noscroll") this.fullHeightUtility
                            )
                          }}
                          @grow={{true}}
                        >
                          {{yield this.legacyParts to="default"}}
                        </EuiFlexItem>
                      </EuiFlexGroup>
                    {{else}}
                      {{yield this.legacyParts to="default"}}
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
                          class={{this.fullHeightUtility}}
                          @gutterSize="none"
                          @direction="column"
                          @responsive={{false}}
                        >
                          <EuiFlexItem
                            class={{classNames
                              (if (eq this.fullHeight true) this.yScrollUtility)
                              (if
                                (eq this.fullHeight "noscroll") this.fullHeightUtility
                              )
                            }}
                            @grow={{true}}
                          >
                            {{yield this.legacyParts to="default"}}
                          </EuiFlexItem>
                        </EuiFlexGroup>
                      {{else}}
                        {{yield this.legacyParts to="default"}}
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
                        class={{this.fullHeightUtility}}
                        @gutterSize="none"
                        @direction="column"
                        @responsive={{false}}
                      >
                        <EuiFlexItem
                          class={{classNames
                            (if (eq this.fullHeight true) this.yScrollUtility)
                            (if
                              (eq this.fullHeight "noscroll") this.fullHeightUtility
                            )
                          }}
                          @grow={{true}}
                        >
                          {{yield this.legacyParts to="default"}}
                        </EuiFlexItem>
                      </EuiFlexGroup>
                    {{else}}
                      {{yield this.legacyParts to="default"}}
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
                          class={{this.fullHeightUtility}}
                          @gutterSize="none"
                          @direction="column"
                          @responsive={{false}}
                        >
                          <EuiFlexItem
                            class={{classNames
                              (if (eq this.fullHeight true) this.yScrollUtility)
                              (if
                                (eq this.fullHeight "noscroll") this.fullHeightUtility
                              )
                            }}
                            @grow={{true}}
                          >
                            {{yield this.legacyParts to="default"}}
                          </EuiFlexItem>
                        </EuiFlexGroup>
                      {{else}}
                        {{yield this.legacyParts to="default"}}
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
                        class={{this.fullHeightUtility}}
                        @gutterSize="none"
                        @direction="column"
                        @responsive={{false}}
                      >
                        <EuiFlexItem
                          class={{classNames
                            (if (eq this.fullHeight true) this.yScrollUtility)
                            (if
                              (eq this.fullHeight "noscroll") this.fullHeightUtility
                            )
                          }}
                          @grow={{true}}
                        >
                          {{yield this.legacyParts to="default"}}
                        </EuiFlexItem>
                      </EuiFlexGroup>
                    {{else}}
                      {{yield this.legacyParts to="default"}}
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
                        class={{this.fullHeightUtility}}
                        @gutterSize="none"
                        @direction="column"
                        @responsive={{false}}
                      >
                        <EuiFlexItem
                          class={{classNames
                            (if (eq this.fullHeight true) this.yScrollUtility)
                            (if
                              (eq this.fullHeight "noscroll") this.fullHeightUtility
                            )
                          }}
                          @grow={{true}}
                        >
                          {{yield this.legacyParts to="default"}}
                        </EuiFlexItem>
                      </EuiFlexGroup>
                    {{else}}
                      {{yield this.legacyParts to="default"}}
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
                          class={{this.fullHeightUtility}}
                          @gutterSize="none"
                          @direction="column"
                          @responsive={{false}}
                        >
                          <EuiFlexItem
                            class={{classNames
                              (if (eq this.fullHeight true) this.yScrollUtility)
                              (if
                                (eq this.fullHeight "noscroll") this.fullHeightUtility
                              )
                            }}
                            @grow={{true}}
                          >
                            {{yield this.legacyParts to="default"}}
                          </EuiFlexItem>
                        </EuiFlexGroup>
                      {{else}}
                        {{yield this.legacyParts to="default"}}
                      {{/if}}
                    </EuiPageContentBody>
                  </EuiPageContent>
                </EuiPageBody>
                {{#if hasBottomBarBlock}}
                  <EuiBottomBar
                    class={{this.bottomBarClass}}
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
                        class={{this.fullHeightUtility}}
                        @gutterSize="none"
                        @direction="column"
                        @responsive={{false}}
                      >
                        <EuiFlexItem
                          class={{classNames
                            (if (eq this.fullHeight true) this.yScrollUtility)
                            (if
                              (eq this.fullHeight "noscroll") this.fullHeightUtility
                            )
                          }}
                          @grow={{true}}
                        >
                          {{yield this.legacyParts to="default"}}
                        </EuiFlexItem>
                      </EuiFlexGroup>
                    {{else}}
                      {{yield this.legacyParts to="default"}}
                    {{/if}}
                  </EuiPageContentBody>
                </EuiPageContent>
                {{#if hasBottomBarBlock}}
                  <EuiBottomBar
                    class={{this.bottomBarClass}}
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
    {{/if}}
  </template>
}
