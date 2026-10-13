---
order: 4
---

# Column display

<EuiText>

There might be cases where displaying multiple `EuiExpression`s in a paragraph is not ideal. For example, when both the `@description` and the `@value` are variable or when their text is quite long. To use a column display instead, pass `@display="columns"`.

In column display, each expression is its own line and the `@description` column is aligned to the right. The default width for the description is 20%, but you can customize this with the `@descriptionWidth` argument. When displaying a group of `EuiExpression`s, make sure to set the same width for all descriptions.

Pass markup as the value with the `<:value>` block.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import {
  EuiComboBox,
  EuiExpression,
  EuiPopover,
  EuiPopoverTitle,
  EuiSelect,
  EuiSpacer,
  EuiTitle,
} from '@ember-eui/core/components';

const noop = () => {};

const OPTIONS = [
  { label: '.kibana_task_manager' },
  { label: 'kibana_sample_data_ecommerce' },
  { label: '.kibana-event-log-8.0.0-000001' },
  { label: 'kibana_sample_data_flights' },
  { label: '.kibana-event-log-8.0.0' },
];

export default class ExpressionColumnsDemo extends Component {
  options = OPTIONS;
  whenOptions = [
    { value: 'count()', text: 'count()' },
    { value: 'sum()', text: 'sum()' },
    { value: 'min()', text: 'min()' },
    { value: 'max()', text: 'max()' },
  ];

  @tracked isOpen1 = false;
  @tracked isOpen2 = false;
  @tracked whenValue = 'count()';
  @tracked selectedOptions = [OPTIONS[0], OPTIONS[1]];

  get isInvalid() {
    return this.selectedOptions.length === 0;
  }

  separator = (index) => (index < this.selectedOptions.length - 1 ? ',' : '');

  @action
  toggle1() {
    this.isOpen1 = !this.isOpen1;
  }

  @action
  close1() {
    this.isOpen1 = false;
  }

  @action
  toggle2() {
    this.isOpen2 = !this.isOpen2;
  }

  @action
  close2() {
    this.isOpen2 = false;
  }

  @action
  changeWhen(event) {
    this.whenValue = event.target.value;
    this.isOpen2 = false;
  }

  @action
  onChange(selectedOptions) {
    this.selectedOptions = selectedOptions;
  }

  @action
  removeTag(option) {
    this.selectedOptions = this.selectedOptions.filter((o) => o !== option);
  }

  <template>
    <div style="max-width: 500px">
      <EuiPopover
        @isOpen={{this.isOpen1}}
        @closePopover={{this.close1}}
        @display="block"
        @panelPaddingSize="s"
        @anchorPosition="downLeft"
      >
        <:button>
          <EuiExpression
            @description="indices"
            @display="columns"
            @isInvalid={{this.isInvalid}}
            @isActive={{this.isOpen1}}
            @onClick={{this.toggle1}}
          >
            <:value>
              {{#each this.selectedOptions as |option index|}}
                <p>{{option.label}}{{this.separator index}}</p>
              {{/each}}
            </:value>
          </EuiExpression>
        </:button>
        <:content>
          <div style="width: 300px">
            <EuiPopoverTitle>INDICES</EuiPopoverTitle>
            <EuiComboBox
              @placeholder="Select one or more indices"
              @options={{this.options}}
              @selectedOptions={{this.selectedOptions}}
              @searchField="label"
              @onChange={{this.onChange}}
              @removeTag={{this.removeTag}}
              @isClearable={{true}}
              as |option|
            >
              {{option.label}}
            </EuiComboBox>
          </div>
        </:content>
      </EuiPopover>
      <EuiPopover
        @isOpen={{this.isOpen2}}
        @closePopover={{this.close2}}
        @display="block"
        @panelPaddingSize="s"
        @anchorPosition="downLeft"
      >
        <:button>
          <EuiExpression
            @description="when"
            @display="columns"
            @value={{this.whenValue}}
            @isActive={{this.isOpen2}}
            @onClick={{this.toggle2}}
          />
        </:button>
        <:content>
          <div style="width: 150px">
            <EuiPopoverTitle>WHEN</EuiPopoverTitle>
            <EuiSelect
              @compressed={{true}}
              @value={{this.whenValue}}
              @options={{this.whenOptions}}
              {{on "change" this.changeWhen}}
            />
          </div>
        </:content>
      </EuiPopover>
      <EuiExpression
        @display="columns"
        @description="Except"
        @value="kibana_sample_data_ky_counties"
      />
      <EuiSpacer />
      <EuiTitle @size="xxs">
        <h3>Description width at 50px</h3>
      </EuiTitle>
      <EuiExpression
        @description="join"
        @display="columns"
        @descriptionWidth={{50}}
        @value="kibana_sample_data_ky_avl"
        @onClick={{noop}}
      />
    </div>
  </template>
}
```
