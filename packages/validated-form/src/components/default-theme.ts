import FieldBase from './validated-form/field-base.gts';
import FieldCheckboxGroupComponent from './validated-form/field-checkbox-group.gts';
import FieldComboBoxComponent from './validated-form/field-combo-box.gts';
import FieldDualRangeSliderComponent from './validated-form/field-dual-range-slider.gts';
import FieldMarkdownEditorComponent from './validated-form/field-markdown-editor.gts';
import FieldNumberComponent from './validated-form/field-number.gts';
import FieldPasswordComponent from './validated-form/field-password.gts';
import FieldRadioGroupComponent from './validated-form/field-radio-group.gts';
import FieldRangeSliderComponent from './validated-form/field-range-slider.gts';
import FieldSelectComponent from './validated-form/field-select.gts';
import FieldSwitchComponent from './validated-form/field-switch.gts';
import FieldTextComponent from './validated-form/field-text.gts';
import FieldTextAreaComponent from './validated-form/field-text-area.gts';

import type { ComponentLike } from '@glint/template';

export interface IValidatedFormTheme {
  FieldBase: ComponentLike<any>;
  FieldNumber: ComponentLike<any>;
  FieldText: ComponentLike<any>;
  FieldPassword: ComponentLike<any>;
  FieldTextArea: ComponentLike<any>;
  FieldSelect: ComponentLike<any>;
  FieldComboBox: ComponentLike<any>;
  FieldCheckboxGroup: ComponentLike<any>;
  FieldRadioGroup: ComponentLike<any>;
  FieldRangeSlider: ComponentLike<any>;
  FieldDualRangeSlider: ComponentLike<any>;
  FieldSwitch: ComponentLike<any>;
  FieldMarkdownEditor: ComponentLike<any>;
}

export const ValidatedFormDefaultTheme: IValidatedFormTheme = {
  FieldBase: FieldBase,
  FieldNumber: FieldNumberComponent,
  FieldText: FieldTextComponent,
  FieldPassword: FieldPasswordComponent,
  FieldTextArea: FieldTextAreaComponent,
  FieldSelect: FieldSelectComponent,
  FieldComboBox: FieldComboBoxComponent,
  FieldCheckboxGroup: FieldCheckboxGroupComponent,
  FieldRadioGroup: FieldRadioGroupComponent,
  FieldRangeSlider: FieldRangeSliderComponent,
  FieldDualRangeSlider: FieldDualRangeSliderComponent,
  FieldSwitch: FieldSwitchComponent,
  FieldMarkdownEditor: FieldMarkdownEditorComponent
};
