import EuiFlexGroup from './eui-flex-group.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

const GUTTERS = {
  none: 'euiFacetGroup--gutterNone',
  s: 'euiFacetGroup--gutterSmall',
  m: 'euiFacetGroup--gutterMedium',
  l: 'euiFacetGroup--gutterLarge'
};

/** Lays out `EuiFacetButton`s in a column or in wrapping rows. */
export interface EuiFacetGroupSignature {
  Element: HTMLDivElement | HTMLSpanElement;
  Args: {
    /**
     * `'vertical'` (a column) or `'horizontal'` (wrapping rows).
     * Defaults to `'vertical'`.
     */
    layout?: 'vertical' | 'horizontal';
    /** Space between buttons: `'none'`, `'s'`, `'m'` or `'l'`. Defaults to `'m'`. */
    gutterSize?: 'none' | 's' | 'm' | 'l';
  };
  Blocks: {
    /** The `EuiFacetButton`s. */
    default: [];
  };
}

function classes(layout: string = 'vertical', gutterSize: keyof typeof GUTTERS = 'm'): string {
  return `euiFacetGroup euiFacetGroup--${layout} ${GUTTERS[gutterSize]}`;
}

function isHorizontal(layout?: string): boolean {
  return layout === 'horizontal';
}

const EuiFacetGroup: TemplateOnlyComponent<EuiFacetGroupSignature> = <template>
  <EuiFlexGroup
    class={{classes @layout @gutterSize}}
    @direction={{if (isHorizontal @layout) "row" "column"}}
    @wrap={{isHorizontal @layout}}
    @gutterSize="none"
    ...attributes
  >
    {{yield}}
  </EuiFlexGroup>
</template>;

export default EuiFacetGroup;
