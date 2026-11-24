/**
 * `EuiDatePicker`'s native input (DESIGN 6.1): `<input type="date">`,
 * `datetime-local` or `time` with `EuiFieldText`'s classes, in place of the
 * text input and its popover. The OS draws the picker; the component
 * converts the value in and out and checks every value it gets
 * (`-private/native-date-input.ts`). Private: rendered by `EuiDatePicker`.
 */
import { on } from '@ember/modifier';

import EuiFieldText from '../eui-field-text.gts';

import type EuiDatePicker from '../eui-date-picker.gts';
import type { TOC } from '@ember/component/template-only';

const EuiDatePickerNativeInput: TOC<{
  Element: HTMLInputElement;
  Args: { picker: EuiDatePicker };
}> = <template>
  {{#let @picker.nativeAttributes as |native|}}
    <EuiFieldText
      @controlOnly={{true}}
      @id={{@picker.inputId}}
      @value={{native.value}}
      @compressed={{@picker.args.compressed}}
      @fullWidth={{@picker.args.fullWidth}}
      @isInvalid={{@picker.isInvalid}}
      @disabled={{@picker.args.disabled}}
      @inputRef={{@picker.registerInput}}
      class="euiDatePicker euiDatePicker--native
        {{@picker.nativeClass}}
        {{@picker.inputErrorClass}}"
      type={{native.type}}
      min={{native.min}}
      max={{native.max}}
      step={{native.step}}
      data-picker-icon={{if @picker.nativeIconOpens ""}}
      ...attributes
      {{on "input" @picker.onNativeInput}}
      {{on "change" @picker.onNativeChange}}
      {{@picker.markNativeEmpty native.value}}
      {{on "focusout" @picker.onNativeFocusOut}}
    />
  {{/let}}
</template>;

export default EuiDatePickerNativeInput;
