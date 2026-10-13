import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import style from 'ember-style-modifier/modifiers/style';
import { and, not, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  euiPageBoxSizing,
  euiPagePadding,
  euiPageRestrictWidthStyle,
  euiScreenReaderOnlyCss
} from '../utils/eui/page-layout.ts';
import spreadAttributes from '../-private/eui-spread-attributes.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import {
  euiMaxBreakpoint,
  euiPageHeaderContentStyles,
  euiPageHeaderStyles
} from '../utils/eui/styles.generated.ts';
import EuiBreadcrumbs from './eui-breadcrumbs.gts';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiIcon from './eui-icon.gts';
import EuiSpacer from './eui-spacer.gts';
import EuiTab from './eui-tab.gts';
import EuiTabs from './eui-tabs.gts';
import EuiText from './eui-text.gts';
import EuiTitle from './eui-title.gts';

import type { EuiPagePaddingSize } from '../utils/eui/page-layout.ts';
import type { EuiButtomBarArgs } from './eui-bottom-bar';
import type { EuiBreadcrumbsSignature } from './eui-breadcrumbs';
import type { EuiTabsSignature } from './eui-tabs';
import type { EuiTitleSignature } from './eui-title';
import type { EuiFlexGroupSignature } from './eui-flex-group';
import type { EuiFlexGroupAlignItems } from './eui-flex-group';
import type { EuiIconSignature } from './eui-icon';
import type { IEuiTab } from './eui-tab';
import type { TOC } from '@ember/component/template-only';
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
  /** @deprecated Has no effect (EuiPageTemplate arg). */
  template?: (typeof TEMPLATES)[number];
  /** @deprecated Has no effect (EuiPageTemplate arg). */
  bottomBarProps?: EuiButtomBarArgs;
  /** @deprecated Has no effect (EuiPageTemplate arg). */
  fullHeight?: boolean;
  /** @deprecated Has no effect (EuiPageTemplate arg). */
  minHeight?: number;

  /** Max width of the content, centered; see EuiPageHeader. */
  restrictWidth?: boolean | string | number;

  /**
   * Block padding (top and bottom; only top above bottom tabs, only
   * bottom below title tabs), see EuiPageHeader. Defaults to `'none'`.
   */
  paddingSize?: EuiPagePaddingSize;

  /**
   * Adds a border below the content. Without padding, it also gets an
   * `l` bottom padding, as upstream.
   */
  bottomBorder?: boolean;

  /** @deprecated Has no effect (EuiPageTemplate arg). */
  bodyBottomBorder?: boolean;

  /** @deprecated Has no effect (EuiPageTemplate arg). */
  bodyProps?: {
    paddingSize?: 'none' | 's' | 'm' | 'l';
  };
  /** @deprecated Has no effect (EuiPageTemplate arg). */
  contentProps?: {
    paddingSize?: 'none' | 's' | 'm' | 'l';
  };

  /** See EuiPageHeader's `@alignItems`. */
  alignItems?: 'top' | 'bottom' | 'center' | 'stretch';

  /** See EuiPageHeader's `@responsive`. Defaults to `true`. */
  responsive?: boolean | 'reverse';

  /** @private Render the `<:description>` block. Defaults to `true`. */
  hasDescriptionBlock?: boolean;

  /** @private Render the `<:rightSideItems>` block. Defaults to `true`. */
  hasRightSideItemsBlock?: boolean;

  /** @private Render the `<:pageTitle>` block. Defaults to `true`. */
  hasPageTitleBlock?: boolean;

  /** @private Render the `<:default>` block. Defaults to `true`. */
  hasDefaultBlock?: boolean;

  /** The page's title. */
  pageTitle?: string;

  /** Breadcrumbs above the title. */
  breadcrumbs?: EuiBreadcrumbsSignature['Args']['breadcrumbs'];

  /**
   * Props for the breadcrumbs: `className`, the `EuiBreadcrumbs` args
   * (`responsive`, `truncate`, `max`, `type`, `lastBreadcrumbIsCurrentPage`,
   * `css`) and any other key as an attribute (`aria-label`, `data-test-subj`).
   */
  breadcrumbProps?: Partial<
    Omit<EuiBreadcrumbsSignature['Args'], 'breadcrumbs'>
  > & { className?: string; [attribute: string]: unknown };

  /**
   * Props for the right side items group: `className`, the `EuiFlexGroup`
   * args (`gutterSize`, `alignItems`, `justifyContent`, `direction`, `wrap`,
   * `responsive`, `css`) and any other key as an attribute.
   */
  rightSideGroupProps?: Partial<EuiFlexGroupSignature['Args']> & {
    className?: string;
    [attribute: string]: unknown;
  };

  /**
   * Props for the title: `className`, `textTransform`, `css` and any other
   * key as an attribute (they land on the `<h1>`).
   */
  pageTitleProps?: Partial<
    Pick<EuiTitleSignature['Args'], 'textTransform' | 'css'>
  > & { className?: string; [attribute: string]: unknown };

  /** Icon before the title. */
  iconType?: EuiIconSignature['Args']['type'];

  /** Text under the title. */
  description?: string;

  /**
   * Props for the icon: `className`, the `EuiIcon` args (`size`, `color`,
   * `title`, `titleId`, `css`) and any other key as an attribute.
   */
  iconProps?: Partial<Omit<EuiIconSignature['Args'], 'type'>> & {
    className?: string;
    [attribute: string]: unknown;
  };

  /**
   * Props for the tabs: `className`, `display` and any other key as an
   * attribute (`aria-label`, `data-test-subj`).
   */
  tabsProps?: Partial<Pick<EuiTabsSignature['Args'], 'display'>> & {
    className?: string;
    [attribute: string]: unknown;
  };

  /** Tabs, see EuiPageHeader's `@tabs`. */
  tabs?: Tab[];
};

