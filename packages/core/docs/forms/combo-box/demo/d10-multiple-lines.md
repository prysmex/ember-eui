---
order: 10
---

# Multiple lines

<EuiText>

Only in the rare case you need text to wrap onto multiple lines instead of being truncated, you can set the `@rowHeight` argument to `"auto"`. This will disable virtualization for the options list. When virtualization is disabled, highlighting will function as expected, but text truncation properties will be ignored.

**Warning:** disabling virtualization has an impact on **performance** with large lists due to all list elements being rendered to the DOM.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiComboBox } from '@ember-eui/core/components';

const options = [
  { label: 'Nam vestibulum, arcu quis gravida tempus, nunc nibh rhoncus tellus' },
  { label: 'Aliquam placerat augue at dolor interdum, et sodales dui consectetur' },
  { label: 'Aenean in scelerisque ligula, nec scelerisque metus' },
  { label: 'Donec iaculis varius massa, ac scelerisque velit facilisis nec' },
  { label: 'Nulla varius urna lorem, et suscipit nisi scelerisque sed' },
  { label: 'Phasellus scelerisque laoreet neque, non malesuada neque maximus sed' },
  { label: 'Maecenas felis eros, mattis eget augue in, euismod tristique arcu' },
  { label: 'Aliquam ac tristique tortor, commodo rhoncus turpis' },
];

export default class ComboBoxMultipleLinesDemo extends Component {
  options = options;

  @tracked selectedOptions = [];

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
      @ariaLabel="Accessible screen reader label"
      @placeholder="Long text options onto multiple lines"
      @rowHeight="auto"
      @options={{this.options}}
      @selectedOptions={{this.selectedOptions}}
      @searchField="label"
      @onChange={{this.onChange}}
      @removeTag={{this.removeTag}}
    />
  </template>
}
```
