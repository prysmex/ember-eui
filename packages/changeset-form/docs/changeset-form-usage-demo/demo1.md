# Demo

```hbs template
<EuiChangesetForm @changeset={{changeset this.model this.Validations}} as |Form changesetObj|>
  <EuiFlexGroup @direction="column" @gutterSize="none" >
    <Form.FieldText @fieldName="user.firstName" @label="First Name" />
    <Form.FieldTextArea @fieldName="user.lastName" @label="Last Name" />
    <Form.FieldRangeSlider
      @fieldName="rangeSlider1"
      @label="Range slider"
      @showLabels={{true}}
      @showValue={{true}}
      @min={{0}}
      @max={{300}}
    />
    <Form.FieldRadioGroup
      @fieldName="radioGroup"
      @options={{array
        (hash id="radio-1" label="Radio 1")
        (hash id="radio-2" label="Radio 2")
        (hash id="radio-3" label="Radio 3")
      }}
      @label="Radio Group"
    />
    <Form.FieldCheckboxGroup
      @fieldName="checkboxGroup"
      @options={{array
        (hash id="checkbox-1" label="Checkbox 1")
        (hash id="checkbox-2" label="Checkbox 2")
        (hash id="checkbox-3" label="Checkbox 3")
      }}
      @label="Checkbox Group"
    />
    <Form.FieldSelect
      @fieldName="country"
      @hasNoInitialSelection={{true}}
      @options={{array
        (hash value="mx" text="Mexico")
        (hash value="pt" text="Portugal")
        (hash value="us" text="United States")
      }}
      @label="Country"
    />
    <Form.FieldComboBox
      @fieldName="veggies"
      @label="Choose a veggie"
      @options={{array "🥦" "🥬" "🍅" "🥑"}}
      @helpText="100% natural"
    as |option|>
      {{option}}
    </Form.FieldComboBox>
    <Form.FieldComboBox
      @fieldName="favVeggie"
      @label="Now choose your favorite veggie!"
      @options={{array "🥦" "🥬" "🍅" "🥑"}}
      @helpText="100% natural"
      @singleSelection={{hash asPlainText=true}}
    as |option|>
      {{option}}
    </Form.FieldComboBox>
    <Form.FieldNumber @fieldName="age" @label="Age" />
    <Form.FieldText @fieldName="email" @label="Email" />
    <Form.FieldSwitch @fieldClasses="euiFlexItem" @fieldName="switch" @label="Switch" @switchLabel="Switch Text"/>
    <Form.FieldPassword @fieldName="password" @label="Password" />
    <Form.FieldPassword @fieldName="passwordConfirmation" @label="Password Confirmation" />
    <EuiButton @type="submit" @isDisabled={{changesetObj.isInvalid}}>
      Submit form
    </EuiButton>
  </EuiFlexGroup>
</EuiChangesetForm>
```

```js component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import {
  validatePresence,
  validateLength,
  validateConfirmation,
  validateFormat,
  validateNumber
} from 'ember-changeset-validations/validators';

export const Validations = {
  user: {
    firstName: [validatePresence(true), validateLength({ min: 4 })],
    lastName: validatePresence(true)
  },
  veggies: validatePresence(true),
  rangeSlider1: validateNumber({ gte: 150 }),
  country: validatePresence(true),
  radioGroup: validatePresence(true),
  checkboxGroup: validatePresence(true),
  email: validateFormat({ type: 'email' }),
  password: [validateLength({ min: 8 })],
  passwordConfirmation: validateConfirmation({ on: 'password' })
};

export default class DemoCardComponent extends Component {
  Validations = Validations;

  model = {
    user: {
      firstName: 'Alberto',
      lastName: ''
    },
    country: '',
    rangeSlider1: 150,
    checkboxGroup: ['checkbox-1'],
    email: '',
    password: '',
    passwordConfirmation: ''
  };
}
```
