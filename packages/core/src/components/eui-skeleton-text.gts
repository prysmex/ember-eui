import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiSkeletonLoading, { applyAttributes } from './eui-skeleton-loading.gts';

import type { EuiCss } from '../utils/eui/styles.ts';
import type {
  EuiScreenReaderLiveProps,
  EuiSkeletonAriaWrapperProps
} from './eui-skeleton-loading.gts';
import { euiSkeletonTextStyles } from '../utils/eui/styles.generated.ts';

/** Line heights of the text being replaced. */
export type EuiSkeletonTextSize = 'm' | 's' | 'xs' | 'relative';

/**
 * Placeholder lines for text that is loading, swapped for its block once
 * loaded.
 */
export interface EuiSkeletonTextSignature {
  Element: HTMLSpanElement;
  Args: {
    /**
     * When true, shows the skeleton; when false, shows the block and
     * announces to screen readers that the content loaded. Defaults to
     * `true`.
     */
    isLoading?: boolean;
    /**
     * Label your loading sections to give screen readers more context: pass
     * "API keys" to have them read "Loading API keys" and "Loaded API keys".
     */
    contentAriaLabel?: string;
    /**
     * Makes a live screen reader announcement when `@isLoading` is true.
     * Defaults to `false`.
     */
    announceLoadingStatus?: boolean;
    /**
     * Makes a live screen reader announcement when `@isLoading` is false.
     * Defaults to `true`.
     */
    announceLoadedStatus?: boolean;
    /**
     * Options for the live region that announces the status:
     * `{ isActive, role, 'aria-live', focusRegionOnTextChange }`.
     */
    ariaLiveProps?: EuiScreenReaderLiveProps;
    /** Attributes for the `aria-busy` wrapper around the skeleton. */
    ariaWrapperProps?: EuiSkeletonAriaWrapperProps;
    /**
     * Extra styles composed last into the skeleton's class (like upstream's
     * `css` prop).
     */
    css?: EuiCss;
    /** Number of lines to display (1 to 10). Defaults to `3`. */
    lines?: number;
    /**
     * EuiText size the lines stand in for: `'m'`, `'s'`, `'xs'`, or
     * `'relative'` (`1em`). Defaults to `'m'`.
     */
    size?: EuiSkeletonTextSize;
  };
  Blocks: {
    /** The loaded content. */
    default: [];
  };
}

export default class EuiSkeletonText extends Component<EuiSkeletonTextSignature> {
  get lines() {
    return Array.from({ length: Math.max(0, this.args.lines ?? 3) });
  }

  @cached
  get lineClass() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiSkeletonTextStyles);
    return euiClass(context, styles.euiSkeletonText, styles[this.args.size ?? 'm']);
  }

  @cached
  get rootClass() {
    const css = this.args.css;
    return css ? euiClass(getEuiThemeContext(this), css) : '';
  }

  <template>
    <EuiSkeletonLoading
      @isLoading={{@isLoading}}
      @contentAriaLabel={{@contentAriaLabel}}
      @announceLoadingStatus={{@announceLoadingStatus}}
      @announceLoadedStatus={{@announceLoadedStatus}}
      @ariaLiveProps={{@ariaLiveProps}}
      {{applyAttributes @ariaWrapperProps}}
    >
      <:loadingContent as |loading|>
        <span
          class="euiSkeletonText {{this.rootClass}}"
          ...attributes
          role={{loading.role}}
          aria-label={{loading.ariaLabel}}
        >{{#each this.lines}}<span class={{this.lineClass}}></span>{{/each}}</span>
      </:loadingContent>
      <:loadedContent>{{yield}}</:loadedContent>
    </EuiSkeletonLoading>
  </template>
}
