# Demo

```hbs template
<EuiChangesetForm @changeset={{changeset this.model this.Validations}} as |Form changesetObj|>
  <EuiFlexGroup @direction="column" @gutterSize="l">
    <Form.FieldText @fieldName="firstName" @label="First Name" />
    <Form.FieldTextArea @fieldName="lastName" @label="Last Name" />
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
    <Form.FieldNumber @fieldName="age" @label="Age" />
    <Form.FieldText @fieldName="email" @label="Email" />
    <Form.FieldSwitch @fieldClasses="euiFlexItem" @fieldName="switch" @label="Switch" />
    <Form.FieldPassword @fieldName="password" @label="Password" />
    <Form.FieldPassword @fieldName="passwordConfirmation" @label="Password Confirmation" />
    <EuiButton @type="submit" @isDisabled={{changesetObj.isInvalid}}>
      Submit form
    </EuiButton>
  </EuiFlexGroup>
</EuiChangesetForm>
```


```js component
import Component from "@glimmer/component";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import {
  validatePresence,
  validateLength,
  validateConfirmation,
  validateFormat,
  validateNumber,
} from "ember-changeset-validations/validators";

export const Validations = {
  firstName: [validatePresence(true), validateLength({ min: 4 })],
  lastName: validatePresence(true),
  rangeSlider1: validateNumber({ gte: 150 }),
  country: validatePresence(true),
  radioGroup: validatePresence(true),
  checkboxGroup: validatePresence(true),
  email: validateFormat({ type: "email" }),
  password: [validateLength({ min: 8 })],
  passwordConfirmation: validateConfirmation({ on: "password" }),
};

export default class DemoCardComponent extends Component {
  Validations = Validations;

  model = {
    firstName: "Alberto",
    country: "",
    rangeSlider1: 150,
    lastName: "",
    checkboxGroup: ["checkbox-1"],
    email: "",
    password: "",
    passwordConfirmation: "",
  };
}

```