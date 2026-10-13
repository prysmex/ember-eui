import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';

import { modifier } from 'ember-modifier';

import spreadAttributes from '../-private/eui-spread-attributes.ts';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  euiBreakpointsMedia,
  euiOutsideBreakpointsMedia
} from '../utils/eui/page-layout.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiHeaderLinksStyles } from '../utils/eui/styles.generated.ts';
import EuiHeaderSectionItemButton from './eui-header-section-item-button.gts';
import EuiIcon from './eui-icon.gts';
import EuiPopover from './eui-popover.gts';

import type { EuiBreakpointSize } from '../utils/breakpoint.ts';
import type { EuiIconSignature } from './eui-icon';
import type { EuiHeaderSectionItemButtonSignature } from './eui-header-section-item-button';
import type { EuiPopoverSignature } from './eui-popover';
import type { EuiCss } from '../utils/eui/styles.ts';
import type { EuiResponsiveSizes } from './eui-show-for.gts';

export type EuiHeaderLinksGutterSize = 'none' | 'xxs' | 'xs' | 's' | 'm' | 'l';

const ALL_SIZES: EuiBreakpointSize[] = ['xs', 's', 'm', 'l', 'xl'];

/**
 * Upstream `popoverButtonProps`: EuiHeaderSectionItemButton args, plus
 * `iconType` (defaults to `'apps'`). Other keys (`aria-label`,
 * `data-test-subj`, …) become attributes of the button.
 */
export type EuiHeaderLinksPopoverButtonProps = Partial<
  EuiHeaderSectionItemButtonSignature['Args']
> & {
  iconType?: EuiIconSignature['Args']['type'];
  [key: string]: unknown;
};

/**
 * Upstream `popoverProps`: EuiPopover args except `button` and
 * `closePopover`; they replace the defaults (`isOpen`, `anchorPosition`
 * `'downRight'`, `panelPaddingSize` `'s'`, `repositionOnScroll`). Its
 * `className` is added to the popover root and its `css` is composed into
 * the root's class.
 */
export type EuiHeaderLinksPopoverProps = Partial<
  Omit<EuiPopoverSignature['Args'], 'button' | 'closePopover'>
> & { className?: string };

/** Button args that are not attributes. */
const BUTTON_ARGS = [
  'iconType',
  'ref',
  'disabled',
  'href',
  'onClick',
  'notification',
  'notificationColor'
];

/** Upstream closes the mobile menu whenever the window resizes. */
const onWindowResize = modifier(
  (_element: Element, [handler]: [() => void]) => {
    window.addEventListener('resize', handler);
    return () => window.removeEventListener('resize', handler);
  }
);

/**
 * A row of `EuiHeaderLink`s that collapses into a popover menu on small
 * screens.
 */
export interface EuiHeaderLinkSignature {
  Element: HTMLElement;
  Args: {
    /**
     * Screen sizes showing the links in a popover instead of a row (theme
     * breakpoints, evaluated with CSS media queries), or `'all'` / `'none'`.
     * Defaults to `['xs', 's']`; pass `[]` to never collapse.
     */
    popoverBreakpoints?: EuiResponsiveSizes;
    /**
     * Space between links: `'none'`, `'xxs'`, `'xs'`, `'s'`, `'m'` or
     * `'l'`. Defaults to `'s'`, as upstream (formerly `'xs'`).
     */
    gutterSize?: EuiHeaderLinksGutterSize;
    /** Padding of the popover. Defaults to `'s'`, as upstream (formerly `'none'`). */
    panelPaddingSize?: EuiPopoverSignature['Args']['panelPaddingSize'];
    /** Icon of the popover button. Defaults to `'apps'`. */
    popoverButtonIconType?: EuiIconSignature['Args']['type'];
    /** Accessible name of the popover button. Defaults to `'Open menu'`. */
    popoverButtonAriaLabel?: string;
    /**
     * Props for the popover's button (upstream `popoverButtonProps`), see
     * {@link EuiHeaderLinksPopoverButtonProps}. `iconType` wins over
     * `@popoverButtonIconType` and an `aria-label` over
     * `@popoverButtonAriaLabel`; `onClick` is called before the menu toggles.
     */
    popoverButtonProps?: EuiHeaderLinksPopoverButtonProps;
    /**
     * Props for the mobile menu's EuiPopover (upstream `popoverProps`), see
     * {@link EuiHeaderLinksPopoverProps}. `panelPaddingSize` wins over
     * `@panelPaddingSize`.
     */
    popoverProps?: EuiHeaderLinksPopoverProps;
  };
  Blocks: {
    /**
     * The `EuiHeaderLink`s. Yields a function closing the mobile menu,
     * like upstream's render-prop children.
     */
    default: [closeMenu: () => void];
  };
}

/**
 * Upstream `EuiHeaderLinks` (`euiHeaderLinksStyles`). Upstream swaps the row
 * and the popover with `EuiHideFor`/`EuiShowFor`; here both are rendered and
 * media queries on the theme breakpoints show one of them.
 */
export default class EuiHeaderLinksComponent extends Component<EuiHeaderLinkSignature> {
  @tracked mobileMenuIsOpen = false;

  get popoverSizes(): EuiBreakpointSize[] {
    const sizes = this.args.popoverBreakpoints ?? ['xs', 's'];
    if (sizes === 'all') return ALL_SIZES;
    if (sizes === 'none' || !Array.isArray(sizes)) return [];
    return sizes;
  }

  get hasList() {
    return ALL_SIZES.some((size) => !this.popoverSizes.includes(size));
  }

  get hasMobileVersion() {
    return this.popoverSizes.length > 0;
  }

