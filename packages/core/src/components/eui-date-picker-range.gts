import type { TemplateOnlyComponent } from '@ember/component/template-only';

const START = 'euiDatePicker euiDatePickerRange__start';
const END = 'euiDatePicker euiDatePickerRange__end';

/**
 * Two date inputs joined in one field with an arrow between them, for a
 * start and end date. It only does the layout: put any date input in the
 * blocks (`EuiPikaday`, `EuiFlatpickr`, or `<EuiFieldText type="date">`),
 * rendered without their own frame (`@controlOnly={{true}}`) and with the
 * class each block yields.
 */
export interface EuiDatePickerRangeSignature {
  Element: HTMLDivElement;
  Args: {
    /** Takes the container's full width instead of 400px at most. */
    fullWidth?: boolean;
    /** Read-only look. */
    readOnly?: boolean;
  };
  Blocks: {
    /** The start input; yields the classes to give it. */
    start: [className: string];
    /** The end input; yields the classes to give it. */
    end: [className: string];
    /** Anything else, instead of the start and end blocks. */
    default: [];
  };
}

const EuiDatePickerRange: TemplateOnlyComponent<EuiDatePickerRangeSignature> =
  <template>
    <div
      class="euiDatePickerRange
        {{if @fullWidth 'euiDatePickerRange--fullWidth'}}
        {{if @readOnly 'euiDatePickerRange--readOnly'}}"
      ...attributes
    >
      {{#if (has-block)}}
        {{yield}}
      {{else}}
        {{yield START to="start"}}
        <div
          class="euiText euiText--small euiDatePickerRange__delimeter"
        ><div class="euiTextColor euiTextColor--subdued">→</div></div>
        {{yield END to="end"}}
      {{/if}}
    </div>
  </template>;

export default EuiDatePickerRange;
