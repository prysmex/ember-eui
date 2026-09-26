import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
//@ts-ignore
import { getValue } from '@glimmer/tracking/primitives/cache';
import Helper from '@ember/component/helper';
//@ts-ignore
import { invokeHelper } from '@ember/helper';
import { throttle } from '@ember/runloop';

import { getBreakpoint } from '../utils/breakpoint.ts';

import type { EuiBreakpointSize } from '../utils/breakpoint.ts';

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
   * Screen sizes to show the content on: any of `'xs'`, `'s'`, `'m'`,
   * `'l'`, `'xl'`, or `'all'`. E.g. `(array "xs" "s")` shows it only on
   * phones.
   */
  sizes: EuiHideForBreakpoints[] | 'all' | 'none';
}

/** Renders its content only on the given screen sizes. See EuiHideFor. */
export interface EuiShowForSignature {
  Args: EuiShowForArgs;
  Blocks: {
    /** The content. */
    default: [];
  };
}

export default class EuiShowForComponent extends Component<EuiShowForSignature> {
  currentBreakpointHelper: any = invokeHelper(this, CurrentBreakPointHelper, () => {
    return {
      positional: [this.args.sizes]
    };
  });

  get shouldShow() {
    return getValue(this.currentBreakpointHelper);
  }

  <template>
    {{#if this.shouldShow}}
      {{yield}}
    {{/if}}
  </template>
}
