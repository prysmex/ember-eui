import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';

import { modifier } from 'ember-modifier';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  composedOver,
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
import type { EuiPopoverSignature } from './eui-popover';
import type { EuiResponsiveSizes } from './eui-show-for.gts';

export type EuiHeaderLinksGutterSize = 'none' | 'xxs' | 'xs' | 's' | 'm' | 'l';

const ALL_SIZES: EuiBreakpointSize[] = ['xs', 's', 'm', 'l', 'xl'];

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

  toggleMenu = () => {
    this.mobileMenuIsOpen = !this.mobileMenuIsOpen;
  };

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
      popover: euiClass(
        context,
        expanded && composedOver({ [expanded]: { display: 'none' } })
      ),
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
          class={{this.classes.popover}}
          @isOpen={{this.mobileMenuIsOpen}}
          @anchorPosition="downRight"
          @repositionOnScroll={{true}}
          @panelPaddingSize={{if @panelPaddingSize @panelPaddingSize "s"}}
          @closePopover={{this.closeMenu}}
        >
          <:button>
            <EuiHeaderSectionItemButton
              aria-label={{if
                @popoverButtonAriaLabel
                @popoverButtonAriaLabel
                "Open menu"
              }}
              @onClick={{this.toggleMenu}}
            >
              <EuiIcon
                @type={{if
                  @popoverButtonIconType
                  @popoverButtonIconType
                  "apps"
                }}
                @size="m"
              />
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
