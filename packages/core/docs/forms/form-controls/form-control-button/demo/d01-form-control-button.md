---
order: 1
---

# Form control buttons

<EuiText>

Form control buttons provide semantic button elements that look like form inputs. They are designed for scenarios where you need interactive buttons within form layouts while maintaining form control styling consistently.

### EuiFormControlButton

`EuiFormControlButton` renders a button that looks like a form input field. It can be used to trigger actions (e.g. opening popovers) from within an `EuiFormControlLayout` to ensure expected visual output and consistency with input controls.

**`EuiFormControlButton` is meant to only be used inside `EuiFormControlLayout`.**

The component provides a mix of base `EuiButtonEmpty` arguments and input specific arguments, e.g. use `@value` and `@placeholder` to provide content similar to an input element. You can customize the content by passing additional content in the default block.

**Dropdown styling.** Set `@isDropdown` on `EuiFormControlLayout` to indicate a dropdown toggle that accounts for other form layout icons.

The switches above the examples are docs-only helpers.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { fn, get } from '@ember/helper';
import {
  EuiBadge,
  EuiFieldSearch,
  EuiFlexGroup,
  EuiForm,
  EuiFormControlButton,
  EuiFormControlLayout,
  EuiFormRow,
  EuiInputPopover,
  EuiNotificationBadge,
  EuiSelectable,
  EuiSpacer,
  EuiSwitch,
} from '@ember-eui/core/components';

const OPTIONS = [
  { label: 'Titan' },
  { label: 'Enceladus' },
  { label: 'Mimas' },
  { label: 'Dione' },
  { label: 'Iapetus' },
  { label: 'Phoebe' },
  { label: 'Rhea' },
];

export default class FormControlButtonDemo extends Component {
  toggles = [
    { key: 'compressed', label: 'compressed' },
    { key: 'isDisabled', label: 'isDisabled' },
    { key: 'isInvalid', label: 'isInvalid' },
    { key: 'isDropdown', label: 'isDropdown' },
    { key: 'clear', label: 'clear' },
  ];

  noop = () => {};

  @tracked flags = {};
  @tracked isPopoverOpen = false;
  @tracked searchValue = '';
  @tracked options = OPTIONS;
  @tracked selectedOptions = [];
  @tracked buttonLabel = '';

  get clear() {
    return this.flags.clear ? this.noop : undefined;
  }

  get clearAndReset() {
    return this.flags.clear ? this.handleOnClear : undefined;
  }

  get badgeColor() {
    return this.selectedOptions.length > 0 && !this.flags.isDisabled
      ? 'success'
      : 'subdued';
  }

  get badgeCount() {
    return this.selectedOptions.length > 0
      ? this.selectedOptions.length
      : this.options.length;
  }

  @action
  toggle(key, event) {
    this.flags = { ...this.flags, [key]: event.target.checked };
  }

  @action
  togglePopover() {
    this.isPopoverOpen = !this.isPopoverOpen;
  }

  @action
  closePopover() {
    this.isPopoverOpen = false;
  }

  @action
  handleOnSearch(event) {
    this.searchValue = event.target.value;
    const search = this.searchValue.toLowerCase();

    this.options = OPTIONS.filter((opt) => opt.label.toLowerCase().includes(search));
  }

  @action
  handleOnChange(options) {
    this.options = options;
    this.selectedOptions = options.filter((option) => option.checked === 'on');
    this.buttonLabel = this.selectedOptions.map((opt) => opt.label).join(', ');
  }

  @action
  handleOnClear() {
    this.options = OPTIONS;
    this.selectedOptions = [];
    this.buttonLabel = '';
  }

