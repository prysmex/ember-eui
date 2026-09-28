import type { TemplateOnlyComponent } from '@ember/component/template-only';

const SIZES = {
  m: 'euiLoadingChart--medium',
  l: 'euiLoadingChart--large',
  xl: 'euiLoadingChart--xLarge'
};

/**
 * Animated bars, for a chart or visualization that is loading. Give it an
 * `aria-label` (e.g. "Loading chart").
 */
export interface EuiLoadingChartSignature {
  Element: HTMLSpanElement;
  Args: {
    /** `'m'`, `'l'` or `'xl'`. Defaults to `'m'`. */
    size?: 'm' | 'l' | 'xl';
    /** Gray bars instead of colored ones. */
    mono?: boolean;
  };
}

function classes(size: keyof typeof SIZES = 'm', mono?: boolean): string {
  return ['euiLoadingChart', mono && 'euiLoadingChart--mono', SIZES[size]]
    .filter(Boolean)
    .join(' ');
}

const EuiLoadingChart: TemplateOnlyComponent<EuiLoadingChartSignature> = <template>
  <span class={{classes @size @mono}} ...attributes>
    <span class="euiLoadingChart__bar"></span>
    <span class="euiLoadingChart__bar"></span>
    <span class="euiLoadingChart__bar"></span>
    <span class="euiLoadingChart__bar"></span>
  </span>
</template>;

export default EuiLoadingChart;
