---
order: 1
---

# Date picker

<EuiText>

Pick a date; the selected `Date` is shown below.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import '@ember-eui/pikaday/pikaday.css';
import { EuiCode, EuiText } from '@ember-eui/core/components';
import EuiPikaday from '@ember-eui/pikaday/components/eui-pikaday';

export default class extends Component {
  @tracked date = new Date();

  @action
  setDate(date) {
    this.date = date;
  }

  <template>
    <EuiPikaday @onSelection={{this.setDate}} @value={{this.date}} />
    <EuiText>
      <p>The selected date is:
        <EuiCode>{{this.date}}</EuiCode></p>
    </EuiText>
  </template>
}
```
