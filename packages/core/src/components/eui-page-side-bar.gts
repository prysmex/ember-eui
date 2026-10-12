import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiPageSidebarClass } from './eui-page-sidebar.gts';

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
 * Upstream `EuiPageSidebar` styles under the older Ember name; renders the
 * same class as EuiPageSidebar (`euiPageSidebarClass`) with the
 * `euiPageSideBar` root class.
 */
export default class EuiPageSideBar extends Component<EuiPageSideBarSignature> {
  @cached
  get classes() {
    return euiPageSidebarClass(getEuiThemeContext(this), this.args);
  }

  <template>
    <div class="euiPageSideBar {{this.classes}}" ...attributes>
      {{yield}}
    </div>
  </template>
}
