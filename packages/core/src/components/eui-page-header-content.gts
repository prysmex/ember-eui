import Component from '@glimmer/component';
import { array } from '@ember/helper';
import { on } from '@ember/modifier';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import style from 'ember-style-modifier/modifiers/style';
import { and, eq, not, or } from 'ember-truth-helpers';

import argOrDefault, {
  argOrDefaultDecorator
} from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import inlineStyles from '../helpers/inline-styles.ts';
import useState from '../helpers/use-state.ts';
import useIsWithinBreakpoints from '../modifiers/use-is-within-breakpoints.ts';
import EuiBreadcrumbs from './eui-breadcrumbs.gts';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiIcon from './eui-icon.gts';
import EuiSpacer from './eui-spacer.gts';
import EuiTab from './eui-tab.gts';
import EuiTabs from './eui-tabs.gts';
import EuiText from './eui-text.gts';
import EuiTitle from './eui-title.gts';

import type { paddingSizeMapping } from '../utils/css-mappings/eui-page-content-body.ts';
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
  /** @deprecated Has no effect (EuiPageTemplate arg). */
  template?: (typeof TEMPLATES)[number];
  /** @deprecated Has no effect (EuiPageTemplate arg). */
  bottomBarProps?: EuiButtomBarArgs;
  /** @deprecated Has no effect (EuiPageTemplate arg). */
  fullHeight?: boolean;
  /** @deprecated Has no effect (EuiPageTemplate arg). */
  minHeight?: number;

  /** Max width of the content, see EuiPageHeader. */
  restrictWidth?: boolean | string | number;

  /** Adds a border below the tabs. */
  bottomBorder?: boolean;

  /** @deprecated Has no effect (EuiPageTemplate arg). */
  bodyBottomBorder?: boolean;

  /** @deprecated Has no effect (EuiPageTemplate arg). */
  bodyProps?: {
    paddingSize?: keyof typeof paddingSizeMapping;
  };
  /** @deprecated Has no effect (EuiPageTemplate arg). */
  contentProps?: {
    paddingSize?: keyof typeof paddingSizeMapping;
  };

  /** See EuiPageHeader's `@alignItems`. Defaults to `'top'`. */
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

  /** Props for the breadcrumbs: `{ className }`. */
  breadcrumbProps?: {
    className?: string;
  };

  /** Props for the right side items group: `{ className }`. */
  rightSideGroupProps?: {
    className?: string;
  };

  /** Props for the title: `{ className }`. */
  pageTitleProps?: {
    className?: string;
  };

  /** Icon before the title. */
  iconType?: EuiIconSignature['Args']['type'];

  /** Text under the title. */
  description?: string;

  /** Props for the icon: `{ className }`. */
  iconProps?: {
    className?: string;
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
                  @gutterSize="m"
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
