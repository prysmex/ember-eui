/**
 * Type-only test, checked by `lint:types` (tsconfig.type-tests.json), never
 * run: each yielded field takes just `@fieldName`, plus the args the control
 * really needs from the caller (`@options`, and the combo box's `@onChange`).
 * The args a field passes to its control itself (`@checked`, `@idSelected`,
 * `@value`, `@onChange`, ...) must not be required of the caller.
 */
import { Changeset } from 'ember-changeset';

import EuiChangesetForm from '../src/components/eui-changeset-form.gts';

const changeset = Changeset({});
const radioOptions = [{ id: 'a', label: 'A' }];
const checkboxOptions = [{ value: 'a', label: 'A' }];
const selectOptions = [{ value: 'a', text: 'A' }];
const comboBoxOptions = [{ label: 'A' }];
const onComboBoxChange = (selected: unknown) => void selected;

export const OnlyFieldName = <template>
  <EuiChangesetForm @changeset={{changeset}} as |form|>
    <form.FieldText @fieldName="text" />
    <form.FieldTextArea @fieldName="textArea" />
    <form.FieldPassword @fieldName="password" />
    <form.FieldNumber @fieldName="number" />
    <form.FieldRadio @fieldName="radio" />
    <form.FieldCheckbox @fieldName="checkbox" />
    <form.FieldSwitch @fieldName="switch" @label="Switch" />
    <form.FieldRangeSlider @fieldName="range" />
    <form.FieldDualRangeSlider @fieldName="dualRange" />
    <form.FieldRadioGroup @fieldName="radioGroup" @options={{radioOptions}} />
    <form.FieldCheckboxGroup
      @fieldName="checkboxGroup"
      @options={{checkboxOptions}}
    />
    <form.FieldSelect @fieldName="select" @options={{selectOptions}} />
    <form.FieldComboBox
      @fieldName="comboBox"
      @options={{comboBoxOptions}}
      @onChange={{onComboBoxChange}}
    />
  </EuiChangesetForm>
</template>;

// The text-like fields read their value from the changeset and ignore
// `@value`, so passing one is a mistake.
export const NoValueArg = <template>
  <EuiChangesetForm @changeset={{changeset}} as |form|>
    {{! @glint-expect-error }}
    <form.FieldText @fieldName="text" @value="ignored" />
    {{! @glint-expect-error }}
    <form.FieldTextArea @fieldName="textArea" @value="ignored" />
    {{! @glint-expect-error }}
    <form.FieldPassword @fieldName="password" @value="ignored" />
    {{! @glint-expect-error }}
    <form.FieldNumber @fieldName="number" @value={{1}} />
    {{! @glint-expect-error }}
    <form.FieldSelect @fieldName="s" @options={{selectOptions}} @value="a" />
  </EuiChangesetForm>
</template>;
