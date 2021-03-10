# Demo

```hbs template
  <EuiPikaday @onSelection={{this.setDate}} @value={{this.date}} />

  The selected date is: {{this.date}}
```


```js component
import Component from "@glimmer/component";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";

export default class Hoool extends Component {
  @tracked date = new Date;

  @action
  setDate(date) {
    this.date = date;
  }
}

```
