---
order: 2
---

# Single selection

<EuiText>

`@singleSelection={{true}}` allows one option; `@onChange` still receives
an array (with at most one item). `@singleSelection={{hash asPlainText=true}}`
shows the selection as plain text instead of a pill. Options can be plain
strings.

</EuiText>

```hbs template
<EuiFormRow @label="Country">
  <EuiComboBox
    @singleSelection={{hash asPlainText=true}}
    @options={{this.countries}}
    @selectedOptions={{this.selected}}
    @onChange={{this.select}}
    @placeholder="Select a country"
    as |country|
  >
    {{country}}
  </EuiComboBox>
</EuiFormRow>
<EuiText @size="s" @color="subdued">
  <p>Selected: {{if this.selected.length (get this.selected 0) "none"}}</p>
</EuiText>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class SingleSelectionDemo extends Component {
  countries = ['Argentina', 'Brazil', 'Canada', 'Mexico', 'Spain', 'Uruguay'];

  @tracked selected = ['Mexico'];

  @action
  select(selected) {
    this.selected = selected;
  }
}
```
