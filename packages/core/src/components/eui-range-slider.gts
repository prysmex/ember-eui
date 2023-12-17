import classNames from '../helpers/class-names';

import type { CommonArgs } from './common';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export type EuiRangeSliderArgs = CommonArgs & {
  id?: string;
  name?: string;
  min: number;
  max: number;
  step?: number;
  value?: number;
  compressed?: boolean;
  hasFocus?: boolean;
  showRange?: boolean;
  showTicks?: boolean;
  disabled?: boolean;
  tabIndex?: number;
  onChange?: (e: InputEvent) => void;
  readonly?: boolean;
};

export interface EuiRangeSliderSignature {
  Element: HTMLInputElement;
  Args: EuiRangeSliderArgs;
}

const EuiRangeSlider: TemplateOnlyComponent<EuiRangeSliderSignature> =
  <template>
    <input
      type="range"
      id={{@id}}
      name={{@name}}
      class={{classNames
        "euiRangeSlider"
        (if @showTicks "euiRangeSlider--hasTicks")
        (if @hasFocus "euiRangeSlider--hasFocus")
        (if @showRange "euiRangeSlider--hasRange")
        (if @compressed "euiRangeSlider--compressed")
      }}
      min={{@min}}
      max={{@max}}
      step={{@step}}
      value={{@value}}
      disabled={{@disabled}}
      ...attributes
    />
  </template>;

export default EuiRangeSlider;
