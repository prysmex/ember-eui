import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** Aligns its text content. */
interface Signature {
  Element: HTMLDivElement;
  Args: {
    /** `'left'`, `'center'` or `'right'`. Defaults to `'left'`. */
    textAlign?: 'left' | 'center' | 'right';
  };
  Blocks: {
    /** The content. */
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