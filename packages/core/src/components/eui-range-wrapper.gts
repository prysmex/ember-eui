import classNames from '../helpers/class-names';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiRangeWrapperSignature {
  Element: HTMLDivElement;
  Args: {
    fullWidth?: boolean;
    compressed?: boolean;
  };
  Blocks: {
    default: [];
  };
}

const EuiRangeWrapper: TemplateOnlyComponent<EuiRangeWrapperSignature> =
  <template>
    <div
      class={{classNames
        "euiRangeWrapper"
        (if @fullWidth "euiRangeWrapper--fullWidth")
        (if @compressed "euiRangeWrapper--compressed")
      }}
      ...attributes
    >
      {{yield}}
    </div>
  </template>;

export default EuiRangeWrapper;
