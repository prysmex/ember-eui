---
order: 6
---

# Option rendering

<EuiText>

There are two object properties you can add to enhance the content of your options, `option.prepend` and `option.append`. These will add nodes before and after the option label respectively, to both the dropdown option and selected pill. They will not be included in the searchable content as this only matches against the label property.

A node is text or a component; components receive the option as `@option`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { hash } from '@ember/helper';
import { EuiComboBox, EuiIcon, EuiSpacer, EuiSwitch } from '@ember-eui/core/components';

const BellIcon = <template><EuiIcon @size="s" @type="bell" /></template>;
const BoltIcon = <template><EuiIcon @size="s" @type="bolt" /></template>;
const BugIcon = <template><EuiIcon @size="s" @type="bug" /></template>;
const CommentIcon = <template><EuiIcon @size="s" @type="comment" /></template>;
const FlagIcon = <template><EuiIcon @size="s" @type="flag" @color="danger" /></template>;
const TagIcon = <template><EuiIcon @size="s" @type="tag" @color="success" /></template>;

const options = [
  { label: 'Titan', 'data-test-subj': 'titanOption', prepend: BellIcon },
  { label: 'Enceladus', prepend: BoltIcon },
  { label: 'Mimas', prepend: BugIcon },
  {
    label:
      "Pandora is one of Saturn's moons, named for a Titaness of Greek mythology",
    prepend: CommentIcon,
    append: '(10)',
  },
  { label: 'Iapetus', prepend: FlagIcon, append: '(2)' },
  { label: 'Phoebe', prepend: TagIcon, append: '(5)' },
];

export default class ComboBoxOptionRenderingDemo extends Component {
  options = options;

  @tracked selectedOptions = [options[0], options[5]];
  @tracked singleSelection = false;

  get singleSelectedOption() {
    return this.selectedOptions.length ? [this.selectedOptions[0]] : [];
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
      @checked={{this.singleSelection}}
      @onChange={{this.toggleSingleSelection}}
      @label="Single selection"
    />
    <EuiSpacer />
    <EuiComboBox
      @ariaLabel="Combo box demo with option prepend/append nodes"
      @options={{this.options}}
      @onChange={{this.onChange}}
      @removeTag={{this.removeTag}}
      @searchField="label"
      @singleSelection={{if this.singleSelection (hash asPlainText=true) false}}
      @selectedOptions={{if this.singleSelection this.singleSelectedOption this.selectedOptions}}
      @placeholder={{if this.singleSelection "Select one option" "Select one or more options"}}
    />
  </template>
}
```
