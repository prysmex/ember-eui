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
import { modifier } from 'ember-modifier';
import { euiSkeletonRectangleStyles } from '../utils/eui/styles.generated.ts';

/** `'s'` and `'m'` use the theme's inline radius; `'none'` is square. */
export type EuiSkeletonRectangleRadius = 's' | 'm' | 'none';

function cssLength(value: string | number) {
  return typeof value === 'number' ? `${value}px` : value;
}

/**
 * Upstream sets the size as inline `inline-size`/`block-size` (overriding a
 * caller's `style` width/height); set them as properties so other inline
 * styles from `style="…"` are kept.
 */
const inlineSize = modifier(
  (element: HTMLElement, [width, height]: [string, string]) => {
    element.style.setProperty('inline-size', width);
    element.style.setProperty('block-size', height);
  }
);

/**
 * A rectangular placeholder of any size, e.g. for an image or chart,
 * swapped for its block once loaded.
 */
export interface EuiSkeletonRectangleSignature {
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
     * Width: a number (px) or any CSS length. Defaults to `'24px'`.
     */
    width?: string | number;
    /**
     * Height: a number (px) or any CSS length. Defaults to `'24px'`.
     */
    height?: string | number;
    /**
     * `'s'` or `'m'` (the theme's inline radius) or `'none'`. Defaults to
     * `'s'`.
     */
    borderRadius?: EuiSkeletonRectangleRadius;
  };
  Blocks: {
    /** The loaded content. */
    default: [];
  };
}

export default class EuiSkeletonRectangle extends Component<EuiSkeletonRectangleSignature> {
  get width() {
    return cssLength(this.args.width ?? '24px');
  }

  get height() {
    return cssLength(this.args.height ?? '24px');
  }

  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiSkeletonRectangleStyles);
    return euiClass(
      context,
      styles.euiSkeletonRectangle,
      styles[this.args.borderRadius ?? 's'],
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
          class="euiSkeletonRectangle {{this.classes}}"
          ...attributes
          role={{loading.role}}
          aria-label={{loading.ariaLabel}}
          {{inlineSize this.width this.height}}
        ></div>
      </:loadingContent>
      <:loadedContent>{{yield}}</:loadedContent>
    </EuiSkeletonLoading>
  </template>
}
