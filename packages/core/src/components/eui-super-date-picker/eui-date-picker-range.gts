import classNames from '../../helpers/class-names.ts';
import EuiIcon from '../eui-icon.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** @private Two date controls with an arrow between them. */
export interface EuiDatePickerRangeSignature {
  Element: HTMLDivElement;
  Args: {
    /** Stretches to the container's width. */
    fullWidth?: boolean;
    /** Read-only styling. */
    readOnly?: boolean;
    /** Invalid styling. */
    isInvalid?: boolean;
    /** Disabled styling. */
    disabled?: boolean;
    /** Extra class(es). */
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
