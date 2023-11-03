import EuiIcon from '../eui-icon.gts';
import classNames from '../../helpers/class-names';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiDatePickerRangeSignature {
  Element: HTMLDivElement;
  Args: {
    fullWidth?: boolean;
    readOnly?: boolean;
    isInvalid?: boolean;
    disabled?: boolean;
    className?: string;
  };
  Blocks: {
    startDateControl: [];
    endDateControl: [];
  };
}

const EuiDatePickerRange: TemplateOnlyComponent<EuiDatePickerRangeSignature> =
  <template>
    <div
      class={{classNames
        "euiDatePickerRange"
        (if @readOnly "euiDatePickerRange--readOnly")
        (if @fullWidth "euiDatePickerRange--fullWidth")
        (if @isInvalid "euiDatePickerRange--isInvalid")
        (if @disabled "euiDatePickerRange--isDisabled")
        @className
      }}
      ...attributes
    >
      {{yield to="startDateControl"}}

      <span class="euiDatePickerRange__delimeter">
        <EuiIcon
          @color={{if @isInvalid "danger" "subdued"}}
          @type={{if @isInvalid "warning" "sortRight"}}
        />
      </span>

      {{yield to="endDateControl"}}
    </div>
  </template>;

export default EuiDatePickerRange;