  <template>
    <EuiFlexGroup @responsive={{false}} @wrap={{true}}>
      {{#each this.toggles as |toggle|}}
        <EuiSwitch
          @label={{toggle.label}}
          @checked={{get this.flags toggle.key}}
          @onChange={{fn this.toggle toggle.key}}
        />
      {{/each}}
    </EuiFlexGroup>
    <EuiSpacer />
    <EuiForm>
      <EuiFormRow @label="Example: placeholder only">
        <EuiFormControlLayout
          @compressed={{this.flags.compressed}}
          @isDisabled={{this.flags.isDisabled}}
          @isInvalid={{this.flags.isInvalid}}
          @isDropdown={{this.flags.isDropdown}}
          @clear={{this.clear}}
        >
          <EuiFormControlButton
            @placeholder="Placeholder text"
            @compressed={{this.flags.compressed}}
            @isDisabled={{this.flags.isDisabled}}
            @isInvalid={{this.flags.isInvalid}}
          />
        </EuiFormControlLayout>
      </EuiFormRow>

      <EuiFormRow @label="Example: value only">
        <EuiFormControlLayout
          @compressed={{this.flags.compressed}}
          @isDisabled={{this.flags.isDisabled}}
          @isInvalid={{this.flags.isInvalid}}
          @isDropdown={{this.flags.isDropdown}}
          @clear={{this.clear}}
        >
          <EuiFormControlButton
            @value="Button value"
            @compressed={{this.flags.compressed}}
            @isDisabled={{this.flags.isDisabled}}
            @isInvalid={{this.flags.isInvalid}}
          />
        </EuiFormControlLayout>
      </EuiFormRow>

      <EuiFormRow @label="Example: value with icon and additional content">
        <EuiFormControlLayout
          @compressed={{this.flags.compressed}}
          @isDisabled={{this.flags.isDisabled}}
          @isInvalid={{this.flags.isInvalid}}
          @isDropdown={{this.flags.isDropdown}}
          @clear={{this.clear}}
        >
          <EuiFormControlButton
            @value="Button value"
            @iconType="gear"
            @compressed={{this.flags.compressed}}
            @isDisabled={{this.flags.isDisabled}}
            @isInvalid={{this.flags.isInvalid}}
          >
            <EuiBadge>Active</EuiBadge>
          </EuiFormControlButton>
        </EuiFormControlLayout>
      </EuiFormRow>

      <EuiFormRow @label="Example: Popover with filter selection">
        <EuiFormControlLayout
          @compressed={{this.flags.compressed}}
          @isDisabled={{this.flags.isDisabled}}
          @isInvalid={{this.flags.isInvalid}}
          @isDropdown={{this.flags.isDropdown}}
          @clear={{this.clearAndReset}}
        >
          <EuiInputPopover
            @ownFocus={{true}}
            @hasArrow={{false}}
            @isOpen={{this.isPopoverOpen}}
            @panelPaddingSize="none"
            @panelMinWidth={{200}}
            @closePopover={{this.closePopover}}
          >
            <:input>
              <EuiFormControlButton
                role="combobox"
                aria-expanded={{if this.isPopoverOpen "true" "false"}}
                @value={{this.buttonLabel}}
                @placeholder="Placeholder"
                @compressed={{this.flags.compressed}}
                @isDisabled={{this.flags.isDisabled}}
                @isInvalid={{this.flags.isInvalid}}
                {{on "click" this.togglePopover}}
              >
                <EuiNotificationBadge @color={{this.badgeColor}}>
                  {{this.badgeCount}}
                </EuiNotificationBadge>
              </EuiFormControlButton>
            </:input>
            <:content>
              <EuiFieldSearch
                placeholder="search field"
                @fullWidth={{true}}
                @value={{this.searchValue}}
                @onSearch={{this.noop}}
                {{on "input" this.handleOnSearch}}
              />
              <EuiSelectable
                @options={{this.options}}
                @onChange={{this.handleOnChange}}
              />
            </:content>
          </EuiInputPopover>
        </EuiFormControlLayout>
      </EuiFormRow>
    </EuiForm>
  </template>
}
```
