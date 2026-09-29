---
order: 2
---

# Title and description

<EuiText>

Options with a title and a description in the list and only the title in
the control. `@hasDividers` separates them; `@itemLayoutAlign="top"`
aligns the check mark with the title.

</EuiText>

```hbs template
<EuiFormRow @label="Index lifecycle" @fullWidth={{true}}>
  <EuiSuperSelect
    @options={{this.options}}
    @valueOfSelected={{this.value}}
    @onChange={{this.setValue}}
    @hasDividers={{true}}
    @itemLayoutAlign="top"
    @fullWidth={{true}}
  >
    <:dropdownDisplay as |option|>
      <strong>{{option.inputDisplay}}</strong>
      <EuiText @size="s" @color="subdued">
        <p>{{option.description}}</p>
      </EuiText>
    </:dropdownDisplay>
  </EuiSuperSelect>
</EuiFormRow>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class SuperSelectComplex extends Component {
  @tracked value = 'hot';

  options = [
    {
      value: 'hot',
      inputDisplay: 'Hot',
      description: 'Recent data, searched often: kept on the fastest nodes.',
    },
    {
      value: 'warm',
      inputDisplay: 'Warm',
      description: 'Searched less often: moved to cheaper nodes after a week.',
    },
    {
      value: 'cold',
      inputDisplay: 'Cold',
      description: 'Rarely searched: kept as searchable snapshots.',
    },
  ];

  @action
  setValue(value) {
    this.value = value;
  }
}
```
