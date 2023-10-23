import Component from '@glimmer/component';
import { EuiBreakpointSize } from '../../utils/breakpoint';
import { CurrentBreakPointHelper } from '../eui-show-for';
//@ts-ignore
import { invokeHelper } from '@ember/helper';
//@ts-ignore
import { getValue } from '@glimmer/tracking/primitives/cache';

export type EuiHideForBreakpoints = EuiBreakpointSize;

export interface EuiHideForArgs {
  /**
   * Required otherwise nothing ever gets returned
   */
  children: Component;
  /**
   * List of all the responsive sizes to hide the children for.
   * Array of #EuiBreakpointSize
   */
  sizes: EuiHideForBreakpoints[] | 'all' | 'none';
}

export default class EuiHideForComponent extends Component<EuiHideForArgs> {
  currentBreakpointHelper = invokeHelper(this, CurrentBreakPointHelper, () => {
    return {
      positional: [this.args.sizes]
    };
  });

  get shouldShow() {
    return !getValue(this.currentBreakpointHelper);
  }
}
