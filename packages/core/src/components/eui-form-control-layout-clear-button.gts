import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import EuiIcon from './eui-icon.gts';

import type { sizeMapping } from '../utils/css-mappings/eui-form-control-layout-clear-button.ts';
import type { CommonArgs } from './common.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

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
        componentName="EuiFormControlLayoutClearButton"
        size=(argOrDefault @size "m")
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
