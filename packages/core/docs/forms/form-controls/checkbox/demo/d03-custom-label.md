---
order: 3
---

# Custom label

<EuiText>

The `<:label>` block takes markup, e.g. a link to terms. Keep interactive
content in it minimal: clicking the label toggles the checkbox.

</EuiText>

```hbs template
<EuiCheckbox @checked={{this.accepted}} {{on "change" this.toggle}}>
  <:label>
    I accept the <strong>terms of service</strong>
  </:label>
</EuiCheckbox>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class CheckboxLabelDemo extends Component {
  @tracked accepted = false;

  @action
  toggle(event) {
    this.accepted = event.target.checked;
  }
}
```
