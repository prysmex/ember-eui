---
order: 3
---

# Global full-width

<EuiText>

To set all the rows and controls in a form to `@fullWidth`, specify the argument on the root `EuiForm` component.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import {
  EuiButton,
  EuiDescribedFormGroup,
  EuiFieldSearch,
  EuiFilePicker,
  EuiFlexGroup,
  EuiFlexItem,
  EuiForm,
  EuiFormRow,
  EuiRange,
  EuiSelect,
  EuiSpacer,
  EuiTextArea,
} from '@ember-eui/core/components';

export default class GlobalFullWidthDemo extends Component {
  selectOptions = [
    {
      value: 'option_one',
      text: 'Option one is very long in order to try justifying the use of fullWidth on a select box',
    },
    { value: 'option_two', text: 'Option two' },
    { value: 'option_three', text: 'Option three' },
  ];

  @tracked range = 42;

  onSearch = () => {};

  @action
  onSubmit(event) {
    event.preventDefault();
  }

  @action
  setRange(event) {
    this.range = Number.parseInt(event.target.value, 10);
  }

  <template>
    <EuiForm @fullWidth={{true}} @tagName="form" {{on "submit" this.onSubmit}}>
      <EuiFlexGroup>
        <EuiFlexItem>
          <EuiFieldSearch
            placeholder="Search..."
            @onSearch={{this.onSearch}}
            aria-label="An example of search with fullWidth"
          />
        </EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          <EuiButton>Search</EuiButton>
        </EuiFlexItem>
      </EuiFlexGroup>

      <EuiSpacer @size="l" />

      <EuiFormRow
        @label="Works on form rows too"
        @helpText="Note that the fullWidth argument is not passed to any of these elements, it's read from the parent EuiForm component."
      >
        <EuiRange
          @min={{0}}
          @max={{100}}
          @value={{this.range}}
          @onChange={{this.setRange}}
          name="range"
        />
      </EuiFormRow>

      <EuiSpacer />

      <EuiDescribedFormGroup>
        <:title>Works with all form controls and layout components</:title>
        <:description>
          <p>Any component that supports the <code>fullWidth</code> argument that is.</p>
          <p>
            Make sure it is appropriate at all of the widths that the container
            can take. There are many situations where a full-width form is
            inappropriate.
          </p>
        </:description>
        <:default>
          <EuiFormRow @label="Text area">
            <EuiTextArea placeholder="" />
          </EuiFormRow>
        </:default>
      </EuiDescribedFormGroup>

      <EuiFormRow @label="Works on EuiSelect">
        <EuiSelect @options={{this.selectOptions}} />
      </EuiFormRow>

      <EuiFormRow @label="It can be disabled for a specific control">
        <EuiFilePicker @display="default" @fullWidth={{false}} />
      </EuiFormRow>
    </EuiForm>
  </template>
}
```