/** @private The layout inside EuiPageHeader; use EuiPageHeader. */
export interface EuiPageHeaderContentSignature {
  Element: HTMLDivElement;
  Args: EuiPageHeaderContentProps;
  Blocks: {
    /** Extra content. */
    default: [];
    /** The title. */
    pageTitle: [];
    /** The description. */
    description: [];
    /** Right side items; yields an `EuiFlexItem` to wrap each in. */
    rightSideItems: [WithBoundArgs<typeof EuiFlexItem, 'grow'>?];
  };
}

interface Presence {
  title: unknown;
  description: unknown;
  right: unknown;
  children: unknown;
}

const ALIGN_ITEMS: Record<string, EuiFlexGroupAlignItems> = {
  top: 'flexStart',
  bottom: 'flexEnd',
  center: 'center',
  stretch: 'stretch'
};

const BREADCRUMB_ARGS = [
  'responsive',
  'truncate',
  'max',
  'type',
  'lastBreadcrumbIsCurrentPage'
] as const;
const TABS_ARGS = ['display'] as const;
const TITLE_ARGS = ['textTransform'] as const;
const ICON_ARGS = ['size', 'color', 'title', 'titleId'] as const;
const GROUP_ARGS = [
  'gutterSize',
  'alignItems',
  'justifyContent',
  'direction',
  'wrap',
  'responsive',
  'tagName'
] as const;

const HeaderTabs: TOC<{
  Args: { tabs: Tab[]; tabsProps?: EuiPageHeaderContentProps['tabsProps'] };
}> = <template>
  <EuiTabs
    @display={{@tabsProps.display}}
    @size="m"
    @bottomBorder={{false}}
    class={{@tabsProps.className}}
    {{spreadAttributes @tabsProps TABS_ARGS}}
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
</template>;

/**
 * Upstream `EuiPageHeaderContent` (`euiPageHeaderContentStyles`): the
 * header's layout, padding and bottom border.
 */
export default class EuiPageHeaderContent extends Component<EuiPageHeaderContentSignature> {
  get context() {
    return getEuiThemeContext(this);
  }

  @cached
  get styles() {
    return useEuiBorealisStyles(this.context, euiPageHeaderContentStyles);
  }

