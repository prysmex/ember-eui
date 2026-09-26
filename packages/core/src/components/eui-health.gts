import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import EuiIcon from './eui-icon.gts';

import type { sizeToClassNameMap } from '../utils/css-mappings/eui-health.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A status: a colored dot followed by text, e.g. "Healthy" or "Down". */
export interface EuiHealthSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * Color of the dot: `'success'`, `'warning'`, `'danger'`, `'subdued'`,
     * any `EuiIcon` color or a CSS color.
     */
    color?: string;

    /**
     * Text size: `'xs'`, `'s'`, `'m'` or `'inherit'`. Defaults to `'m'`.
     */
    textSize?: keyof typeof sizeToClassNameMap;
  };
  Blocks: {
    /** The status text. */
    default: [];
  };
}

const EuiHealth: TemplateOnlyComponent<EuiHealthSignature> = <template>
  <div
    class={{classNames
      componentName="EuiHealth"
      textSize=(argOrDefault @textSize "m")
    }}
    ...attributes
  >
    <div
      class="euiFlexGroup euiFlexGroup--gutterExtraSmall euiFlexGroup--alignItemsCenter euiFlexGroup--directionRow"
    >
      <div class="euiFlexItem euiFlexItem--flexGrowZero">
        <EuiIcon @type="dot" @color={{@color}} />
      </div>
      <div class="euiFlexItem euiFlexItem--flexGrowZero">
        {{yield}}
      </div>
    </div>
  </div>
</template>;

export default EuiHealth;
