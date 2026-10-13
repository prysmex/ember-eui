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
import { euiSkeletonCircleStyles } from '../utils/eui/styles.generated.ts';

/** `'s'` (24px), `'m'` (32px), `'l'` (40px), `'xl'` (64px) at Borealis defaults. */
export type EuiSkeletonCircleSize = 's' | 'm' | 'l' | 'xl';

/**
 * A round placeholder, e.g. for an avatar, swapped for its block once
 * loaded.
 */
export interface EuiSkeletonCircleSignature {
  Element: HTMLDivElement;
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
    /**
     * `'s'`, `'m'`, `'l'` or `'xl'` (theme sizes l, xl, xxl and 4 × base).
     * Defaults to `'m'`.
     */
    size?: EuiSkeletonCircleSize;
  };
  Blocks: {
    /** The loaded content. */
    default: [];
  };
}

export default class EuiSkeletonCircle extends Component<EuiSkeletonCircleSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiSkeletonCircleStyles);
    return euiClass(
      context,
      styles.euiSkeletonCircle,
      styles[this.args.size ?? 'm'],
      this.args.css
    );
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
        <div
          class="euiSkeletonCircle {{this.classes}}"
          ...attributes
          role={{loading.role}}
          aria-label={{loading.ariaLabel}}
        ></div>
      </:loadingContent>
      <:loadedContent>{{yield}}</:loadedContent>
    </EuiSkeletonLoading>
  </template>
}
