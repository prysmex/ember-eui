---
order: 2
---

# With EUI fields

<EuiText>

Instead of plain inputs, use EUI's fields with `@controlOnly={{true}}`:
they render just their `<input>` and the delimited layout provides the
border, icons and states. Put the yielded class on each control.

</EuiText>

```hbs template
<EuiFormRow @label="Price range">
  <EuiFormControlLayoutDelimited @icon="currency">
    <:startControl as |classes|>
      <EuiFieldNumber
        @controlOnly={{true}}
        class={{classes}}
        @value={{this.min}}
        aria-label="Minimum price"
        {{on "input" (fn this.update "min")}}
      />
    </:startControl>
    <:endControl as |classes|>
      <EuiFieldNumber
        @controlOnly={{true}}
        class={{classes}}
        @value={{this.max}}
        aria-label="Maximum price"
        {{on "input" (fn this.update "max")}}
      />
    </:endControl>
  </EuiFormControlLayoutDelimited>
</EuiFormRow>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DelimitedFieldsDemo extends Component {
  @tracked min = '10';
  @tracked max = '250';

  @action
  update(field, event) {
    this[field] = event.target.value;
  }
}
```
