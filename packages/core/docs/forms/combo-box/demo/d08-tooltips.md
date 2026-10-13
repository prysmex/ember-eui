---
order: 8
---

# Tooltips

<EuiText>

You can add tooltips to the options by passing `toolTipContent`. Use `toolTipProps` to pass additional `EuiToolTip` arguments to the tooltip.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiComboBox } from '@ember-eui/core/components';

const options = [
  {
    label: 'Titan',
    toolTipContent:
      'Titan is the largest moon of Saturn and the second-largest in the Solar System',
  },
  {
    label: 'Pandora',
    toolTipContent:
      "Pandora is one of Saturn's moons, named for a Titaness of Greek mythology",
  },
  {
    label: 'Iapetus',
    toolTipContent: "Iapetus is the outermost of Saturn's large moons",
    toolTipProps: { position: 'bottom' },
  },
];

export default class ComboBoxToolTipsDemo extends Component {
  options = options;

  @tracked selectedOptions = [options[2]];

  @action
  onChange(selectedOptions) {
    this.selectedOptions = selectedOptions;
  }

  @action
  removeTag(option) {
    this.selectedOptions = this.selectedOptions.filter((o) => o !== option);
  }

  <template>
    <EuiComboBox
      @ariaLabel="Example of combobox options with tooltips"
      @options={{this.options}}
      @selectedOptions={{this.selectedOptions}}
      @searchField="label"
      @onChange={{this.onChange}}
      @removeTag={{this.removeTag}}
      @isClearable={{true}}
    />
  </template>
}
```
