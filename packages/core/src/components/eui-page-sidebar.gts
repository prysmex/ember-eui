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

import type { EuiThemeContext } from '../utils/emotion/context.ts';
import type {
  EuiPageBreakpoint,
  EuiPagePaddingSize
} from '../utils/eui/page-layout.ts';
import type { EuiCss } from '../utils/eui/styles.ts';

export interface EuiPageSidebarArgs {
  /**
   * Keeps the sidebar in view (and scrollable) while the page scrolls,
   * except on `@responsive` breakpoints. `true` offsets it by the
   * `--euiFixedHeadersOffset` CSS variable (fixed headers); pass
   * `{ offset: 48 }` for a pixel offset.
   */
  sticky?: boolean | { offset?: number };
  /**
   * Padding: `'none'`, `'xs'`, `'s'`, `'m'`, `'l'` or `'xl'`.
   * Defaults to `'none'`.
   */
  paddingSize?: EuiPagePaddingSize;
  /**
   * Minimum width, in px or any CSS width; take `@paddingSize` into
   * account. Defaults to `248`.
   */
  minWidth?: number | string;
  /**
   * Theme breakpoints where the sidebar takes the full width and is never
   * sticky (an `EuiPage` stacks it above the body there). `false` keeps
   * the desktop layout everywhere. Defaults to `['xs', 's']`.
   */
  responsive?: EuiPageBreakpoint[] | false;
  /** Adds a subtle diagonal embellishment to the top start corner. */
  hasEmbellish?: boolean;
}

/**
 * The Emotion class of upstream `EuiPageSidebar` (`euiPageSidebarStyles`),
 * shared by EuiPageSidebar and the older EuiPageSideBar. Upstream measures
 * the window in JS and writes inline styles; here the same breakpoints are
 * media queries in the theme class, so callers' `style` is never replaced.
 * `css` is composed last, like upstream's `css` prop.
 */
export function euiPageSidebarClass(
  context: EuiThemeContext,
  args: EuiPageSidebarArgs,
  css?: EuiCss
): string {
  const upstream = context.upstream;
  const styles = useEuiBorealisStyles(context, euiPageSidebarStyles);
  const responsive =
    args.responsive === false ? [] : (args.responsive ?? ['xs', 's']);
  const responding = euiBreakpointsMedia(upstream, responsive);
  const desktop = responsive.length
    ? euiOutsideBreakpointsMedia(upstream, responsive)
    : undefined;
  const minWidth = args.minWidth ?? 248;
  const { sticky } = args;
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
    args.hasEmbellish && styles.embellish,
    euiPagePadding(upstream, args.paddingSize ?? 'none'),
    { minInlineSize: typeof minWidth === 'number' ? `${minWidth}px` : minWidth },
    responding && { [responding]: { minInlineSize: '100%' } },
    css
  );
}

/**
 * The side column of an `EuiPage` (upstream `EuiPageSidebar`), e.g. with an
 * `EuiSideNav`. Place it before an `EuiPageBody` in a row `EuiPage`.
 */
export interface EuiPageSidebarSignature {
  Element: HTMLDivElement;
  Args: EuiPageSidebarArgs & {
    /** Styles composed last into the sidebar's class (upstream's `css`). */
    css?: EuiCss;
  };
  Blocks: {
    /** The sidebar content. */
    default: [];
  };
}

export default class EuiPageSidebar extends Component<EuiPageSidebarSignature> {
  @cached
  get classes() {
    return euiPageSidebarClass(
      getEuiThemeContext(this),
      this.args,
      this.args.css
    );
  }

  <template>
    <div class="euiPageSidebar {{this.classes}}" ...attributes>
      {{yield}}
    </div>
  </template>
}
