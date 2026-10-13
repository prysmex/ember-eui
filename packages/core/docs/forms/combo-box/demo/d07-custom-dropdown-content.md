---
order: 7
---

# Custom dropdown content

<EuiText>

While it is best to stick to the `option.label`, `option.append`, and `option.prepend` keys, you can render anything in the default block, which is called with the single `option` and the `searchValue` to use for highlighting (`as |option index searchValue|`). The block also renders the selected pills, where `searchValue` is empty.

You can use the `value` key of the `option` object to store metadata about the option for use in the block.

**Note:** virtualization requires that each option have the same height. Ensure that you render the options so that wrapping text is truncated instead of causing the height of the option to change.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

import {
  euiPaletteColorBlind,
  euiPaletteColorBlindBehindText,
} from '@ember-eui/core/utils/color/eui_palettes';
import { EuiComboBox, EuiHealth, EuiHighlight } from '@ember-eui/core/components';

const colors = euiPaletteColorBlindBehindText();
const visColors = euiPaletteColorBlind();

const MOONS = [
  { label: 'Titan', value: { size: 5 }, color: colors[0], dotColor: visColors[0] },
  { label: 'Enceladus', value: { size: 2 }, color: colors[1], dotColor: visColors[1] },
  { label: 'Mimas', value: { size: 15 }, color: colors[2], dotColor: visColors[2] },
  { label: 'Dione', value: { size: 1 }, color: colors[3], dotColor: visColors[3] },
  { label: 'Iapetus', value: { size: 8 }, color: colors[4], dotColor: visColors[4] },
  { label: 'Phoebe', value: { size: 2 }, color: colors[5], dotColor: visColors[5] },
  { label: 'Rhea', value: { size: 33 }, color: colors[6], dotColor: visColors[6] },
  { label: "Pandora is one of Saturn's moons, named for a Titaness of Greek mythology", value: { size: 18 }, color: colors[7], dotColor: visColors[7] },
  { label: 'Tethys', value: { size: 9 }, color: colors[8], dotColor: visColors[8] },
  { label: 'Hyperion', value: { size: 4 }, color: colors[9], dotColor: visColors[9] },
];

export default class ComboBoxCustomContentDemo extends Component {
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
  onCreateOption(searchValue, flattenedOptions = []) {
    if (!searchValue) {
      return;
    }

    const normalizedSearchValue = searchValue.trim().toLowerCase();

    if (!normalizedSearchValue) {
      return;
    }

    const newOption = { value: searchValue, label: searchValue };

    // Create the option if it doesn't exist.
    if (
      flattenedOptions.findIndex(
        (option) => option.label.trim().toLowerCase() === normalizedSearchValue
      ) === -1
    ) {
      this.options = [...this.options, newOption];
    }

    // Select the option.
    this.selectedOptions = [...this.selectedOptions, newOption];
  }

  <template>
    <EuiComboBox
      @ariaLabel="Accessible screen reader label"
      @placeholder="Select or create options"
      @options={{this.options}}
      @selectedOptions={{this.selectedOptions}}
      @searchField="label"
      @onChange={{this.onChange}}
      @removeTag={{this.removeTag}}
      @onCreateOption={{this.onCreateOption}}
      as |option index searchValue|
    >
      <EuiHealth @color={{option.dotColor}}>
        <span class="eui-textTruncate">
          <EuiHighlight @text={{option.label}} @search={{searchValue}} />
          {{#if option.value.size}}&nbsp;<span>({{option.value.size}})</span>{{/if}}
        </span>
      </EuiHealth>
    </EuiComboBox>
  </template>
}
```
