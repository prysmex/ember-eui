import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { service } from '@ember/service';

import { modifier } from 'ember-modifier';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass } from '../utils/eui/styles.ts';
import EuiScreenReaderLive from './eui-skeleton-loading/screen-reader-live.gts';

import type { EuiCss } from '../utils/eui/styles.ts';
import type EuiI18n from '../services/eui-i18n.ts';
import type { EuiScreenReaderLiveProps } from './eui-skeleton-loading/screen-reader-live.gts';

export type { EuiScreenReaderLiveProps };

/** Attributes for the `aria-busy` wrapper (upstream `ariaWrapperProps`). */
export type EuiSkeletonAriaWrapperProps = Record<
  string,
  string | number | boolean | null | undefined
>;

/** What `<:loadingContent>` receives: apply both to its root element. */
export interface EuiSkeletonLoadingProps {
  role: 'progressbar';
  ariaLabel: string;
}

/**
 * Sets the attributes of a props object on an element (upstream spreads
 * `ariaWrapperProps` onto the wrapper). `className`/`class` add classes;
 * previous values are restored when the props change or the element goes.
 */
export const applyAttributes = modifier(
  (element: Element, [props]: [EuiSkeletonAriaWrapperProps | undefined]) => {
    if (!props) return;
    const restore: Array<() => void> = [];
    for (const [key, value] of Object.entries(props)) {
      if (value === undefined || value === null) continue;
      if (key === 'className' || key === 'class') {
        const added = String(value)
          .split(/\s+/)
          .filter((name) => name && !element.classList.contains(name));
        element.classList.add(...added);
        restore.push(() => element.classList.remove(...added));
        continue;
      }
      const previous = element.getAttribute(key);
      element.setAttribute(key, String(value));
      restore.push(() =>
        previous === null
          ? element.removeAttribute(key)
          : element.setAttribute(key, previous)
      );
    }
    return () => restore.reverse().forEach((undo) => undo());
  }
);

/**
 * Swaps loading content for loaded content, marking the region
 * `aria-busy` while loading and announcing the change to screen readers
 * ("Loading …" / "Loaded …"). The other EuiSkeleton components use it.
 */
export interface EuiSkeletonLoadingSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * When true, shows `<:loadingContent>`; when false, shows
     * `<:loadedContent>` and announces to screen readers that it loaded.
     * Defaults to `true`.
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
     * `{ isActive, role, 'aria-live', focusRegionOnTextChange }` (upstream
     * EuiScreenReaderLive props).
     */
    ariaLiveProps?: EuiScreenReaderLiveProps;
    /**
     * Extra styles composed into the wrapper's class (like upstream's `css`
     * prop).
     */
    css?: EuiCss;
  };
  Blocks: {
    /**
     * Shown while loading. Put `role` and `aria-label` from the yielded
     * object on its root element (upstream adds them to `loadingContent`).
     */
    loadingContent: [EuiSkeletonLoadingProps];
    /** Shown once loaded. */
    loadedContent: [];
  };
}

export default class EuiSkeletonLoading extends Component<EuiSkeletonLoadingSignature> {
  @service declare euiI18n: EuiI18n;

  get isLoading() {
    return this.args.isLoading ?? true;
  }

  get announceLoading() {
    return this.args.announceLoadingStatus ?? false;
  }

  get announceLoaded() {
    return this.args.announceLoadedStatus ?? true;
  }

  get loadingLabel() {
    return this.euiI18n.lookupToken(
      'euiSkeletonLoading.loadingAriaText',
      'Loading {contentAriaLabel}',
      { contentAriaLabel: this.args.contentAriaLabel }
    );
  }

  get loadedLabel() {
    return this.euiI18n.lookupToken(
      'euiSkeletonLoading.loadedAriaText',
      'Loaded {contentAriaLabel}',
      { contentAriaLabel: this.args.contentAriaLabel }
    );
  }

  @cached
  get loadingProps(): EuiSkeletonLoadingProps {
    return { role: 'progressbar', ariaLabel: this.loadingLabel };
  }

  @cached
  get cssClass() {
    const css = this.args.css;
    return css ? euiClass(getEuiThemeContext(this), css) : undefined;
  }

  <template>
    <div
      class={{this.cssClass}}
      aria-busy={{if this.isLoading "true" "false"}}
      data-test-subj="euiSkeletonLoadingAriaWrapper"
      ...attributes
    >
      {{#if this.isLoading}}
        {{#if this.announceLoading}}
          <EuiScreenReaderLive
            @text={{this.loadingLabel}}
            @options={{@ariaLiveProps}}
          />
        {{/if}}
        {{yield this.loadingProps to="loadingContent"}}
      {{else}}
        {{#if this.announceLoaded}}
          <EuiScreenReaderLive
            @text={{this.loadedLabel}}
            @options={{@ariaLiveProps}}
          />
        {{/if}}
        {{yield to="loadedContent"}}
      {{/if}}
    </div>
  </template>
}
