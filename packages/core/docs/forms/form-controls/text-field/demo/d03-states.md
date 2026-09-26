---
order: 3
---

# Icon, clear button and states

<EuiText>

- `@icon` shows an icon inside the input.
- `@clear` shows a clear button calling your function, where you empty the
  value.
- `@isLoading` shows a spinner, e.g. while checking a value.
- `@compressed` makes the input shorter, for dense forms.
- `@readOnly` and `@disabled` work as on a native input.

</EuiText>

```hbs template
<EuiFlexGrid @columns={{2}}>
  <EuiFlexItem>
    <EuiFormRow @label="With an icon">
      <EuiFieldText @icon="user" @value="Jane" />
    </EuiFormRow>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiFormRow @label="Clearable">
      <EuiFieldText
        @value={{this.query}}
        @clear={{this.clear}}
        {{on "input" this.updateQuery}}
      />
    </EuiFormRow>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiFormRow @label="Loading">
      <EuiFieldText @isLoading={{true}} @value="checking…" />
    </EuiFormRow>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiFormRow @label="Compressed" @display="rowCompressed">
      <EuiFieldText @compressed={{true}} @value="Small" />
    </EuiFormRow>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiFormRow @label="Read only">
      <EuiFieldText @readOnly={{true}} @value="Can't edit me" />
    </EuiFormRow>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiFormRow @label="Disabled">
      <EuiFieldText @disabled={{true}} @value="Disabled" />
    </EuiFormRow>
  </EuiFlexItem>
</EuiFlexGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class TextFieldStatesDemo extends Component {
  @tracked query = 'Clear me';

  @action
  updateQuery(event) {
    this.query = event.target.value;
  }

  @action
  clear() {
    this.query = '';
  }
}
```
