---
order: 6
---

# Checkable

<EuiText>

**EuiCheckableCard** wraps an **EuiRadio** or **EuiCheckbox** with a more-prominent panel, allowing for content to be displayed.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiCheckableCard } from '@ember-eui/core/components';
import { on } from '@ember/modifier';

export default class CardCheckableDemo extends Component {
  @tracked checkbox = false;

  @action toggleCheckbox() {
    this.checkbox = !this.checkbox;
  }

  <template>
    <EuiCheckableCard
      @label="I am a checkbox"
      @checkableType="checkbox"
      @checked={{this.checkbox}}
      value="checkbox1"
      {{on "change" this.toggleCheckbox}}
    />
  </template>
}
```