  toggleMenu = (event: MouseEvent) => {
    this.args.popoverButtonProps?.onClick?.(event);
    this.mobileMenuIsOpen = !this.mobileMenuIsOpen;
  };

  get buttonArgs(): readonly string[] {
    return BUTTON_ARGS;
  }

  get buttonIconType(): EuiIconSignature['Args']['type'] {
    return (
      this.args.popoverButtonProps?.iconType ??
      this.args.popoverButtonIconType ??
      'apps'
    );
  }

  get isPopoverOpen(): boolean {
    const props = this.args.popoverProps;

    return props && 'isOpen' in props
      ? Boolean(props.isOpen)
      : this.mobileMenuIsOpen;
  }

  get popoverPaddingSize(): EuiPopoverSignature['Args']['panelPaddingSize'] {
    return (
      this.args.popoverProps?.panelPaddingSize ??
      this.args.panelPaddingSize ??
      's'
    );
  }

  get popoverRepositionOnScroll(): boolean {
    return this.args.popoverProps?.repositionOnScroll ?? true;
  }

  @cached
  get popoverCss(): EuiCss {
    return [this.classes.popover, this.args.popoverProps?.css];
  }

  closeMenu = () => {
    this.mobileMenuIsOpen = false;
  };

  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiHeaderLinksStyles);
    const collapsed = euiBreakpointsMedia(context.upstream, this.popoverSizes);
    const expanded = euiOutsideBreakpointsMedia(
      context.upstream,
      this.popoverSizes
    );
    const gutter = this.args.gutterSize ?? 's';
    return {
      nav: euiClass(context, { boxSizing: 'border-box' }, styles.euiHeaderLinks),
      list: euiClass(
        context,
        styles.euiHeaderLinks__list,
        gutter === 'none' ? { gap: 0 } : styles.gutterSizes[gutter],
        collapsed && { [collapsed]: { display: 'none' } }
      ),
      // Upstream's `css` on EuiPopover.
      popover: expanded ? { [expanded]: { display: 'none' } } : undefined,
      mobileList: euiClass(context, styles.euiHeaderLinks__mobileList)
    };
  }

  <template>
    <nav
      class="euiHeaderLinks {{this.classes.nav}}"
      aria-label="App menu"
      {{onWindowResize this.closeMenu}}
      ...attributes
    >
      {{#if this.hasList}}
        <div class="euiHeaderLinks__list {{this.classes.list}}">
          {{yield this.closeMenu}}
        </div>
      {{/if}}

      {{#if this.hasMobileVersion}}
        <EuiPopover
          class={{@popoverProps.className}}
          @css={{this.popoverCss}}
          @isOpen={{this.isPopoverOpen}}
          @anchorPosition={{if
            @popoverProps.anchorPosition
            @popoverProps.anchorPosition
            "downRight"
          }}
          @repositionOnScroll={{this.popoverRepositionOnScroll}}
          @panelPaddingSize={{this.popoverPaddingSize}}
          @closePopover={{this.closeMenu}}
          @portalRef={{@popoverProps.portalRef}}
          @anchorClassName={{@popoverProps.anchorClassName}}
          @attachToAnchor={{@popoverProps.attachToAnchor}}
          @buttonRef={{@popoverProps.buttonRef}}
          @container={{@popoverProps.container}}
          @display={{@popoverProps.display}}
          @hasArrow={{@popoverProps.hasArrow}}
          @initialFocus={{@popoverProps.initialFocus}}
          @insert={{@popoverProps.insert}}
          @ownFocus={{@popoverProps.ownFocus}}
          @panelClassName={{@popoverProps.panelClassName}}
          @panelStyle={{@popoverProps.panelStyle}}
          @popoverScreenReaderText={{@popoverProps.popoverScreenReaderText}}
          @panelProps={{@popoverProps.panelProps}}
          @focusTrapProps={{@popoverProps.focusTrapProps}}
          @onPositionChange={{@popoverProps.onPositionChange}}
          @panelRef={{@popoverProps.panelRef}}
          @popoverRef={{@popoverProps.popoverRef}}
          @shouldAccountForOtherPopovers={{@popoverProps.shouldAccountForOtherPopovers}}
          @repositionToCrossAxis={{@popoverProps.repositionToCrossAxis}}
          @panelCss={{@popoverProps.panelCss}}
          @zIndex={{@popoverProps.zIndex}}
          @onTrapDeactivation={{@popoverProps.onTrapDeactivation}}
          @offset={{@popoverProps.offset}}
          @buffer={{@popoverProps.buffer}}
          @ariaLabel={{@popoverProps.ariaLabel}}
          @ariaLabelledBy={{@popoverProps.ariaLabelledBy}}
          @tabindex={{@popoverProps.tabindex}}
        >
          <:button>
            <EuiHeaderSectionItemButton
              aria-label={{if
                @popoverButtonAriaLabel
                @popoverButtonAriaLabel
                "Open menu"
              }}
              @onClick={{this.toggleMenu}}
              @ref={{@popoverButtonProps.ref}}
              @disabled={{@popoverButtonProps.disabled}}
              @href={{@popoverButtonProps.href}}
              @notification={{@popoverButtonProps.notification}}
              @notificationColor={{@popoverButtonProps.notificationColor}}
              {{spreadAttributes @popoverButtonProps this.buttonArgs}}
            >
              <EuiIcon @type={{this.buttonIconType}} @size="m" />
            </EuiHeaderSectionItemButton>
          </:button>
          <:content>
            <div class="euiHeaderLinks__mobileList {{this.classes.mobileList}}">
              {{yield this.closeMenu}}
            </div>
          </:content>
        </EuiPopover>
      {{/if}}
    </nav>
  </template>
}
