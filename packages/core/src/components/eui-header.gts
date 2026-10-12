import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { modifier } from 'ember-modifier';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiHeaderStyles,
  euiHeaderVariables
} from '../utils/eui/styles.generated.ts';
import EuiHeaderBreadcrumbs from './eui-header-breadcrumbs.gts';
import EuiHeaderSection from './eui-header-section.gts';
import EuiHeaderSectionItem from './eui-header-section-item.gts';

import type { EuiHeaderBreadcrumbsSignature } from './eui-header-breadcrumbs';
import type { EuiHeaderSectionItemSignature } from './eui-header-section-item';

/** Upstream `euiFixedHeadersCount`: fixed headers currently rendered. */
let euiFixedHeadersCount = 0;
/** The body's own inline `padding-top`, restored when the last header leaves. */
let bodyPaddingTop = '';

const FIXED_OFFSET = '--euiFixedHeadersOffset';

function multiply(length: string, times: number): string {
  const match = /^(-?[\d.]+)(.*)$/.exec(length);
  return match ? `${Number(match[1]) * times}${match[2]}` : length;
}

/**
 * Upstream `EuiFixedHeader`: stacks each fixed header below the previous
 * ones, keeps `--euiFixedHeadersOffset` (on `<html>`) at the total height and
 * adds `euiBody--headerIsFixed`. Ember additionally pads `<body>` by the
 * offset, as the documented API always did (formerly through legacy CSS).
 */
const fixedHeaderModifier = modifier(function fixedHeader(
  element: HTMLElement,
  [position, height]: [string | undefined, string]
): () => void {
  // Always return a teardown: ember-modifier keeps the previous one when a
  // run returns nothing, which would run it twice (fixed -> static -> fixed).
  if (position !== 'fixed') return () => {};
  const root = document.documentElement;
  const body = document.body;

  // Upstream sets `top` from the previous headers; a caller's `style` wins.
  const ownTop = !element.style.top;
  if (ownTop) element.style.top = multiply(height, euiFixedHeadersCount);
  element.setAttribute('data-fixed-header', 'true');

  if (euiFixedHeadersCount === 0) bodyPaddingTop = body.style.paddingTop;
  euiFixedHeadersCount++;
  root.style.setProperty(FIXED_OFFSET, multiply(height, euiFixedHeadersCount));
  body.classList.add('euiBody--headerIsFixed');
  body.style.paddingTop = `var(${FIXED_OFFSET}, 0)`;

  return () => {
    euiFixedHeadersCount--;
    if (ownTop) element.style.top = '';
    element.removeAttribute('data-fixed-header');
    if (euiFixedHeadersCount === 0) {
      root.style.removeProperty(FIXED_OFFSET);
      body.classList.remove('euiBody--headerIsFixed');
      body.style.paddingTop = bodyPaddingTop;
    } else {
      root.style.setProperty(
        FIXED_OFFSET,
        multiply(height, euiFixedHeadersCount)
      );
    }
  };
});

export type EuiHeaderSections = {
  /** Wrapped in one `EuiHeaderSection`, each in an `EuiHeaderSectionItem`. */
  items?: {
    text: string;
  }[];
  /** Rendered as `EuiHeaderBreadcrumbs` after the section. */
  breadcrumbs?: EuiHeaderBreadcrumbsSignature['Args']['breadcrumbs'];
  /** @deprecated Has no effect: latest EUI removed section item borders. */
  border?: EuiHeaderSectionItemSignature['Args']['border'];
}[];

/**
 * The app's top bar: logo, breadcrumbs, links and actions, arranged in
 * `EuiHeaderSection`s of `EuiHeaderSectionItem`s.
 */
export interface EuiHeaderSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * `'default'` follows the light/dark theme; `'dark'` always renders a
     * dark header (upstream's pseudo dark theme for logo, links and
     * buttons). Defaults to `'default'`.
     */
    theme?: 'default' | 'dark' | (string & {});
    /**
     * `'static'` scrolls with the page; `'fixed'` stays at the top. Fixed
     * headers stack below each other, set the `--euiFixedHeadersOffset` CSS
     * variable on `<html>` to their total height, give `<body>` the
     * `euiBody--headerIsFixed` class and pad `<body>` by that offset.
     * Defaults to `'static'`.
     */
    position?: 'static' | 'fixed' | (string & {});
    /**
     * Builds the header from data instead of the block: per section, one
     * `EuiHeaderSection` of text `items`, then optional `breadcrumbs`.
     * Most apps compose it with `EuiHeaderSection`s instead.
     */
    sections?: EuiHeaderSections;
  };
  Blocks: {
    /** `EuiHeaderSection`s (left and right), ignored with `@sections`. */
    default: [];
  };
}

/** Upstream `EuiHeader` (`euiHeaderStyles`). */
export default class EuiHeader extends Component<EuiHeaderSignature> {
  get position(): 'static' | 'fixed' {
    return this.args.position === 'fixed' ? 'fixed' : 'static';
  }

  get theme(): 'default' | 'dark' {
    return this.args.theme === 'dark' ? 'dark' : 'default';
  }

  @cached
  get height(): string {
    const context = getEuiThemeContext(this);
    return useEuiBorealisStyles(context, euiHeaderVariables).height;
  }

  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiHeaderStyles);
    return euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiHeader,
      styles[this.position],
      styles[this.theme]
    );
  }

  <template>
    <div
      class="euiHeader {{this.classes}}"
      {{fixedHeaderModifier this.position this.height}}
      ...attributes
    >
      {{#if @sections}}
        {{#each @sections as |section|}}
          {{#if section.items}}
            <EuiHeaderSection>
              {{#each section.items as |item|}}
                <EuiHeaderSectionItem>{{item.text}}</EuiHeaderSectionItem>
              {{/each}}
            </EuiHeaderSection>
          {{/if}}
          {{#if section.breadcrumbs}}
            <EuiHeaderBreadcrumbs @breadcrumbs={{section.breadcrumbs}} />
          {{/if}}
        {{/each}}
      {{else}}
        {{yield}}
      {{/if}}
    </div>
  </template>
}
