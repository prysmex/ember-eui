import { concat } from '@ember/helper';

import style from 'ember-style-modifier/modifiers/style';
import { and,eq, not, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import euiPageRestrictWidth from '../helpers/eui-page-restrict-width.ts';
import EuiPageHeaderContent from './eui-page-header-content.gts';

import type { paddingSizeMapping } from '../utils/css-mappings/eui-page-content-body.ts';
import type { EuiIconSignature } from './eui-icon';
import type { EuiPageHeaderContentSignature } from './eui-page-header-content';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * The top of a page: breadcrumbs, title (with icon), description, tabs and
 * actions on the right.
 */
export interface EuiPageHeaderSignature {
  Element: Element;
  Args: {
    /** Padding around the header: `'none'`, `'s'`, `'m'` or `'l'`. */
    paddingSize?: keyof typeof paddingSizeMapping;
    /** Adds a border below the header. */
    bottomBorder?: boolean;
    /**
     * Max width of the header: `true` for EUI's default, a number in px or
     * any CSS width. Defaults to `false` (full width).
     */
    restrictWidth?: boolean | 'full' | number | string;
    /**
     * Vertical alignment of the title and the right side items: `'top'`,
     * `'bottom'`, `'center'` or `'stretch'`. Defaults to `'center'`.
     */
    alignItems?: EuiPageHeaderContentSignature['Args']['alignItems'];
    /**
     * Stacks the right side items under the title on small screens;
     * `'reverse'` puts them above it. Defaults to `true`.
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

    /** Props for the title: `{ className }`. */
    pageTitleProps?: EuiPageHeaderContentSignature['Args']['pageTitleProps'];

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

    /** Inline styles, merged with the max width. */
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

const EuiPageHeader: TemplateOnlyComponent<EuiPageHeaderSignature> = <template>
  {{#let
    (euiPageRestrictWidth (argOrDefault @restrictWidth false) @style)
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
    (or
      (and
        (argOrDefault @hasRightSideItemsBlock true) (has-block "rightSideItems")
      )
      @rightSideItems
    )
    as |styling responsive hasDefaultBlock hasDescriptionBlock hasPageTitleBlock hasRightSideItemsBlock|
  }}
    {{#let
      (classNames
        (if
          styling.widthClassName
          (concat "euiPageHeader--" styling.widthClassName)
        )
        (if @bottomBorder "euiPageHeader--bottomBorder")
        (if responsive "euiPageHeader--responsive")
        (if (eq responsive "reverse") "euiPageHeader--responsiveReverse")
        (if (and hasPageTitleBlock @tabs) "euiPageHeader--tabsAtBottom")
        (if
          (and
            @tabs
            (not hasPageTitleBlock)
            (not hasRightSideItemsBlock)
            (not hasDescriptionBlock)
            (not hasDefaultBlock)
          )
          "euiPageHeader--onlyTabs"
        )
        (if
          @alignItems
          (concat "euiPageHeader--" @alignItems)
          "euiPageHeader--center"
        )
        componentName="EuiPageHeader"
        paddingSize=@paddingSize
      )
      as |classes|
    }}
      {{#if
        (and
          (not @tabs)
          (not hasPageTitleBlock)
          (not hasDescriptionBlock)
          (not hasRightSideItemsBlock)
        )
      }}
        <header class={{classes}} {{style styling.newStyle}} ...attributes>
          {{yield to="default"}}
        </header>
      {{else}}
        {{!template-lint-disable}}
        <header class={{classes}} {{style styling.newStyle}} ...attributes>
          <EuiPageHeaderContent
            @alignItems={{@alignItems}}
            @responsive={{responsive}}
            @pageTitle={{@pageTitle}}
            @pageTitleProps={{@pageTitleProps}}
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
      {{/if}}
    {{/let}}
  {{/let}}
</template>;

export default EuiPageHeader;
