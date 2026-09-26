---
order: 1
---

# Select

<EuiText>

Options are `{ value, text }`. Update `@value` from `event.target.value`
(always a string) on `change`. `@hasNoInitialSelection` starts with no
option selected.

</EuiText>

```hbs template
<EuiFormRow @label="Time zone">
  <EuiSelect
    @options={{this.zones}}
    @value={{this.zone}}
    @hasNoInitialSelection={{true}}
    {{on "change" this.chooseZone}}
  />
</EuiFormRow>
<EuiText @size="s" @color="subdued"><p>Selected: {{if this.zone this.zone "none"}}</p></EuiText>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class SelectDemo extends Component {
  zones = [
    { value: 'UTC', text: 'UTC' },
    { value: 'Europe/Madrid', text: 'Madrid (UTC+1)' },
    { value: 'America/Mexico_City', text: 'Mexico City (UTC−6)' },
    { value: 'Asia/Tokyo', text: 'Tokyo (UTC+9)', disabled: true },
  ];

  @tracked zone = '';

  @action
  chooseZone(event) {
    this.zone = event.target.value;
  }
}
```