  /** Upstream's padding/border rules, which depend on what is rendered. */
  layout = (present: Presence) => {
    const { tabs } = this.args;
    const hasTabs = !!tabs;
    const title = !!present.title;
    const onlyChildren =
      !hasTabs &&
      !title &&
      !present.right &&
      !present.description &&
      !!present.children;
    const onlyTabs =
      hasTabs &&
      !title &&
      !present.right &&
      !present.description &&
      !present.children;
    let paddingSize = this.args.paddingSize ?? 'none';
    let bottomBorder = this.args.bottomBorder;
    let sides: 'vertical' | 'top' | 'bottom' = 'vertical';
    if (onlyTabs) {
      paddingSize = 'none';
    } else if (hasTabs && !title) {
      sides = 'bottom';
    } else if (hasTabs && title) {
      sides = 'top';
      bottomBorder = bottomBorder === false ? false : true;
    } else if (paddingSize === 'none' && bottomBorder) {
      sides = 'bottom';
      paddingSize = 'l';
    }
    const context = this.context;
    const styles = this.styles;
    const pageHeader = useEuiBorealisStyles(context, euiPageHeaderStyles);
    const responsive = this.args.responsive ?? true;
    return {
      onlyChildren,
      tabsAsTitle: hasTabs && !title,
      tabsAtBottom: hasTabs && title,
      root: euiClass(
        context,
        euiPageBoxSizing,
        styles.euiPageHeaderContent,
        bottomBorder && pageHeader.border,
        euiPagePadding(context.upstream, paddingSize, sides)
      ),
      childrenOnly: euiClass(
        context,
        euiPageBoxSizing,
        styles.childrenOnly.flex,
        styles[this.args.alignItems ?? 'center'],
        responsive && {
          [euiMaxBreakpoint(context.upstream, 'm') as string]:
            responsive === 'reverse'
              ? styles.childrenOnly.responsiveReverse
              : styles.childrenOnly.responsive
        }
      )
    };
  };

  get widthStyle() {
    return euiPageRestrictWidthStyle(this.args.restrictWidth);
  }

  // Upstream's `css` on the EuiFlexGroup/EuiFlexItem children.
  @cached
  get topCss(): EuiCss {
    return this.styles.euiPageHeaderContent__top;
  }

  @cached
  get leftCss(): EuiCss {
    return this.styles.euiPageHeaderContent__leftSideItems;
  }

  /**
   * Upstream renders the right side first at small breakpoints with
   * `responsive="reverse"`; Ember keeps the DOM order and reorders it
   * visually below the same breakpoint.
   */
  @cached
  get rightCss(): EuiCss {
    const upstream = this.context.upstream;
    return [
      this.styles.euiPageHeaderContent__rightSideItems,
      { '& > .euiFlexItem': this.styles.euiPageHeaderContent__rightSideItem },
      this.args.responsive === 'reverse' && {
        [euiMaxBreakpoint(upstream, 'm') as string]: { order: -1 }
      },
      this.args.rightSideGroupProps?.css
    ];
  }

  breadcrumbArgs = BREADCRUMB_ARGS;
  titleArgs = TITLE_ARGS;
  iconArgs = ICON_ARGS;
  groupArgs = GROUP_ARGS;

  /** Upstream's `iconProps.css` composed after the title icon styles. */
  @cached
  get iconCss(): EuiCss {
    return [this.titleIconCss, this.args.iconProps?.css];
  }

  /** Upstream's `iconProps.css`, composed into EuiIcon's own class. */
  @cached
  get titleIconCss(): EuiCss {
    return this.styles.euiPageHeaderContent__titleIcon;
  }

  @cached
  get screenReaderOnlyClass() {
    return euiClass(this.context, euiScreenReaderOnlyCss);
  }

  get selectedTabLabel() {
    return this.args.tabs?.find((tab) => tab.isSelected === true)?.label;
  }

