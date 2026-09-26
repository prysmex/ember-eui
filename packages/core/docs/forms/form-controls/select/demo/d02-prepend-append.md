---
order: 2
---

# Prepend and append

<EuiText>

Like the text fields, the `<:prepend>` / `<:append>` blocks join labels or
buttons to the select; put the yielded class on them.

</EuiText>

```hbs template
<EuiSelect @options={{this.sorts}} @value="date" aria-label="Sort by">
  <:prepend as |classes|>
    <EuiFormLabel class={{classes}}>Sort by</EuiFormLabel>
  </:prepend>
  <:append as |classes|>
    <EuiButtonIcon class={{classes}} @iconType="sortDown" aria-label="Descending" />
  </:append>
</EuiSelect>
```

```js component
import Component from '@glimmer/component';

export default class SelectBlocksDemo extends Component {
  sorts = [
    { value: 'date', text: 'Date' },
    { value: 'name', text: 'Name' },
    { value: 'size', text: 'Size' },
  ];
}
```
