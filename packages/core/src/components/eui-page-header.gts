import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import style from 'ember-style-modifier/modifiers/style';
import { and, eq, not, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  euiPageBoxSizing,
  euiPagePadding
} from '../utils/eui/page-layout.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiBackgroundColor,
  euiPageHeaderStyles
} from '../utils/eui/styles.generated.ts';
import EuiPageHeaderContent from './eui-page-header-content.gts';

import type { EuiPagePaddingSize } from '../utils/eui/page-layout.ts';
import type { EuiIconSignature } from './eui-icon';
import type { EuiPageHeaderContentSignature } from './eui-page-header-content';

/**
 * The top of a page: breadcrumbs, title (with icon), description, tabs and
 * actions on the right.
 */
export interface EuiPageHeaderSignature {
  Element: Element;
  Args: {
    /**
     * Padding: `'none'`, `'xs'`, `'s'`, `'m'`, `'l'` or `'xl'`. Inline
     * padding goes on the header, block padding on its content (see
     * `@bottomBorder`). Defaults to `'none'`.
     */
    paddingSize?: EuiPagePaddingSize;
    /**
     * Adds a border below the content (`true`, within the max width) or
     * across the whole header (`'extended'`). With no padding, a `true`
     * border also gets an `l` bottom padding, as upstream. Title + tabs
     * headers get the border unless this is `false`.
     */
    bottomBorder?: boolean | 'extended';
    /**
     * Max width of the header's content, centered: `true` for EUI's
     * default (1200px), a number in px or any CSS width. The header itself
     * stays full width. Defaults to `false`.
     */
    restrictWidth?: boolean | number | string;
    /**
     * Background: `'transparent'`, `'plain'`, `'subdued'`, … (EuiPanel
     * colors). Defaults to `'transparent'`.
     */
    color?: string;
    /**
     * Vertical alignment of the title and the right side items: `'top'`,
     * `'bottom'`, `'center'` or `'stretch'`. Defaults to stretching the
     * items (centered for a header with only a default block).
     */
    alignItems?: EuiPageHeaderContentSignature['Args']['alignItems'];
    /**
     * Stacks the right side items under the title below the theme's `m`
     * breakpoint; `'reverse'` puts them above it. Defaults to `true`.
     */
    responsive?: boolean | 'reverse';
    /** Icon before the title, e.g. the app's logo. */
    iconType?: EuiIconSignature['Args']['type'];
    /** Breadcrumbs above the title, see `EuiBreadcrumbs`'s `@breadcrumbs`. */
    breadcrumbs?: any[];
    /**
     * Tabs under the title (or as the title, without `@pageTitle`):
     * `[{ label: 'Overview', isSelected: true, onClick }, …]`, also taking
     * `id`, `href` and `disabled`.
     */
    tabs?: any[];
    /** Text under the title. Use the `<:description>` block for markup. */
    description?: string;
    /** The page's title (an `<h1>`). Use the `<:pageTitle>` block for markup. */
    pageTitle?: string;

    /**
     * Props for the title: `className`, `textTransform`, `css` and any other
     * key as an attribute of the `<h1>` (`aria-label`, `data-test-subj`).
     */
    pageTitleProps?: EuiPageHeaderContentSignature['Args']['pageTitleProps'];
    /**
     * Props for the icon: `className`, `size`, `color`, `title`, `titleId`,
     * `css` and any other key as an attribute.
     */
    iconProps?: EuiPageHeaderContentSignature['Args']['iconProps'];
    /** Props for the tabs: `className`, `display` and any attribute. */
    tabsProps?: EuiPageHeaderContentSignature['Args']['tabsProps'];
    /**
     * Props for the breadcrumbs: `className`, `EuiBreadcrumbs` args and any
     * attribute.
     */
    breadcrumbProps?: EuiPageHeaderContentSignature['Args']['breadcrumbProps'];
    /**
     * Props for the right side items group: `className`, `EuiFlexGroup`
     * args and any attribute.
     */
    rightSideGroupProps?: EuiPageHeaderContentSignature['Args']['rightSideGroupProps'];

    /**
     * @deprecated Has no effect on its own: put the items in the
     * `<:rightSideItems>` block.
     */
    rightSideItems?: any[];
    /** @deprecated Has no effect, use the `<:default>` block. */
    default?: any[];
    /** @private Render the `<:default>` block. Defaults to `true`. */
    hasDefaultBlock?: boolean;
    /** @private Render the `<:description>` block. Defaults to `true`. */
    hasDescriptionBlock?: boolean;
    /** @private Render the `<:pageTitle>` block. Defaults to `true`. */
    hasPageTitleBlock?: boolean;
    /** @private Render the `<:rightSideItems>` block. Defaults to `true`. */
    hasRightSideItemsBlock?: boolean;

    /** Inline styles of the header (the max width goes on its content). */
    style?: {
      [key: string]: string;
    };
  };
  Blocks: {
    /** Extra content under the title and description. */
    default: [];
    /** The description, instead of `@description`. */
    description: [];
    /** The title, instead of `@pageTitle`. */
    pageTitle: [];
    /**
     * Actions on the right, e.g. buttons. Wrap each in the yielded item:
     * `<:rightSideItems as |Item|><Item><EuiButton …/></Item></:rightSideItems>`.
     */
    rightSideItems: EuiPageHeaderContentSignature['Blocks']['rightSideItems'];
  };
}

