import { modifier } from 'ember-modifier';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import EuiHeaderBreadcrumbs from './eui-header-breadcrumbs.gts';
import EuiHeaderSection from './eui-header-section.gts';
import EuiHeaderSectionItem from './eui-header-section-item.gts';

import type { EuiHeaderBreadcrumbsSignature } from './eui-header-breadcrumbs';
import type { EuiHeaderSectionItemSignature } from './eui-header-section-item';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

let euiHeaderFixedCounter = 0;

const fixedHeaderModifier = modifier(function fixedHeader(
  _,
  [position]: [string | undefined]
): void | (() => unknown) {
  if (position === 'fixed') {
    // Increment fixed header counter for each fixed header
    euiHeaderFixedCounter++;
    document.body.classList.add('euiBody--headerIsFixed');

    return () => {
      // Both decrement the fixed counter AND then check if there are none
      if (--euiHeaderFixedCounter === 0) {
        // If there are none, THEN remove class
        document.body.classList.remove('euiBody--headerIsFixed');
      }
    };
  }
});

/**
 * The app's top bar: logo, breadcrumbs, links and actions, arranged in
 * `EuiHeaderSection`s of `EuiHeaderSectionItem`s.
 */
export interface EuiHeaderSignature {
  Element: HTMLDivElement;
  Args: {
    /** `'default'` (light) or `'dark'`. Defaults to `'default'`. */
    theme?: string;
    /**
     * `'static'` scrolls with the page; `'fixed'` stays at the top and pads
     * `<body>` for it (the body gets `euiBody--headerIsFixed`).
     * Defaults to `'static'`.
     */
    position?: string;
    /**
     * Builds the header from data instead of the block: sections of text
     * `items` and `breadcrumbs`. Most apps compose it with
     * `EuiHeaderSection`s instead.
     */
    sections?: {
      items: {
        text: string;
      }[];
      breadcrumbs: EuiHeaderBreadcrumbsSignature['Args']['breadcrumbs'];
      border: EuiHeaderSectionItemSignature['Args']['border'];
    }[];
  };
  Blocks: {
    /** `EuiHeaderSection`s (left and right), ignored with `@sections`. */
    default: [];
  };
}

const EuiHeader: TemplateOnlyComponent<EuiHeaderSignature> = <template>
  <div
    {{fixedHeaderModifier @position}}
    class={{classNames
      componentName="EuiHeader"
      theme=(argOrDefault @theme "default")
      position=(argOrDefault @position "static")
    }}
    ...attributes
  >
    {{#if @sections}}
      {{#each @sections as |section|}}
        {{#each section.items as |itemSection|}}
          <EuiHeaderSection>
            <EuiHeaderSectionItem @border={{section.border}}>
              {{itemSection.text}}
            </EuiHeaderSectionItem>
          </EuiHeaderSection>
        {{/each}}
        <EuiHeaderBreadcrumbs @breadcrumbs={{section.breadcrumbs}} />
      {{/each}}
    {{else}}
      {{yield}}
    {{/if}}
  </div>
</template>;

export default EuiHeader;
