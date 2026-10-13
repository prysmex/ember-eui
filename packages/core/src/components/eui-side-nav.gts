import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { not } from 'ember-truth-helpers';

import { randomId } from '../-private/random-id.ts';
import EuiButtonEmpty from '../components/eui-button-empty.gts';
import EuiHideFor from '../components/eui-hide-for.gts';
import EuiShowFor from '../components/eui-show-for.gts';
import EuiSideNavItem, { isChildrenOnly } from '../components/eui-side-nav-item.gts';
import EuiTitle from '../components/eui-title.gts';
import nullish from '../helpers/nullish.ts';
import { isItemOpen, isItemSelected } from '../helpers/is-item-open.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import {
  euiScreenReaderOnly,
  euiSideNavMobileStyles
} from '../utils/eui/styles.generated.ts';

import type { EuiHideForSignature } from '../components/eui-hide-for';
import type EuiI18n from '../services/eui-i18n';
import type { ComponentLike } from '@glint/template';

/** Props a `renderItem` component receives for the item it replaces. */
export interface EuiSideNavRenderItemSignature {
  Element: HTMLElement;
  Args: {
    href?: string;
    target?: string;
    rel?: string;
    onClick?: () => void;
    disabled?: boolean;
  };
  Blocks: { default: [] };
}

export type EuiSideNavRenderItem = ComponentLike<EuiSideNavRenderItemSignature>;

export interface Item {
  /** Unique id, matched against `@selectedItem`. */
  id: string;
  /**
   * Icon before the name: a type name for `EuiIcon`, or a component
   * rendered as is (e.g. `EuiIcon` curried with a color:
   * `(component EuiIcon type="clock" color="success")`).
   */
  icon?: string | ComponentLike<any>;
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
  /**
   * Replaces the item's link, button or text: a component (see
   * `EuiSideNavRenderItemSignature`) getting `@href`, `@target`, `@rel`,
   * `@onClick` and `@disabled`, the item's classes as `class`, and the
   * item's content as its block. Wins over the nav's `@renderItem`.
   */
  renderItem?: EuiSideNavRenderItem;
  /**
   * Opens or closes this item's children, overriding what its selection
   * and `forceOpen` imply (upstream passes it through to the item).
   */
  isOpen?: boolean;
  /**
   * Marks the item as the current one, like matching `@selectedItem`:
   * highlighted, with its parents open.
   */
  isSelected?: boolean;
  /** Keeps a nested item's children open. */
  forceOpen?: boolean;
  /** Disables the item. */
  disabled?: boolean;
  /** Truncates a long name instead of wrapping. Defaults to `true`. */
  truncate?: boolean;
  /** Bolder style with a background band, e.g. for the current section. */
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
    /**
     * Whether the collapsed (mobile) nav is open; flip it in
     * `@toggleOpenOnMobile`.
     */
    isOpenOnMobile?: boolean;
    /** @deprecated Use `@isOpenOnMobile` (upstream's name). */
    isOpenMobile?: boolean;
    /**
     * Truncates the names of all items to one line (`false` wraps them). An
     * item's own `truncate` wins. Items truncate by default.
     */
    truncate?: boolean;
    /** Called by the mobile toggle button with the new open state. */
    toggleOpenOnMobile?: (isOpen: boolean) => void;
    /** Heading above the items (and the toggle text on mobile). */
    heading?: string;
    /**
     * Props for the heading: `{ element: 'h2', id, className,
     * screenReaderOnly }`. The heading labels the `<nav>`.
     */
    headingProps?: {
      element?: 'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6' | 'p';
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
    /**
     * Replaces the rendering of every item's link, button or text with a
     * component, see `Item.renderItem`.
     */
    renderItem?: EuiSideNavRenderItem;
  };
  Blocks: {
    /** Unused. */
    default: [Item];
    /** Custom heading, instead of `@heading`. */
    heading: [];
  };
}

const MOBILE_HEADING_CSS = { marginBlockEnd: 0 };

