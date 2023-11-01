import Component from '@glimmer/component';
import classNames from '../helpers/class-names';
import argOrDefault from '../helpers/arg-or-default';
import { eq, not, or, and } from 'ember-truth-helpers';
import uniqueId from '../helpers/unique-id';
import { on } from '@ember/modifier';
import optional from 'ember-composable-helpers/helpers/optional';
import isItemOpen from '../helpers/is-item-open';
import { element } from 'ember-element-helper';
import EuiShowFor from '../components/eui-show-for';
import EuiButtonEmpty from '../components/eui-button-empty';
import EuiSideNavItem from '../components/eui-side-nav-item';
import EuiHideFor from '../components/eui-hide-for';
import EuiTitle from '../components/eui-title';
import type { EuiHideForSignature } from '../components/eui-hide-for';
import { fn } from '@ember/helper';
import screenReaderOnly from '../modifiers/screen-reader-only';

export interface Item {
  id: string;
  icon?: string;
  onClick?: () => void;
  href?: string;
  className?: string;
  rel?: string;
  target?: string;
  items?: Item[];
  depth?: number;
  name?: string;
  renderItem?: unknown;
  isSelected?: boolean;
  disabled?: boolean;
  truncate?: boolean;
  emphasize?: boolean;
  buttonClassName?: string;
}

export interface EuiSideNavSignature {
  Element: HTMLDivElement | HTMLUListElement | HTMLElement;
  Args: {
    mobileBreakpoints?: EuiHideForSignature['Args']['sizes'];
    isOpenMobile?: boolean;
    toggleOpenOnMobile?: () => void;
    heading?: string;
    headingProps?: {
      element?: string;
      id?: string;
      className?: string;
      screenReaderOnly?: boolean;
    };
    mobileTitle?: string;
    items?: Item[];
    selectedItem?: string;
  };
  Blocks: {
    default: [Item];
    heading: [];
  };
}

export default class EuiSideNavComponent extends Component<EuiSideNavSignature> {
  get mobileBreakpoints() {
    return this.args.mobileBreakpoints || ['xs', 's'];
  }

  get contentClasses() {
    let mobileBreakpoints = Array.isArray(this.mobileBreakpoints)
      ? this.mobileBreakpoints
      : [this.mobileBreakpoints];

    return `euiSideNav__content ${mobileBreakpoints
      .map?.((breakpointName) => {
        return `euiSideNav__contentMobile-${breakpointName}`;
      })
      .join(' ')}`;
  }

  get hasMobileVersion() {
    return this.mobileBreakpoints?.length > 0;
  }

