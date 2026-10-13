---
order: 5
---

# Pill colors

<EuiText>

Useful for visualization or tagging systems. You can also pass a `color` in your option list. The color can be a hex value (like `#000`) or any other named color value accepted by the `EuiBadge` component.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

import { euiPaletteColorBlindBehindText } from '@ember-eui/core/utils/color/eui_palettes';
import { EuiFlexGroup, EuiFlexItem, EuiSwitch, EuiSpacer, EuiComboBox } from '@ember-eui/core/components';
import { get, fn } from '@ember/helper';

const colors = euiPaletteColorBlindBehindText();

const MOONS = [
  { label: 'Titan', color: colors[0] },
  { label: 'Enceladus', color: colors[1] },
  { label: 'Mimas', color: colors[2] },
  { label: 'Dione', color: colors[3] },
  { label: 'Iapetus', color: colors[4] },
  { label: 'Phoebe', color: colors[5] },
  { label: 'Rhea', color: colors[6] },
  { label: "Pandora is one of Saturn's moons, named for a Titaness of Greek mythology", color: colors[7] },
  { label: 'Tethys', color: colors[8] },
  { label: 'Hyperion', color: colors[9] },
];

export default class ComboBoxPillColorsDemo extends Component {
  toggles = [
    { key: 'fullWidth', label: 'fullWidth' },
    { key: 'compressed', label: 'compressed' },
    { key: 'isInvalid', label: 'isInvalid' },
    { key: 'isLoading', label: 'isLoading' },
    { key: 'isDisabled', label: 'isDisabled' },
  ];

  @tracked flags = {};

  @action
  toggle(key, event) {
    this.flags = { ...this.flags, [key]: event.target.checked };
  }

  @tracked options = MOONS;
  @tracked selectedOptions = [MOONS[2], MOONS[5]];

  @action
  onChange(selectedOptions) {
    this.selectedOptions = selectedOptions;
  }

  @action
  removeTag(option) {
    this.selectedOptions = this.selectedOptions.filter((o) => o !== option);
  }

  @action
  onCreateOption(searchValue) {
    const normalizedSearchValue = searchValue.trim().toLowerCase();

    if (!normalizedSearchValue) {
      return;
    }

    const newOption = { label: searchValue };

    // Create the option if it doesn't exist.
    if (
      !this.options.some(
        (option) => option.label.trim().toLowerCase() === normalizedSearchValue
      )
    ) {
      this.options = [...this.options, newOption];
    }

    // Select the option.
    this.selectedOptions = [...this.selectedOptions, newOption];
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
      @options={{this.options}}
      @selectedOptions={{this.selectedOptions}}
      @searchField="label"
      @onChange={{this.onChange}}
      @removeTag={{this.removeTag}}
      @placeholder="Select or create options"
      @onCreateOption={{this.onCreateOption}}
      @fullWidth={{this.flags.fullWidth}}
      @compressed={{this.flags.compressed}}
      @isInvalid={{this.flags.isInvalid}}
      @isLoading={{this.flags.isLoading}}
      @isDisabled={{this.flags.isDisabled}}
      as |option|
    >
      {{option.label}}
    </EuiComboBox>
  </template>
}
```
