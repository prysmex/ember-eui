import classNames from '../helpers/class-names';
import EuiIcon from './eui-icon.gts';

import type { CommonArgs } from './common';
import type { TemplateOnlyComponent } from '@ember/component/template-only';
import { sizeMapping } from '../utils/css-mappings/eui-form-control-layout-clear-button';

export type EuiFormControlLayoutClearButtonArgs = CommonArgs & {
  size?: keyof typeof sizeMapping;
  label?: string;
};

export interface EuiFormControlLayoutClearButtonSignature {
  Element: HTMLButtonElement;
  Args: EuiFormControlLayoutClearButtonArgs;
}

const EuiFormControlLayoutClearButton: TemplateOnlyComponent<EuiFormControlLayoutClearButtonSignature> =
  <template>
    <button
      class={{classNames
        "euiFormControlLayoutClearButton"
        componentName="EuiFormControlLayoutClearButton"
        size=@size
      }}
      type="button"
      aria-label={{@label}}
      ...attributes
    >
      <EuiIcon
        @iconClasses="euiFormControlLayoutClearButton__icon"
        @type="cross"
      />
    </button>
  </template>;

export default EuiFormControlLayoutClearButton;
