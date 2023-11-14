import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import EuiIcon from './eui-icon.gts';
import { sizeToClassNameMap } from '../utils/css-mappings/eui-health';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiHealthSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * The color of the health indicator.
     */
    color?: string;

    /**
     * The size of the health indicator.
     */
    textSize?: keyof typeof sizeToClassNameMap;
  };
  Blocks: {
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
