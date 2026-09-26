---
order: 3
---

# States

<EuiText>

`@isInvalid`, `@isLoading`, `@compressed`, `@disabled` and `@fullWidth`
work as on the other fields.

</EuiText>

```hbs template
<EuiFormRow @label="Invalid" @isInvalid={{true}} @error="Choose a size.">
  <EuiSelect @options={{this.sizes}} @hasNoInitialSelection={{true}} @isInvalid={{true}} />
</EuiFormRow>
<EuiFormRow @label="Loading">
  <EuiSelect @options={{this.sizes}} @isLoading={{true}} />
</EuiFormRow>
<EuiFormRow @label="Compressed" @display="rowCompressed">
  <EuiSelect @options={{this.sizes}} @compressed={{true}} />
</EuiFormRow>
<EuiFormRow @label="Disabled">
  <EuiSelect @options={{this.sizes}} @disabled={{true}} />
</EuiFormRow>
```

```js component
import Component from '@glimmer/component';

export default class SelectStatesDemo extends Component {
  sizes = [
    { value: 's', text: 'Small' },
    { value: 'm', text: 'Medium' },
    { value: 'l', text: 'Large' },
  ];
}
```
