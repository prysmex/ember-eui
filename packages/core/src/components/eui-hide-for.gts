import Component from '@glimmer/component';
import type { EuiBreakpointSize } from '../utils/breakpoint';
import { CurrentBreakPointHelper } from './eui-show-for.gts';
//@ts-expect-error
import { invokeHelper } from '@ember/helper';
//@ts-expect-error
import { getValue } from '@glimmer/tracking/primitives/cache';

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
  currentBreakpointHelper = invokeHelper(this, CurrentBreakPointHelper, () => {
    return {
      positional: [this.args.sizes]
    };
  });

  get shouldShow() {
    return !getValue(this.currentBreakpointHelper);
  }

  <template>
    {{#if this.shouldShow}}
      {{yield}}
    {{/if}}
  </template>
}