  <template>
    {{#let
      (argOrDefault @responsive true)
      (and (argOrDefault @hasDescriptionBlock true) (has-block "description"))
      (and
        (argOrDefault @hasRightSideItemsBlock true) (has-block "rightSideItems")
      )
      (or
        (and (argOrDefault @hasPageTitleBlock true) (has-block "pageTitle"))
        @pageTitle
      )
      (and (argOrDefault @hasDefaultBlock true) (has-block "default"))
      as |responsive hasDescriptionBlock hasRightSideItemsBlock hasPageTitleBlock hasDefaultBlock|
    }}
      {{#let
        (this.layout
          (hash
            title=hasPageTitleBlock
            description=(or hasDescriptionBlock @description)
            right=hasRightSideItemsBlock
            children=hasDefaultBlock
          )
        )
        as |layout|
      }}
        <div
          class="euiPageHeaderContent {{layout.root}}"
          {{style this.widthStyle}}
          ...attributes
        >
          {{#if layout.onlyChildren}}
            <div class={{layout.childrenOnly}}>
              {{yield to="default"}}
            </div>
          {{else}}
            {{#if @breadcrumbs}}
              <EuiBreadcrumbs
                @breadcrumbs={{@breadcrumbs}}
                @responsive={{@breadcrumbProps.responsive}}
                @truncate={{@breadcrumbProps.truncate}}
                @max={{@breadcrumbProps.max}}
                @type={{@breadcrumbProps.type}}
                @lastBreadcrumbIsCurrentPage={{@breadcrumbProps.lastBreadcrumbIsCurrentPage}}
                @css={{@breadcrumbProps.css}}
                class={{@breadcrumbProps.className}}
                {{spreadAttributes @breadcrumbProps this.breadcrumbArgs}}
              />
              <EuiSpacer @size="s" />
            {{/if}}
            <EuiFlexGroup
              class="euiPageHeaderContent__top"
              @css={{this.topCss}}
              @responsive={{not (not responsive)}}
              @alignItems={{if @alignItems (this.alignItems @alignItems)}}
              @gutterSize="l"
              @wrap={{true}}
            >
              <EuiFlexItem @grow={{2}} @css={{this.leftCss}}>
                {{#if layout.tabsAsTitle}}
                  <h1 class={{this.screenReaderOnlyClass}}>
                    {{this.selectedTabLabel}}
                  </h1>
                  {{! @glint-expect-error tabs is set when tabsAsTitle }}
                  <HeaderTabs @tabs={{@tabs}} @tabsProps={{@tabsProps}} />
                {{else if hasPageTitleBlock}}
                  <EuiTitle
                    class={{@pageTitleProps.className}}
                    @size="l"
                    @tagName="h1"
                    @textTransform={{@pageTitleProps.textTransform}}
                    @css={{@pageTitleProps.css}}
                    {{spreadAttributes @pageTitleProps this.titleArgs}}
                  >
                    {{#if @iconType}}
                      <EuiIcon
                        @size={{if @iconProps.size @iconProps.size "xl"}}
                        @type={{@iconType}}
                        @color={{@iconProps.color}}
                        @title={{@iconProps.title}}
                        @titleId={{@iconProps.titleId}}
                        {{spreadAttributes @iconProps this.iconArgs}}
                        @iconClasses={{classNames
                          "euiPageHeaderContent__titleIcon"
                          @iconProps.className
                        }}
                        @css={{this.iconCss}}
                      />
                    {{/if}}
                    {{@pageTitle}}
                    {{yield to="pageTitle"}}
                  </EuiTitle>
                {{/if}}

                {{#if (or hasDescriptionBlock @description)}}
                  {{#if (or hasPageTitleBlock @tabs)}}
                    <EuiSpacer />
                  {{/if}}
                  <EuiText @grow={{false}}>
                    {{#if @description}}
                      <p>{{@description}}</p>
                    {{/if}}
                    {{#if hasDescriptionBlock}}
                      {{yield to="description"}}
                    {{/if}}
                  </EuiText>
                {{/if}}

                {{#if hasDefaultBlock}}
                  <EuiSpacer />
                  {{yield to="default"}}
                {{/if}}
              </EuiFlexItem>
              {{#if hasRightSideItemsBlock}}
                <EuiFlexGroup
                  @gutterSize={{if
                    @rightSideGroupProps.gutterSize
                    @rightSideGroupProps.gutterSize
                    "m"
                  }}
                  @responsive={{argOrDefault
                    @rightSideGroupProps.responsive
                    false
                  }}
                  @wrap={{argOrDefault @rightSideGroupProps.wrap true}}
                  @alignItems={{@rightSideGroupProps.alignItems}}
                  @justifyContent={{@rightSideGroupProps.justifyContent}}
                  @direction={{@rightSideGroupProps.direction}}
                  @tagName={{@rightSideGroupProps.tagName}}
                  class={{classNames
                    "euiPageHeaderContent__rightSideItems"
                    @rightSideGroupProps.className
                  }}
                  @css={{this.rightCss}}
                  {{spreadAttributes @rightSideGroupProps this.groupArgs}}
                >
                  {{yield
                    (component EuiFlexItem grow=false)
                    to="rightSideItems"
                  }}
                </EuiFlexGroup>
              {{/if}}
            </EuiFlexGroup>
            {{#if layout.tabsAtBottom}}
              <div class="euiPageHeaderContent__bottom">
                <EuiSpacer />
                {{! @glint-expect-error tabs is set when tabsAtBottom }}
                <HeaderTabs @tabs={{@tabs}} @tabsProps={{@tabsProps}} />
              </div>
            {{/if}}
          {{/if}}
        </div>
      {{/let}}
    {{/let}}
  </template>

  alignItems = (value: string) => ALIGN_ITEMS[value];
}
