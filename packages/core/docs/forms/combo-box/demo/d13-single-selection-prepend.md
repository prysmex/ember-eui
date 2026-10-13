---
order: 13
---

# Single selection with prepended label

<EuiText>

`@append` and `@prepend` only work if `@singleSelection` is not set to `false`, to avoid multi-lines that make the combo box taller than the `@append` and `@prepend`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { hash } from '@ember/helper';
import { EuiComboBox } from '@ember-eui/core/components';

const options = [
  { label: 'Titan', 'data-test-subj': 'titanOption' },
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

export default class ComboBoxSinglePrependDemo extends Component {
  options = options;

  @tracked selectedOptions = [options[2]];

  @action
  onChange(selectedOptions) {
    // We should only get back either 0 or 1 options.
    this.selectedOptions = selectedOptions;
  }

  <template>
    <EuiComboBox
      @prepend="Prepend"
      @singleSelection={{hash asPlainText=true}}
      @options={{this.options}}
      @selectedOptions={{this.selectedOptions}}
      @searchField="label"
      @onChange={{this.onChange}}
    />
  </template>
}
```
