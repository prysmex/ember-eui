import classNames from '../helpers/class-names.ts';

import type { CommonArgs } from './common.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export type EuiRangeSliderArgs = CommonArgs & {
  /** Id of the input. */
  id?: string;
  /** `name` of the input. */
  name?: string;
  /** Lowest value. */
  min: number;
  /** Highest value. */
  max: number;
  /** Increment between values. */
  step?: number;
  /** The value. */
  value?: number;
  /** Compressed (smaller) styling. */
  compressed?: boolean;
  /** Focus styling. */
  hasFocus?: boolean;
  /** Highlights the range from min to the value. */
  showRange?: boolean;
  /** Leaves room for ticks under the track. */
  showTicks?: boolean;
  /** Disabled styling. */
  disabled?: boolean;
  /** `tabindex` of the control. */
  tabIndex?: number;
  /** Called when the value changes (a tick or the track is clicked). */
  onChange?: (e: InputEvent) => void;
  /** Read-only. */
  readonly?: boolean;
};

/** @private The native range input of EuiRange / EuiDualRange. */
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
