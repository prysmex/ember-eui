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
import { euiSkeletonTitleStyles } from '../utils/eui/styles.generated.ts';

/** EuiTitle sizes. */
export type EuiSkeletonTitleSize = 'xxxs' | 'xxs' | 'xs' | 's' | 'm' | 'l';

/**
 * A placeholder bar as tall as an EuiTitle's line, swapped for its block
 * once loaded.
 */
export interface EuiSkeletonTitleSignature {
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
    /**
     * EuiTitle size it stands in for: `'xxxs'`, `'xxs'`, `'xs'`, `'s'`,
     * `'m'` or `'l'`. Defaults to `'m'`.
     */
    size?: EuiSkeletonTitleSize;
  };
  Blocks: {
    /** The loaded content. */
    default: [];
  };
}

export default class EuiSkeletonTitle extends Component<EuiSkeletonTitleSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiSkeletonTitleStyles);
    return euiClass(
      context,
      styles.euiSkeletonTitle,
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
        <span
          class="euiSkeletonTitle {{this.classes}}"
          ...attributes
          role={{loading.role}}
          aria-label={{loading.ariaLabel}}
        ></span>
      </:loadingContent>
      <:loadedContent>{{yield}}</:loadedContent>
    </EuiSkeletonLoading>
  </template>
}
