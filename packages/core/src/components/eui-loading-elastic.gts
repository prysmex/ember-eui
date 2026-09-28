import EuiIcon from './eui-icon.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

const SIZES = {
  m: 'euiLoadingElastic--medium',
  l: 'euiLoadingElastic--large',
  xl: 'euiLoadingElastic--xLarge',
  xxl: 'euiLoadingElastic--xxLarge'
};

/**
 * The Elastic logo, animated, for a full page or app that is loading.
 * Give it an `aria-label` (e.g. "Loading").
 */
export interface EuiLoadingElasticSignature {
  Element: HTMLSpanElement;
  Args: {
    /** `'m'`, `'l'`, `'xl'` or `'xxl'`. Defaults to `'m'`. */
    size?: 'm' | 'l' | 'xl' | 'xxl';
  };
}

function sizeClass(size: keyof typeof SIZES = 'm'): string {
  return SIZES[size];
}

const EuiLoadingElastic: TemplateOnlyComponent<EuiLoadingElasticSignature> =
  <template>
    <span class="euiLoadingElastic {{sizeClass @size}}" ...attributes>
      <EuiIcon @type="logoElastic" @size={{if @size @size "m"}} />
    </span>
  </template>;

export default EuiLoadingElastic;
