import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

interface Signature {
  Element: HTMLDivElement;
  Args: {
    textAlign?: 'left' | 'center' | 'right';
  };
  Blocks: {
    default: [];
  };
}

const EuiTextAlignComponent: TemplateOnlyComponent<Signature> = <template>
  <div
    class={{classNames
      componentName="EuiTextAlign"
      textAlign=(argOrDefault @textAlign "left")
    }}
    ...attributes
  >
    {{yield}}
  </div>
</template>;

export default EuiTextAlignComponent;