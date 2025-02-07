import Component from '@glimmer/component';
import { getValue } from '@glimmer/tracking/primitives/cache';
import { invokeHelper } from '@ember/helper';

import { CurrentBreakPointHelper } from './eui-show-for.gts';

import type { EuiBreakpointSize } from '../utils/breakpoint.ts';

export type EuiHideForBreakpoints = EuiBreakpointSize;

export interface EuiHideForArgs {
  /**
   * List of all the responsive sizes to hide the children for.
   * Array of #EuiBreakpointSize
   */
  sizes: EuiHideForBreakpoints[] | 'all' | 'none';
}

export interface EuiHideForSignature {
  Args: EuiHideForArgs;
  Blocks: { default: [] };
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