/** Native Ember side nav using the upstream EUI 123 / Borealis factories. */
export default class EuiSideNavComponent extends Component<EuiSideNavSignature> {
  @service declare euiI18n: EuiI18n;

  generatedHeadingId = randomId();
  contentId = randomId();

  get context() {
    return getEuiThemeContext(this);
  }

  @cached
  get mobileStyles() {
    return useEuiBorealisStyles(this.context, euiSideNavMobileStyles);
  }

  get mobileBreakpoints() {
    return this.args.mobileBreakpoints ?? ['xs', 's'];
  }

  get hasMobileVersion() {
    return this.mobileBreakpoints.length > 0;
  }

  get headingId(): string {
    return this.args.headingProps?.id ?? this.generatedHeadingId;
  }

  get headingElement() {
    return this.args.headingProps?.element ?? 'h2';
  }

  get headingScreenReaderOnly(): boolean {
    return Boolean(this.args.headingProps?.screenReaderOnly);
  }

  get isOpenOnMobile(): boolean {
    return Boolean(this.args.isOpenOnMobile ?? this.args.isOpenMobile);
  }

  get classes(): string {
    return this.isOpenOnMobile
      ? 'euiSideNav euiSideNav-isOpenMobile'
      : 'euiSideNav';
  }

  get headingClassNames(): string {
    return ['euiSideNav__heading', this.args.headingProps?.className]
      .filter(Boolean)
      .join(' ');
  }

  /** Upstream EuiSideNavHeading: `xs` title with an `l` bottom margin. */
  @cached
  get headingCss(): EuiCss {
    return { marginBlockEnd: this.context.upstream.euiTheme.size.l };
  }

  @cached
  get srHeadingClass(): string {
    return [
      'euiSideNav__heading euiScreenReaderOnly',
      this.args.headingProps?.className,
      euiClass(this.context, euiScreenReaderOnly())
    ]
      .filter(Boolean)
      .join(' ');
  }

  /** The mobile heading drops the bottom margin (upstream `mobileHeadingUnset`). */
  get mobileHeadingCss(): EuiCss {
    return MOBILE_HEADING_CSS;
  }

  @cached
  get mobileContentClass(): string {
    const content = this.mobileStyles.content;
    return `euiSideNav__content ${euiClass(
      this.context,
      { boxSizing: 'border-box' },
      content.euiSideNav__mobileContent,
      this.isOpenOnMobile ? content.open : content.hidden
    )}`;
  }

  /** Upstream labels the toggle when it has no visible text. */
  get mobileToggleAriaLabel(): string | undefined {
    const hasText = Boolean(this.args.mobileTitle || this.args.heading);
    return !hasText || this.headingScreenReaderOnly
      ? this.euiI18n.lookupToken(
          'euiSideNav.mobileToggleAriaLabel',
          'Toggle navigation'
        )
      : undefined;
  }

  isItemOpen = (item: Item): boolean => isItemOpen(item, this.args.selectedItem);

  isItemSelected = (item: Item): boolean =>
    !isChildrenOnly(item, 0) && isItemSelected(item, this.args.selectedItem);

