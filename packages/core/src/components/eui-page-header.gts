import { concat } from '@ember/helper';

import style from 'ember-style-modifier/modifiers/style';
import { and,eq, not, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import euiPageRestrictWidth from '../helpers/eui-page-restrict-width';
import EuiPageHeaderContent from './eui-page-header-content.gts';

import type { paddingSizeMapping } from '../utils/css-mappings/eui-page-content-body';
import type { EuiIconSignature } from './eui-icon';
import type { EuiPageHeaderContentSignature } from './eui-page-header-content';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiPageHeaderSignature {
  Element: Element;
  Args: {
    /**
     * Sets the padding around the content
     */
    paddingSize?: keyof typeof paddingSizeMapping;
    /**
     * Adds a bottom border to the header
     */
    bottomBorder?: boolean;
    /**
     * Sets the width of the header to `restricted` (992px) or `full` (100%)
     */
    restrictWidth?: boolean | 'full';
    /**
     * Sets the alignment of the content within the header
     */
    alignItems?: EuiPageHeaderContentSignature['Args']['alignItems'];
    /**
     * Sets the header to be responsive and collapse to a single line
     */
    responsive?: boolean | 'reverse';
    /**
     * Sets the icon type for the header
     */
    iconType?: EuiIconSignature['Args']['type'];
    /**
     * Sets the breadcrumbs for the header
     */
    breadcrumbs?: any[];
    /**
     * Sets the tabs for the header
     */
    tabs?: any[];
    /**
     * Sets the description for the header
     */
    description?: string;
    /**
     * Sets the title for the header
     */
    pageTitle?: string;

    /**
     * Sets the props for the title
     */
    pageTitleProps?: EuiPageHeaderContentSignature['Args']['pageTitleProps'];

    /**
     * Sets the right side items for the header
     */
    rightSideItems?: any[];
    /**
     * Sets the default content for the header
     */
    default?: any[];
    /**
     * Sets the default content for the header
     */
    hasDefaultBlock?: boolean;
    /**
     * Sets the description content for the header
     */
    hasDescriptionBlock?: boolean;
    /**
     * Sets the page title content for the header
     */
    hasPageTitleBlock?: boolean;
    /**
     * Sets the right side items content for the header
     */
    hasRightSideItemsBlock?: boolean;

    style?: {
      [key: string]: string;
    };
  };
  Blocks: {
    default: [];
    description: [];
    pageTitle: [];
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
