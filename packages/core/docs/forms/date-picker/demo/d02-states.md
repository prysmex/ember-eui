---
order: 2
---

# Date picker states

<EuiText>

Examples of how the input can appear within a form. This should match our other form styles. The switches are docs-only helpers that toggle the display arguments of the first two pickers. `<:prepend>` and `<:append>` take any content, here an `EuiFormLabel` and a button; each yields the class to put on it, and `<:prepend>` also the input's id.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { fn, get } from '@ember/helper';
import { on } from '@ember/modifier';
import {
  EuiButtonEmpty,
  EuiDatePicker,
  EuiFlexGroup,
  EuiFlexItem,
  EuiFormLabel,
  EuiFormRow,
  EuiSpacer,
  EuiSwitch,
} from '@ember-eui/core/components';

export default class DatePickerStatesDemo extends Component {
  toggles = [
    { key: 'fullWidth', label: 'fullWidth' },
    { key: 'compressed', label: 'compressed' },
    { key: 'isInvalid', label: 'isInvalid' },
    { key: 'isLoading', label: 'isLoading' },
    { key: 'readOnly', label: 'readOnly' },
    { key: 'disabled', label: 'disabled' },
  ];

  @tracked flags = {};
  @tracked startDate = null;

  @action
  toggle(key, event) {
    this.flags = { ...this.flags, [key]: event.target.checked };
  }

  handleChange = (date) => {
    this.startDate = date;
  };

  clear = () => {
    this.startDate = null;
  };

  errors = [
    "Here's an example of an error",
    'You might have more than one error, so pass an array.',
  ];

  <template>
    <EuiFlexGroup @wrap={{true}} @gutterSize="m">
      {{#each this.toggles as |toggle|}}
        <EuiFlexItem @grow={{false}}>
          <EuiSwitch
            @label={{toggle.label}}
            @compressed={{true}}
            @checked={{get this.flags toggle.key}}
            @onChange={{fn this.toggle toggle.key}}
          />
        </EuiFlexItem>
      {{/each}}
    </EuiFlexGroup>
    <EuiSpacer @size="m" />
    <EuiDatePicker
      aria-label="Date picker states"
      @value={{this.startDate}}
      @onChange={{this.handleChange}}
      @placeholder="Placeholder text"
      @fullWidth={{this.flags.fullWidth}}
      @compressed={{this.flags.compressed}}
      @isInvalid={{this.flags.isInvalid}}
      @isLoading={{this.flags.isLoading}}
      @readOnly={{this.flags.readOnly}}
      @disabled={{this.flags.disabled}}
    />

    <EuiSpacer @size="l" />

    <EuiDatePicker
      @value={{this.startDate}}
      @onChange={{this.handleChange}}
      @placeholder="Prepend and append"
      @fullWidth={{this.flags.fullWidth}}
      @compressed={{this.flags.compressed}}
      @isInvalid={{this.flags.isInvalid}}
      @isLoading={{this.flags.isLoading}}
      @readOnly={{this.flags.readOnly}}
      @disabled={{this.flags.disabled}}
    >
      <:prepend as |className inputId|>
        <EuiFormLabel class={{className}} for={{inputId}}>Due</EuiFormLabel>
      </:prepend>
      <:append as |className|>
        <EuiButtonEmpty
          class={{className}}
          @size="xs"
          @isDisabled={{this.flags.disabled}}
          {{on "click" this.clear}}
        >Clear</EuiButtonEmpty>
      </:append>
    </EuiDatePicker>

    <EuiSpacer @size="l" />

    <EuiDatePicker
      aria-label="Clearable"
      @value={{this.startDate}}
      @onChange={{this.handleChange}}
      @onClear={{this.clear}}
      @placeholder="Clearable"
    />

    <EuiSpacer @size="m" />

    <EuiFormRow
      @label="Form row validation"
      @id="d02-invalid"
      @isInvalid={{true}}
      @error={{this.errors}}
    >
      <EuiDatePicker
        @id="d02-invalid"
        @isInvalid={{true}}
        @value={{this.startDate}}
        @onChange={{this.handleChange}}
        @placeholder="Example of an error"
      />
    </EuiFormRow>
  </template>
}
```
