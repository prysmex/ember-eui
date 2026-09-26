---
order: 1
---

# Number field

<EuiText>

`@min`, `@max` and `@step` constrain the value. Convert the event's value
to a number yourself; an empty field gives `''`.

</EuiText>

```hbs template
<EuiFormRow @label="Seats" @helpText="Between 1 and 20.">
  <EuiFieldNumber
    @value={{this.seats}}
    @min={{1}}
    @max={{20}}
    {{on "input" this.updateSeats}}
  />
</EuiFormRow>
<EuiText @size="s" @color="subdued">
  <p>Total: {{this.total}} €</p>
</EuiText>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class NumberFieldDemo extends Component {
  @tracked seats = 3;

  get total() {
    return (Number(this.seats) || 0) * 12;
  }

  @action
  updateSeats(event) {
    this.seats = event.target.value;
  }
}
```