/** Upstream `EuiPageHeader` (`euiPageHeaderStyles`) on the Borealis theme. */
export default class EuiPageHeader extends Component<EuiPageHeaderSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const upstream = context.upstream;
    const styles = useEuiBorealisStyles(context, euiPageHeaderStyles);
    // Same order as upstream's `cssStyles`.
    return euiClass(
      context,
      euiPageBoxSizing,
      styles.euiPageHeader,
      euiPagePadding(upstream, this.args.paddingSize ?? 'none', 'horizontal'),
      this.args.bottomBorder === 'extended' && styles.border,
      {
        backgroundColor: euiBackgroundColor(
          upstream,
          this.args.color ?? 'transparent'
        )
      }
    );
  }

  get inlineStyle() {
    return this.args.style ?? {};
  }

  <template>
    {{#let
      (argOrDefault @responsive true)
      (and (argOrDefault @hasDefaultBlock true) (has-block "default"))
      (or
        (and (argOrDefault @hasDescriptionBlock true) (has-block "description"))
        @description
      )
      (or
        (and (argOrDefault @hasPageTitleBlock true) (has-block "pageTitle"))
        @pageTitle
      )
      (and
        (argOrDefault @hasRightSideItemsBlock true) (has-block "rightSideItems")
      )
      as |responsive hasDefaultBlock hasDescriptionBlock hasPageTitleBlock hasRightSideItemsBlock|
    }}
      <header
        class="euiPageHeader {{this.classes}}"
        {{style this.inlineStyle}}
        ...attributes
      >
        <EuiPageHeaderContent
          @alignItems={{@alignItems}}
          @responsive={{responsive}}
          @paddingSize={{@paddingSize}}
          @bottomBorder={{if (eq @bottomBorder "extended") false @bottomBorder}}
          @pageTitle={{@pageTitle}}
          @pageTitleProps={{@pageTitleProps}}
          @iconProps={{@iconProps}}
          @tabsProps={{@tabsProps}}
          @breadcrumbProps={{@breadcrumbProps}}
          @rightSideGroupProps={{@rightSideGroupProps}}
          @iconType={{@iconType}}
          @breadcrumbs={{@breadcrumbs}}
          @tabs={{@tabs}}
          @description={{@description}}
          @restrictWidth={{@restrictWidth}}
          @hasDescriptionBlock={{not (not hasDescriptionBlock)}}
          @hasPageTitleBlock={{not (not hasPageTitleBlock)}}
          @hasRightSideItemsBlock={{not (not hasRightSideItemsBlock)}}
          @hasDefaultBlock={{not (not hasDefaultBlock)}}
        >
          <:pageTitle>
            {{yield to="pageTitle"}}
          </:pageTitle>
          <:rightSideItems as |item|>
            {{yield item to="rightSideItems"}}
          </:rightSideItems>
          <:description>
            {{yield to="description"}}
          </:description>
          <:default>
            {{yield to="default"}}
          </:default>
        </EuiPageHeaderContent>
      </header>
    {{/let}}
  </template>
}
