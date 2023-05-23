# Validated form

<EuiText>
  <p>Inspired on <strong>ember-paper</strong>'s <EuiCode>{{t "validated_form.ember_paper"}}</EuiCode></p>

  <p>The idea is simple, <strong>ValidatedForm</strong> yields most basic <strong>@ember-eui/core</strong> components with some wiring to keep the form state on sync.</p>

  <p>It uses <EuiLink @target="_blank" @href="https://github.com/offirgolan/ember-validators">ember-validators</EuiLink> by default to describe the validations. To provide the validations ergonomically you'd just pass a hash where each key is a valid
ember-valitador validator, <EuiCode>length</EuiCode>, <EuiCode>presence</EuiCode>, <EuiCode>number</EuiCode>, the values and the <EuiCode>config</EuiCode> expected by those.</p>

<p><EuiCodeBlock @isCopyable={{true}}>ember install @ember-eui/validated-form</EuiCodeBlock></p>

</EuiText>

```hbs template
<ValidatedForm as |Form|>
  <Form.FieldText
    @value={{this.data.fieldText}}
    @label='Email'
    @onChange={{set this.data 'fieldText'}}
    @validations={{hash
      presence=(hash presence=true)
      format=(hash type='email')
    }}
  />
  <Form.FieldMarkdownEditor
    @value={{this.data.markdownText}}
    @label='Markdown'
    @onChange={{set this.data 'markdownText'}}
    @validations={{hash presence=(hash presence=true)}}
    @error={{array 'one error'}}
  />
  <Form.FieldSelect
    @onChange={{set this.data 'fieldSelect'}}
    @value={{this.data.fieldSelect}}
    @validations={{hash presence=(hash presence=true)}}
    @options={{array
      (hash value='mx' text='Mexico')
      (hash value='pt' text='Portugal')
      (hash value='us' text='United States')
    }}
    @label='Country'
  />
  <Form.FieldComboBox
    @onChange={{set this.data 'fieldComboBoxSingleSelection'}}
    @singleSelection={{true}}
    @selectedOptions={{this.data.fieldComboBoxSingleSelection}}
    @validations={{hash presence=(hash presence=true)}}
    @required={{true}}
    @options={{array
      (hash value='mx' text='Mexico')
      (hash value='pt' text='Portugal')
      (hash value='us' text='United States')
    }}
    @label='fieldComboBoxSingleSelection'
    as |option|
  >
    {{option.text}}
  </Form.FieldComboBox>
  <Form.FieldComboBox
    @onChange={{set this.data 'fieldComboBoxMultiple'}}
    @selectedOptions={{this.data.fieldComboBoxMultiple}}
    @validations={{hash presence=(hash presence=true) length=(hash min=2)}}
    @hasNoInitialSelection={{true}}
    @options={{array
      (hash value='mx' text='Mexico')
      (hash value='pt' text='Portugal')
      (hash value='us' text='United States')
    }}
    @label='fieldComboBoxMultiple'
    as |option|
  >
    {{option.text}}
  </Form.FieldComboBox>
  <Form.FieldRangeSlider
    @onChange={{set this.data 'rangeSlider'}}
    @value={{this.data.rangeSlider}}
    @label='Range slider'
    @showLabels={{true}}
    @showValue={{true}}
    @min={{0}}
    @max={{300}}
    @validations={{hash
      number=(hash gte=0 lte=100 allowString=true)
      presence=(hash presence=true)
    }}
    @required={{true}}
  />
  <Form.FieldCheckboxGroup
    @onChange={{set this.data 'fieldCheckbox'}}
    @validations={{hash presence=(hash presence=true) length=(hash min=1)}}
    @value={{this.data.fieldCheckbox}}
    @options={{array
      (hash id='checkbox-1' label='Checkbox 1')
      (hash id='checkbox-2' label='Checkbox 2')
      (hash id='checkbox-3' label='Checkbox 3')
    }}
    @label='Checkbox Group'
  />
  <Form.FieldRadioGroup
    @onChange={{set this.data 'fieldRadioGroup'}}
    @validations={{hash presence=(hash presence=true)}}
    @value={{this.data.fieldRadioGroup}}
    @options={{array
      (hash id='radio-1' label='Radio 1')
      (hash id='radio-2' label='Radio 2')
      (hash id='radio-3' label='Radio 3')
    }}
    @label='Radio Group'
  />
  <Form.FieldNumber
    @value={{this.data.fieldNumber}}
    @onChange={{set this.data 'fieldNumber'}}
    @validations={{hash number=(hash lt=10 allowString=true)}}
    @label='Less than 10'
    @errors={{this.data.errors}}
  />
  <Form.FieldPassword
    @value={{this.data.fieldPassword}}
    @onChange={{set this.data 'fieldPassword'}}
    @validations={{hash presence=(hash presence=true)}}
    @label='Field password'
  />
  <Form.FieldTextArea
    @value={{this.data.fieldTextArea}}
    @onChange={{set this.data 'fieldTextArea'}}
    @validations={{hash length=(hash min=10) presence=(hash presence=true)}}
    @label='Field Text minlength 10'
  />
  <Form.FieldSwitch
    @validations={{hash presence=(hash presence=true)}}
    @value={{this.data.fieldSwitch}}
    @label='Field must be true'
    @onChange={{set this.data 'fieldSwitch'}}
  />
  <Form.FieldNestedForm as |NestedForm|>
    <NestedForm.FieldText
      @validations={{hash presence=(hash presence=true)}}
      @label='Nested form field text'
      @value={{this.data.nestedFormFieldText}}
      @onChange={{set this.data 'nestedFormFieldText'}}
    />
  </Form.FieldNestedForm>
  <EuiButton @type='submit'>
    Submit
  </EuiButton>
</ValidatedForm>
```

```js component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import O from '@ember/object';

export default class DemoCardComponent extends Component {
  @tracked data = O.create({});
}
```
