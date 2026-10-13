---
order: 8
---

# Groups

<EuiText>

You can group options together by passing `{ groupName, options }` objects. The group names _won't_ match against the search value.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiComboBox } from '@ember-eui/core/components';

const COLOR_GROUP = {
  groupName: 'Colors',
  options: [
    { label: 'Red' },
    { label: 'Blue' },
    { label: 'Yellow' },
    { label: 'Green' },
  ],
};

const SOUND_GROUP = {
  groupName: 'Sounds',
  options: [
    { label: 'Pop' },
    { label: 'Hiss' },
    { label: 'Screech' },
    { label: 'Ding' },
  ],
};

export default class ComboBoxGroupsDemo extends Component {
  @tracked allOptions = [COLOR_GROUP, SOUND_GROUP];
  @tracked selectedOptions = [COLOR_GROUP.options[2], SOUND_GROUP.options[3]];

  @action
  onCreateOption(searchValue) {
    const newOption = { label: searchValue };
    const [colors, sounds, custom = { groupName: 'Custom', options: [] }] =
      this.allOptions;

    this.allOptions = [
      colors,
      sounds,
      { ...custom, options: [...custom.options, newOption] },
    ];

    // Select the option.
    this.selectedOptions = [...this.selectedOptions, newOption];
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
    <EuiComboBox
      @ariaLabel="EuiComboBox example with groups"
      @placeholder="These options are grouped"
      @options={{this.allOptions}}
      @selectedOptions={{this.selectedOptions}}
      @searchField="label"
      @onChange={{this.onChange}}
      @removeTag={{this.removeTag}}
      @onCreateOption={{this.onCreateOption}}
      as |option|
    >
      {{option.label}}
    </EuiComboBox>
  </template>
}
```
