# Nested forms

The customer fields belong to the parent form. The indented delivery address is
a separate validated form: all three address fields must be valid before the
parent can be saved. Try saving the empty address, use **Fill example**, or remove
the address to see how the parent responds.

```hbs template
<ValidatedForm
  @fullWidth={{true}}
  @onSubmit={{this.save}}
  @onInvalid={{this.invalid}}
  novalidate
  as |form|
>
  <EuiPanel @hasBorder={{true}} @paddingSize="l">
    <EuiFlexGroup @alignItems="center" @justifyContent="spaceBetween">
      <EuiFlexItem>
        <EuiText>
          <h2>New customer</h2>
          <p>Customer details and a delivery address, saved together.</p>
        </EuiText>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiBadge @color={{if form.isValid "success" "warning"}}>
          Parent: {{if form.isValid "Valid" "Incomplete"}}
        </EuiBadge>
      </EuiFlexItem>
    </EuiFlexGroup>
    <EuiSpacer @size="l" />

    <EuiText><h3>Customer details</h3></EuiText>
    <EuiSpacer @size="s" />
    <EuiFlexGroup>
      <EuiFlexItem>
        <form.FieldText
          @label="Full name"
          @value={{this.details.name}}
          @onChange={{fn this.update "name"}}
          @validations={{hash presence=(hash presence=true)}}
        />
      </EuiFlexItem>
      <EuiFlexItem>
        <form.FieldText
          @label="Email"
          @value={{this.details.email}}
          @onChange={{fn this.update "email"}}
          @validations={{hash
            presence=(hash presence=true)
            format=(hash type="email")
          }}
        />
      </EuiFlexItem>
    </EuiFlexGroup>
    <EuiSpacer @size="l" />

    {{#if this.showAddress}}
      <form.Form as |address|>
        <EuiPanel
          @color="subdued"
          @paddingSize="l"
          style="margin-left: clamp(12px, 3vw, 32px); border-left: 4px solid #6092c0;"
        >
          <EuiFlexGroup @alignItems="center" @justifyContent="spaceBetween">
            <EuiFlexItem>
              <EuiText>
                <h3>Delivery address</h3>
                <p>This nested form contributes its validity to the parent.</p>
              </EuiText>
            </EuiFlexItem>
            <EuiFlexItem @grow={{false}}>
              <EuiBadge @color={{if address.isValid "success" "warning"}}>
                Address: {{if address.isValid "Valid" "Incomplete"}}
              </EuiBadge>
            </EuiFlexItem>
          </EuiFlexGroup>
          <EuiSpacer @size="m" />
          <address.FieldText
            @label="Street address"
            @placeholder="123 Main Street"
            @value={{this.details.street}}
            @onChange={{fn this.update "street"}}
            @validations={{hash presence=(hash presence=true)}}
          />
          <EuiFlexGroup>
            <EuiFlexItem>
              <address.FieldText
                @label="City"
                @placeholder="Monterrey"
                @value={{this.details.city}}
                @onChange={{fn this.update "city"}}
                @validations={{hash presence=(hash presence=true)}}
              />
            </EuiFlexItem>
            <EuiFlexItem>
              <address.FieldText
                @label="Postal code"
                @placeholder="64000"
                @helpText="Enter five digits."
                @value={{this.details.postalCode}}
                @onChange={{fn this.update "postalCode"}}
                @validations={{hash
                  presence=(hash presence=true)
                  format=(hash regex=this.postalCodePattern)
                }}
              />
            </EuiFlexItem>
          </EuiFlexGroup>
          <EuiSpacer @size="s" />
          <EuiText @size="s">
            <p>Address fields: {{if address.isTouched "Touched" "Untouched"}}</p>
          </EuiText>
        </EuiPanel>
      </form.Form>
    {{else}}
      <EuiCallOut @title="No delivery address" @color="primary" @size="s">
        Only the customer fields contribute to the parent's validity.
      </EuiCallOut>
    {{/if}}

    <EuiSpacer @size="l" />
    <EuiFlexGroup @alignItems="center" @gutterSize="s">
      <EuiFlexItem @grow={{false}}>
        <EuiButton @type="submit" @fill={{true}}>Save customer</EuiButton>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiButton @type="button" {{on "click" this.fillExample}}>Fill example</EuiButton>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiButton @type="button" {{on "click" this.toggleAddress}}>
          {{if this.showAddress "Remove address" "Add address"}}
        </EuiButton>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiButton @type="button" {{on "click" this.clearAddress}}>Clear address</EuiButton>
      </EuiFlexItem>
    </EuiFlexGroup>
    <EuiSpacer @size="m" />
    <EuiText @size="s">
      <p>Overall form: {{if form.isValid "Ready to save" "Needs attention"}} · {{if form.isTouched "Touched" "Untouched"}}</p>
      <p role="status">{{this.message}}</p>
    </EuiText>
  </EuiPanel>
</ValidatedForm>
```

```js component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class extends Component {
  @tracked details = {
    name: 'Alex Rivera',
    email: 'alex@example.com',
    street: '',
    city: '',
    postalCode: ''
  };
  @tracked showAddress = true;
  @tracked message = '';

  postalCodePattern = /^[0-9]{5}$/;

  @action
  update(field, value) {
    this.details = { ...this.details, [field]: value };
    this.message = '';
  }

  @action
  fillExample() {
    this.details = {
      name: 'Alex Rivera',
      email: 'alex@example.com',
      street: '123 Main Street',
      city: 'Monterrey',
      postalCode: '64000'
    };
    this.message = '';
  }

  @action
  clearAddress() {
    this.details = { ...this.details, street: '', city: '', postalCode: '' };
    this.message = '';
  }

  @action
  toggleAddress() {
    this.showAddress = !this.showAddress;
    this.message = '';
  }

  @action
  save() {
    this.message = this.showAddress
      ? 'Customer and delivery address saved successfully.'
      : 'Customer saved without a delivery address.';
  }

  @action
  invalid() {
    this.message = 'Check the highlighted fields before saving.';
  }
}
```
