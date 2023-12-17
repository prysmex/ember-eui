import { modifier } from 'ember-modifier';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
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

export interface EuiHeaderSignature {
  Element: HTMLDivElement;
  Args: {
    theme?: string;
    position?: string;
    sections?: {
      items: {
        text: string;
      }[];
      breadcrumbs: EuiHeaderBreadcrumbsSignature['Args']['breadcrumbs'];
      border: EuiHeaderSectionItemSignature['Args']['border'];
    }[];
  };
  Blocks: {
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
