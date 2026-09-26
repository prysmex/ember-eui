---
order: 1
---

# Date picker

<EuiText>

Pick a date; the selected `Date` is shown below.

</EuiText>

```hbs template
<EuiPikaday @onSelection={{this.setDate}} @value={{this.date}} />
<EuiText>
  <p>The selected date is:
    <EuiCode>{{this.date}}</EuiCode></p>
</EuiText>
```

```js component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import '@ember-eui/pikaday/pikaday.css';

export default class extends Component {
  @tracked date = new Date();

  @action
  setDate(date) {
    this.date = date;
  }
}
```
