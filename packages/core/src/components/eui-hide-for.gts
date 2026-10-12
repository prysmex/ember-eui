import Component from '@glimmer/component';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { CurrentBreakPointHelper } from './eui-show-for.gts';

import type { EuiBreakpointSize, EuiBreakpoints } from '../utils/breakpoint.ts';
import type { EuiResponsiveSizes } from './eui-show-for.gts';

export type EuiHideForBreakpoints = EuiBreakpointSize;

export interface EuiHideForArgs {
  /**
   * Screen sizes to hide the content on: any of `'xs'`, `'s'`, `'m'`,
   * `'l'`, `'xl'` (the nearest theme's `breakpoint` values), or `'all'` /
   * `'none'`. E.g. `(array "xs" "s")` hides it on phones.
   */
  sizes: EuiResponsiveSizes;
}

/** Renders its content except on the given screen sizes. See EuiShowFor. */
export interface EuiHideForSignature {
  Args: EuiHideForArgs;
  Blocks: {
    /** The content. */
    default: [];
  };
}

export default class EuiHideForComponent extends Component<EuiHideForSignature> {
  get breakpoints(): EuiBreakpoints {
    return getEuiThemeContext(this).upstream.euiTheme
      .breakpoint as EuiBreakpoints;
  }

  <template>
    {{#unless (CurrentBreakPointHelper @sizes this.breakpoints)}}
      {{yield}}
    {{/unless}}
  </template>
}
