---
order: 3
---

# States

<EuiText>

You can pass the same arguments as you normally would to `EuiSelect`, like `@disabled`, `@isLoading`, `@compressed`, etc. The switches above the example are docs-only helpers that toggle them.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiFlexGroup, EuiFlexItem, EuiSwitch, EuiSpacer, EuiSuperSelect } from '@ember-eui/core/components';
import { get, fn } from '@ember/helper';

export default class SuperSelectStatesDemo extends Component {
  toggles = [
    { key: 'fullWidth', label: 'fullWidth' },
    { key: 'compressed', label: 'compressed' },
    { key: 'isInvalid', label: 'isInvalid' },
    { key: 'isLoading', label: 'isLoading' },
    { key: 'readOnly', label: 'readOnly' },
    { key: 'disabled', label: 'disabled' },
  ];

  options = [
    { value: 'option_one', inputDisplay: 'Option one', disabled: true },
    { value: 'option_two', inputDisplay: 'Option two' },
    {
      value: 'option_three',
      inputDisplay: 'Option three has a super long text and added truncation',
      truncate: true,
    },
  ];

  @tracked flags = {};
  @tracked value = 'option_two';

  @action
  toggle(key, event) {
    this.flags = { ...this.flags, [key]: event.target.checked };
  }

  @action
  onChange(value) {
    this.value = value;
  }

  <template>
    <EuiFlexGroup @wrap={{true}} @gutterSize="m" @responsive={{false}}>
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
    <EuiSuperSelect
      @options={{this.options}}
      @valueOfSelected={{this.value}}
      @fullWidth={{this.flags.fullWidth}}
      @compressed={{this.flags.compressed}}
      @isInvalid={{this.flags.isInvalid}}
      @isLoading={{this.flags.isLoading}}
      @readOnly={{this.flags.readOnly}}
      @disabled={{this.flags.disabled}}
      @onChange={{this.onChange}}
    >
      <:inputDisplay as |option|>
        {{#if option.truncate}}
          <span class="eui-textTruncate eui-displayBlock">{{option.inputDisplay}}</span>
        {{else}}
          {{option.inputDisplay}}
        {{/if}}
      </:inputDisplay>
      <:dropdownDisplay as |option|>
        {{#if option.truncate}}
          <span class="eui-textTruncate eui-displayBlock">{{option.inputDisplay}}</span>
        {{else}}
          {{option.inputDisplay}}
        {{/if}}
      </:dropdownDisplay>
    </EuiSuperSelect>
  </template>
}
```
