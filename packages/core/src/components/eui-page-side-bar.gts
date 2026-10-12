import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  euiBreakpointsMedia,
  euiOutsideBreakpointsMedia,
  euiPageBoxSizing,
  euiPagePadding
} from '../utils/eui/page-layout.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiPageSidebarStyles } from '../utils/eui/styles.generated.ts';

import type {
  EuiPageBreakpoint,
  EuiPagePaddingSize
} from '../utils/eui/page-layout.ts';

/** The side column of an EuiPage, e.g. with an `EuiSideNav`. */
export interface EuiPageSideBarSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * Keeps the side bar in view (and scrollable) while the page scrolls,
     * except on `@responsive` breakpoints. `true` offsets it by the
     * `--euiFixedHeadersOffset` CSS variable (fixed headers); pass
     * `{ offset: 48 }` for a pixel offset.
     */
    sticky?: boolean | { offset?: number };
    /**
     * Padding: `'none'`, `'xs'`, `'s'`, `'m'`, `'l'` or `'xl'`.
     * Defaults to `'none'`, as upstream (formerly `'l'`).
     */
    paddingSize?: EuiPagePaddingSize;
    /** Minimum width, in px or any CSS width. Defaults to `248`. */
    minWidth?: number | string;
    /**
     * Theme breakpoints where the side bar takes the full width and is never
     * sticky (an `EuiPage` stacks it above the body there). `false` keeps
     * the desktop layout everywhere. Defaults to `['xs', 's']`.
     */
    responsive?: EuiPageBreakpoint[] | false;
    /** Adds upstream's subtle diagonal background embellishment. */
    hasEmbellish?: boolean;
  };
  Blocks: {
    /** The side bar content. */
    default: [];
  };
}

/**
 * Upstream `EuiPageSidebar` (`euiPageSidebarStyles`). Upstream measures the
 * window in JS and writes inline styles; here the same breakpoints are
 * media queries in the theme class, so callers' `style` is never replaced.
 */
export default class EuiPageSideBar extends Component<EuiPageSideBarSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const upstream = context.upstream;
    const styles = useEuiBorealisStyles(context, euiPageSidebarStyles);
    const responsive =
      this.args.responsive === false
        ? []
        : (this.args.responsive ?? ['xs', 's']);
    const responding = euiBreakpointsMedia(upstream, responsive);
    const desktop = responsive.length
      ? euiOutsideBreakpointsMedia(upstream, responsive)
      : undefined;
    const minWidth = this.args.minWidth ?? 248;
    const { sticky } = this.args;
    const offset =
      typeof sticky === 'object' && sticky
        ? `${sticky.offset ?? 0}px`
        : 'var(--euiFixedHeadersOffset, 0)';
    const stickyStyles = sticky && [
      styles.sticky,
      { insetBlockStart: offset, maxBlockSize: `calc(100vh - ${offset})` }
    ];
    return euiClass(
      context,
      euiPageBoxSizing,
      styles.euiPageSidebar,
      // Upstream applies sticky only while not responding.
      stickyStyles &&
        (desktop
          ? { [desktop]: stickyStyles }
          : responsive.length
            ? undefined
            : stickyStyles),
      this.args.hasEmbellish && styles.embellish,
      euiPagePadding(upstream, this.args.paddingSize ?? 'none'),
      {
        minInlineSize:
          typeof minWidth === 'number' ? `${minWidth}px` : minWidth
      },
      responding && { [responding]: { minInlineSize: '100%' } }
    );
  }

  <template>
    <div class="euiPageSideBar {{this.classes}}" ...attributes>
      {{yield}}
    </div>
  </template>
}
