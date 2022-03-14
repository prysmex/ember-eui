import Component from '@glimmer/component';
import { throttle } from '@ember/runloop';
import { tracked } from '@glimmer/tracking';
import { EuiBreakpointSize, getBreakpoint } from '../../utils/breakpoint';
//@ts-ignore
import { invokeHelper } from '@ember/helper';
//@ts-ignore
import { getValue } from '@glimmer/tracking/primitives/cache';
import Helper from '@ember/component/helper';

export class CurrentBreakPointHelper extends Helper {
  @tracked currentBreakpoint: string | undefined;
  functionToCallOnWindowResize: undefined | (() => void);

  compute([sizes]: [EuiHideForBreakpoints[] | 'all' | 'none']) {
    this.currentBreakpoint = getBreakpoint(
      typeof window === 'undefined' ? -Infinity : window.innerWidth
    );

    this.setupListeners();

    return (
      sizes === 'all' ||
      sizes.includes(this.currentBreakpoint as EuiBreakpointSize)
    );
  }

  willDestroy(): void {
    super.willDestroy();
    this.teardown();
  }

  setupListeners() {
    this.functionToCallOnWindowResize = () => {
      const fn = () => {
        const newBreakpoint = getBreakpoint(window.innerWidth);
        if (newBreakpoint !== this.currentBreakpoint) {
          this.currentBreakpoint = newBreakpoint;
        }
      };
      throttle(this, fn, 50);
    };

    window.addEventListener('resize', this.functionToCallOnWindowResize);
  }

  teardown() {
    if (typeof this.functionToCallOnWindowResize === 'function') {
      window.removeEventListener('resize', this.functionToCallOnWindowResize);
      this.functionToCallOnWindowResize = undefined;
    }
  }
}

export type EuiHideForBreakpoints = EuiBreakpointSize;

export interface EuiShowForArgs {
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

export default class EuiShowForComponent extends Component<EuiShowForArgs> {
  currentBreakpointHelper = invokeHelper(this, CurrentBreakPointHelper, () => {
    return {
      positional: [this.args.sizes]
    };
  });

  get shouldShow() {
    return getValue(this.currentBreakpointHelper);
  }
}