  <template>
    {{#let
      (classNames "euiSideNav" (if @isOpenMobile "euiSideNav-isOpenMobile"))
      (element (argOrDefault @headingProps.element "h2"))
      (argOrDefault @headingProps.id (uniqueId))
      (uniqueId)
      (or (has-block "heading") (not (not @heading)))
      as |classes HeadingElement headingId sideNavContentId hasHeader|
    }}
      {{#if this.hasMobileVersion}}
        <EuiShowFor @sizes={{this.mobileBreakpoints}}>
          <nav aria-labelledby={{headingId}} class={{classes}} ...attributes>
            <HeadingElement id={{headingId}} class={{@headingProps.className}}>
              <EuiButtonEmpty
                type="button"
                class="euiSideNav__mobileToggle"
                @contentClasses="euiSideNav__mobileToggleContent"
                @textClasses="euiSideNav__mobileToggleText"
                {{on
                  "click"
                  (fn (optional @toggleOpenOnMobile) (not @isOpenMobile))
                }}
                @iconType="apps"
                @iconSide="right"
                aria-controls={{sideNavContentId}}
                aria-expanded={{@isOpenMobile}}
              >
                {{#if @mobileTitle}}
                  {{@mobileTitle}}
                {{else if (has-block "heading")}}
                  {{yield to="heading"}}
                {{else}}
                  {{@heading}}
                {{/if}}
              </EuiButtonEmpty>
            </HeadingElement>
            <div id={{sideNavContentId}} class={{this.contentClasses}}>
              {{#each @items as |item|}}
                {{#let
                  (and
                    (not item.onClick) (not item.href) (not (not item.items))
                  )
                  as |childrenOnly|
                }}
                  <EuiSideNavItem
                    @selectedItem={{@selectedItem}}
                    @isOpen={{isItemOpen item @selectedItem}}
                    @isSelected={{and
                      (not childrenOnly)
                      (eq item.id item.isSelected)
                    }}
                    @isParent={{not (not item.items)}}
                    @icon={{item.icon}}
                    @onClick={{item.onClick}}
                    @href={{item.href}}
                    @className={{item.className}}
                    @rel={{item.rel}}
                    @target={{item.target}}
                    @items={{item.items}}
                    @depth={{0}}
                    @renderItem={{item.renderItem}}
                    @disabled={{item.disabled}}
                    @truncate={{item.truncate}}
                    @emphasize={{item.emphasize}}
                    @buttonClassName={{item.buttonClassName}}
                    @childrenOnly={{childrenOnly}}
                  >
                    {{item.name}}
                  </EuiSideNavItem>
                {{/let}}
              {{/each}}
            </div>
          </nav>
        </EuiShowFor>
      {{/if}}

      <EuiHideFor @sizes={{this.mobileBreakpoints}}>
        <nav
          aria-labelledby={{if hasHeader headingId}}
          class={{classes}}
          ...attributes
        >
          {{#if hasHeader}}
            {{#let
              (argOrDefault @headingProps.screenReaderOnly false)
              as |shouldScreenReader|
            }}
              {{#if (has-block "heading")}}
                {{#if shouldScreenReader}}
                  <HeadingElement {{screenReaderOnly}}>
                    {{yield to="heading"}}
                  </HeadingElement>
                {{else}}
                  <EuiTitle
                    class={{classNames
                      "euiSideNav__heading"
                      @headingProps.className
                    }}
                    @size="xs"
                  >
                    <HeadingElement>
                      {{yield to="heading"}}
                    </HeadingElement>
                  </EuiTitle>
                {{/if}}
              {{else}}
                {{#if screenReaderOnly}}
                  <HeadingElement {{screenReaderOnly}}>
                    {{@heading}}
                  </HeadingElement>
                {{else}}
                  <EuiTitle
                    class={{classNames
                      "euiSideNav__heading"
                      @headingProps.className
                    }}
                    @size="xs"
                  >
                    {{@heading}}
                  </EuiTitle>
                {{/if}}
              {{/if}}
            {{/let}}
          {{/if}}
          <div id={{sideNavContentId}} class={{this.contentClasses}}>
            {{#each @items as |item|}}
              {{#let
                (and (not item.onClick) (not item.href) (not (not item.items)))
                as |childrenOnly|
              }}
                <EuiSideNavItem
                  @selectedItem={{@selectedItem}}
                  @isOpen={{isItemOpen item @selectedItem}}
                  @isSelected={{and
                    (not childrenOnly)
                    (eq item.id item.isSelected)
                  }}
                  @isParent={{not (not item.items)}}
                  @icon={{item.icon}}
                  @onClick={{item.onClick}}
                  @href={{item.href}}
                  @className={{item.className}}
                  @rel={{item.rel}}
                  @target={{item.target}}
                  @items={{item.items}}
                  @depth={{0}}
                  @renderItem={{item.renderItem}}
                  @disabled={{item.disabled}}
                  @truncate={{item.truncate}}
                  @emphasize={{item.emphasize}}
                  @buttonClassName={{item.buttonClassName}}
                  @childrenOnly={{childrenOnly}}
                >
                  {{item.name}}
                </EuiSideNavItem>
              {{/let}}
            {{/each}}
          </div>
        </nav>
      </EuiHideFor>
    {{/let}}
  </template>
}
