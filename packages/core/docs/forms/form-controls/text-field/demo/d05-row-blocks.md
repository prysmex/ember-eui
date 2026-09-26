---
order: 5
---

# Customizing the row with blocks

<EuiText>

`EuiFormRow`'s `<:label>`, `<:helpText>` and `<:errors>` blocks take markup
instead of plain strings. `<:errors>` is called once per error, with the
error.

</EuiText>

```hbs template
<EuiFormRow @isInvalid={{true}} @error={{this.errors}}>
  <:label>
    Display name <EuiBetaBadge @label="New" @size="s" />
  </:label>
  <:field>
    <EuiFieldText @value="x" @isInvalid={{true}} />
  </:field>
  <:helpText>
    Shown next to your comments. <EuiLink @href="#">Learn more</EuiLink>
  </:helpText>
  <:errors as |error|>
    <EuiIcon @type="alert" @size="s" /> {{error}}
  </:errors>
</EuiFormRow>
```

```js component
import Component from '@glimmer/component';

export default class RowBlocksDemo extends Component {
  errors = ['Too short: use at least 2 characters.', "Can't be a single letter."];
}
```
