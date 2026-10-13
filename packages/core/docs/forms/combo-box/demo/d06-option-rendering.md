---
order: 6
---

# Option rendering

<EuiText>

You can enhance the content of your options by rendering extra nodes, such as an icon before and a count after the label, in the default block. The block is used for both the dropdown option and the selected pill. Extra nodes are not included in the searchable content, as this only matches against the `@searchField` (`label`).

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiSwitch, EuiSpacer, EuiComboBox, EuiIcon } from '@ember-eui/core/components';
import { hash } from '@ember/helper';

const MOONS = [
  { label: 'Titan', icon: 'bell' },
  { label: 'Enceladus', icon: 'bolt' },
  { label: 'Mimas', icon: 'bug' },
  {
    label:
      "Pandora is one of Saturn's moons, named for a Titaness of Greek mythology",
    icon: 'comment',
    append: '(10)',
  },
  { label: 'Iapetus', icon: 'flag', iconColor: 'danger', append: '(2)' },
  { label: 'Phoebe', icon: 'tag', iconColor: 'success', append: '(5)' },
];

export default class ComboBoxOptionRenderingDemo extends Component {
  options = MOONS;

  @tracked selectedOptions = [MOONS[0], MOONS[5]];
  @tracked singleSelection = false;

  get visibleSelectedOptions() {
    return this.singleSelection
      ? this.selectedOptions.slice(0, 1)
      : this.selectedOptions;
  }

  @action
  toggleSingleSelection() {
    this.singleSelection = !this.singleSelection;
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
    <EuiSwitch
      @label="Single selection"
      @checked={{this.singleSelection}}
      @onChange={{this.toggleSingleSelection}}
    />
    <EuiSpacer />
    <EuiComboBox
      @ariaLabel="Combo box demo with option prepend/append nodes"
      @options={{this.options}}
      @selectedOptions={{this.visibleSelectedOptions}}
      @searchField="label"
      @singleSelection={{if this.singleSelection (hash asPlainText=true) false}}
      @placeholder={{if this.singleSelection "Select one option" "Select one or more options"}}
      @onChange={{this.onChange}}
      @removeTag={{this.removeTag}}
      as |option|
    >
      {{#if option.icon}}
        <EuiIcon @type={{option.icon}} @size="s" @color={{option.iconColor}} />
      {{/if}}
      {{option.label}}
      {{#if option.append}}{{option.append}}{{/if}}
    </EuiComboBox>
  </template>
}
```
