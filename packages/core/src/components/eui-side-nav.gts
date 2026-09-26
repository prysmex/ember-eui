import Component from '@glimmer/component';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { element } from 'ember-element-helper';
import { and, eq, not, or } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import EuiButtonEmpty from '../components/eui-button-empty.gts';
import EuiHideFor from '../components/eui-hide-for.gts';
import EuiShowFor from '../components/eui-show-for.gts';
import EuiSideNavItem from '../components/eui-side-nav-item.gts';
import EuiTitle from '../components/eui-title.gts';
import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import isItemOpen from '../helpers/is-item-open.ts';
import screenReaderOnly from '../modifiers/screen-reader-only.ts';

import type { EuiHideForSignature } from '../components/eui-hide-for';

export interface Item {
  /** Unique id, matched against `@selectedItem`. */
  id: string;
  /** Icon before the name; anything `EuiIcon`'s `@type` accepts. */
  icon?: string;
  /** Makes the item a button calling this function. */
  onClick?: () => void;
  /** Makes the item a link. */
  href?: string;
  /** Class for the item. */
  className?: string;
  /** `rel` of the link. */
  rel?: string;
  /** `target` of the link. */
  target?: string;
  /**
   * Nested items. An item with children but no `href`/`onClick` is a
   * section title; nested levels open while one of them is selected.
   */
  items?: Item[];
  /** @private Nesting level. */
  depth?: number;
  /** The item's text. */
  name?: string;
  /** @deprecated Has no effect. */
  renderItem?: unknown;
  /** @deprecated Has no effect, use the side nav's `@selectedItem`. */
  isSelected?: boolean;
  /** Disables the item. */
  disabled?: boolean;
  /** Truncates a long name instead of wrapping. */
  truncate?: boolean;
  /** Bolder style, e.g. for the top level. */
  emphasize?: boolean;
  /** Class for the item's button or link. */
  buttonClassName?: string;
}

/** A hierarchical navigation tree for a page's side bar. */
export interface EuiSideNavSignature {
  Element: HTMLDivElement | HTMLUListElement | HTMLElement;
  Args: {
    /**
     * Screen sizes showing the nav collapsed behind a toggle button.
     * Defaults to `['xs', 's']`; pass `[]` to never collapse.
     */
    mobileBreakpoints?: EuiHideForSignature['Args']['sizes'];
    /** Whether the collapsed (mobile) nav is open. */
    isOpenMobile?: boolean;
    /** Called by the mobile toggle button with the new open state. */
    toggleOpenOnMobile?: () => void;
    /** Heading above the items (and the toggle text on mobile). */
    heading?: string;
    /**
     * Props for the heading: `{ element: 'h2', id, className,
     * screenReaderOnly }`.
     */
    headingProps?: {
      element?: string;
      id?: string;
      className?: string;
      screenReaderOnly?: boolean;
    };
    /** Text of the mobile toggle button. Defaults to the heading. */
    mobileTitle?: string;
    /** The navigation tree, see `Item`. */
    items?: Item[];
    /** Id of the current item: it is highlighted and its parents open. */
    selectedItem?: string;
  };
  Blocks: {
    /** Unused. */
    default: [Item];
    /** Custom heading, instead of `@heading`. */
    heading: [];
  };
}

export default class EuiSideNavComponent extends Component<EuiSideNavSignature> {
  get mobileBreakpoints() {
    return this.args.mobileBreakpoints || ['xs', 's'];
  }

  get contentClasses() {
    const mobileBreakpoints = Array.isArray(this.mobileBreakpoints)
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
      (argOrDefault @headingProps.id (randomId))
      (randomId)
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
                aria-expanded={{if @isOpenMobile "true" "false"}}
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
                      (eq item.id @selectedItem)
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
                {{#if shouldScreenReader}}
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
                    (eq item.id @selectedItem)
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
