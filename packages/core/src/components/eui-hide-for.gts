import Component from '@glimmer/component';
import { getValue } from '@glimmer/tracking/primitives/cache';
import { invokeHelper } from '@ember/helper';

import { CurrentBreakPointHelper } from './eui-show-for.gts';

import type { EuiBreakpointSize } from '../utils/breakpoint.ts';

export type EuiHideForBreakpoints = EuiBreakpointSize;

export interface EuiHideForArgs {
  /**
   * Screen sizes to hide the content on: any of `'xs'`, `'s'`, `'m'`,
   * `'l'`, `'xl'`, or `'all'`. E.g. `(array "xs" "s")` hides it on phones.
   */
  sizes: EuiHideForBreakpoints[] | 'all' | 'none';
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
  currentBreakpointHelper: any = invokeHelper(
    this,
    CurrentBreakPointHelper,
    () => {
      return {
        positional: [this.args.sizes]
      };
    }
  );

  get shouldShow() {
    return !getValue(this.currentBreakpointHelper);
  }

  <template>
    {{#if this.shouldShow}}
      {{yield}}
    {{/if}}
  </template>
}
