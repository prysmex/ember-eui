import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import Helper from '@ember/component/helper';
import { throttle } from '@ember/runloop';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';

import type { EuiBreakpointSize, EuiBreakpoints } from '../utils/breakpoint.ts';

export type EuiHideForBreakpoints = EuiBreakpointSize;

/** `'all'`, `'none'` or a list of breakpoint names. */
export type EuiResponsiveSizes = EuiHideForBreakpoints[] | 'all' | 'none';

/**
 * Upstream `useCurrentEuiBreakpoint`: the name of the largest breakpoint
 * whose minimum width is at most the window width.
 */
export function currentBreakpoint(
  width: number,
  breakpoints: EuiBreakpoints
): EuiBreakpointSize | undefined {
  return (Object.keys(breakpoints) as EuiBreakpointSize[])
    .sort((a, b) => breakpoints[b] - breakpoints[a])
    .find((key) => breakpoints[key] <= width);
}

/** Whether the current breakpoint is one of `sizes` (`'all'` always is). */
export class CurrentBreakPointHelper extends Helper<{
  Args: { Positional: [sizes: EuiResponsiveSizes, breakpoints: EuiBreakpoints] };
  Return: boolean;
}> {
  @tracked width = typeof window === 'undefined' ? -Infinity : window.innerWidth;
  #listening = false;

  onResize = () => {
    throttle(this, this.measure, 50);
  };

  measure() {
    if (this.isDestroying || this.isDestroyed) return;
    if (window.innerWidth !== this.width) this.width = window.innerWidth;
  }

  compute([sizes, breakpoints]: [EuiResponsiveSizes, EuiBreakpoints]): boolean {
    if (!this.#listening && typeof window !== 'undefined') {
      window.addEventListener('resize', this.onResize);
      this.#listening = true;
    }
    if (sizes === 'all') return true;
    if (sizes === 'none' || !Array.isArray(sizes)) return false;
    const current = currentBreakpoint(this.width, breakpoints);
    return current !== undefined && sizes.includes(current);
  }

  willDestroy(): void {
    super.willDestroy();
    if (this.#listening) window.removeEventListener('resize', this.onResize);
  }
}

export interface EuiShowForArgs {
  /**
   * Screen sizes to show the content on: any of `'xs'`, `'s'`, `'m'`,
   * `'l'`, `'xl'` (the nearest theme's `breakpoint` values), or `'all'` /
   * `'none'`. E.g. `(array "xs" "s")` shows it only on phones.
   */
  sizes: EuiResponsiveSizes;
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
  get breakpoints(): EuiBreakpoints {
    return getEuiThemeContext(this).upstream.euiTheme
      .breakpoint as EuiBreakpoints;
  }

  <template>
    {{#if (CurrentBreakPointHelper @sizes this.breakpoints)}}
      {{yield}}
    {{/if}}
  </template>
}
