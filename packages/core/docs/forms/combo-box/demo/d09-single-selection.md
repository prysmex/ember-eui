---
order: 9
---

# Single selection

<EuiText>

To only allow the user to select a single option, provide the `@singleSelection` argument. You may want to render the selected option as plain text instead of pill form. To do this, pass `@singleSelection={{hash asPlainText=true}}`. `@onChange` still receives an array, with either 0 or 1 options.

The switches above the combo box are docs-only helpers that toggle its display arguments.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiFlexGroup, EuiFlexItem, EuiSwitch, EuiSpacer, EuiComboBox } from '@ember-eui/core/components';
import { get, fn, hash } from '@ember/helper';

const MOONS = [
  { label: 'Titan' },
  { label: 'Enceladus' },
  { label: 'Mimas' },
  { label: 'Dione' },
  { label: 'Iapetus' },
  { label: 'Phoebe' },
  { label: 'Rhea' },
  {
    label:
      "Pandora is one of Saturn's moons, named for a Titaness of Greek mythology",
  },
  { label: 'Tethys' },
  { label: 'Hyperion' },
];

export default class ComboBoxSingleSelectionDemo extends Component {
  toggles = [
    { key: 'fullWidth', label: 'fullWidth' },
    { key: 'compressed', label: 'compressed' },
    { key: 'isInvalid', label: 'isInvalid' },
    { key: 'isDisabled', label: 'isDisabled' },
  ];

  @tracked flags = {};

  @action
  toggle(key, event) {
    this.flags = { ...this.flags, [key]: event.target.checked };
  }

  options = MOONS;

  @tracked selectedOptions = [MOONS[2]];

  @action
  onChange(selectedOptions) {
    // We should only get back either 0 or 1 options.
    this.selectedOptions = selectedOptions;
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
    <EuiComboBox
      @ariaLabel="Accessible screen reader label"
      @placeholder="Select a single option"
      @singleSelection={{hash asPlainText=true}}
      @options={{this.options}}
      @selectedOptions={{this.selectedOptions}}
      @searchField="label"
      @onChange={{this.onChange}}
      @fullWidth={{this.flags.fullWidth}}
      @compressed={{this.flags.compressed}}
      @isInvalid={{this.flags.isInvalid}}
      @isDisabled={{this.flags.isDisabled}}
      as |option|
    >
      {{option.label}}
    </EuiComboBox>
  </template>
}
```