  <template>
    {{#let
      (if (has-block "heading") true (if @heading true false))
      as |hasHeading|
    }}
      {{#if this.hasMobileVersion}}
        <EuiShowFor @sizes={{this.mobileBreakpoints}}>
          <nav
            aria-labelledby={{this.headingId}}
            class={{this.classes}}
            ...attributes
          >
            <EuiTitle
              @size="xs"
              @tagName={{this.headingElement}}
              id={{this.headingId}}
              class={{this.headingClassNames}}
              @css={{this.mobileHeadingCss}}
            >
              <EuiButtonEmpty
                class="euiSideNav__mobileToggle"
                @css={{this.mobileStyles.euiSideNav__mobileToggle}}
                @contentClasses="euiSideNav__mobileToggleContent"
                @contentCss={{this.mobileStyles.euiSideNav__mobileToggleContent}}
                @iconType="apps"
                @iconSide="right"
                aria-controls={{this.contentId}}
                aria-expanded={{if this.isOpenOnMobile "true" "false"}}
                aria-label={{this.mobileToggleAriaLabel}}
                {{on
                  "click"
                  (fn (optional @toggleOpenOnMobile) (not this.isOpenOnMobile))
                }}
              >
                {{#unless this.headingScreenReaderOnly}}
                  {{#if @mobileTitle}}
                    {{@mobileTitle}}
                  {{else if (has-block "heading")}}
                    {{yield to="heading"}}
                  {{else}}
                    {{@heading}}
                  {{/if}}
                {{/unless}}
              </EuiButtonEmpty>
            </EuiTitle>
            <div id={{this.contentId}} class={{this.mobileContentClass}}>
              {{#each @items as |item|}}
                <EuiSideNavItem
                  @selectedItem={{@selectedItem}}
                  @isOpen={{nullish item.isOpen true}}
                  @isSelected={{this.isItemSelected item}}
                  @isParent={{if item.items true false}}
                  @icon={{item.icon}}
                  @onClick={{item.onClick}}
                  @href={{item.href}}
                  @className={{item.className}}
                  @rel={{item.rel}}
                  @target={{item.target}}
                  @items={{item.items}}
                  @depth={{0}}
                  @disabled={{item.disabled}}
                  @truncate={{item.truncate}}
                  @navTruncate={{@truncate}}
                  @emphasize={{item.emphasize}}
                  @buttonClassName={{item.buttonClassName}}
                  @childrenOnly={{false}}
                  @renderItem={{if item.renderItem item.renderItem @renderItem}}
                >
                  {{item.name}}
                </EuiSideNavItem>
              {{/each}}
            </div>
          </nav>
        </EuiShowFor>
      {{/if}}

      <EuiHideFor @sizes={{this.mobileBreakpoints}}>
        <nav
          aria-labelledby={{if hasHeading this.headingId}}
          class={{this.classes}}
          ...attributes
        >
          {{#if hasHeading}}
            {{#if this.headingScreenReaderOnly}}
              {{#let (element this.headingElement) as |Heading|}}
                <Heading id={{this.headingId}} class={{this.srHeadingClass}}>
                  {{#if (has-block "heading")}}
                    {{yield to="heading"}}
                  {{else}}
                    {{@heading}}
                  {{/if}}
                </Heading>
              {{/let}}
            {{else}}
              <EuiTitle
                @size="xs"
                @tagName={{this.headingElement}}
                id={{this.headingId}}
                class={{this.headingClassNames}}
                @css={{this.headingCss}}
              >
                {{#if (has-block "heading")}}
                  {{yield to="heading"}}
                {{else}}
                  {{@heading}}
                {{/if}}
              </EuiTitle>
            {{/if}}
          {{/if}}
          <div id={{this.contentId}} class="euiSideNav__content">
            {{#each @items as |item|}}
              <EuiSideNavItem
                @selectedItem={{@selectedItem}}
                @isOpen={{nullish item.isOpen true}}
                @isSelected={{this.isItemSelected item}}
                @isParent={{if item.items true false}}
                @icon={{item.icon}}
                @onClick={{item.onClick}}
                @href={{item.href}}
                @className={{item.className}}
                @rel={{item.rel}}
                @target={{item.target}}
                @items={{item.items}}
                @depth={{0}}
                @disabled={{item.disabled}}
                @truncate={{item.truncate}}
                @navTruncate={{@truncate}}
                @emphasize={{item.emphasize}}
                @buttonClassName={{item.buttonClassName}}
                @childrenOnly={{false}}
                  @renderItem={{if item.renderItem item.renderItem @renderItem}}
              >
                {{item.name}}
              </EuiSideNavItem>
            {{/each}}
          </div>
        </nav>
      </EuiHideFor>
    {{/let}}
  </template>
}
