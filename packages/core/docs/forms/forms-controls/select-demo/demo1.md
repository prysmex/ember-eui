---
order: 1
---

# Demo

```hbs template
{{#let (unique-id) as |selectId|}}
  <EuiFormRow @label="Some Select" @helpText="here's some help text" @id={{selectId}}>
    <EuiSelect
      @value={{this.select1}}
      @hasNoInitialSelection={{true}}
      @options={{array (hash value="1" text="hello") (hash value="2" text="goodbye")}}
      @id={{selectId}}
      {{on "change" (pick "target.value" (set this "select1"))}}
    >
      <:prepend as |classes|>
        <EuiFormLabel class={{classes}} for={{selectId}}>
          Here's a label
        </EuiFormLabel>
      </:prepend>
    </EuiSelect>
  </EuiFormRow>
{{/let}}
<EuiHorizontalRule />
<EuiTitle>
  With Errors
</EuiTitle>
{{#let (unique-id) as |selectId|}}
  <EuiFormRow
    @label="Some Input"
    @isInvalid={{true}}
    @error={{array "error one" "error two"}}
    @helpText="here's some help text"
    @id={{selectId}}
  >
    <EuiSelect
      @value={{this.select2}}
      @hasNoInitialSelection={{true}}
      @options={{array (hash value="1" text="hello") (hash value="2" text="goodbye")}}
      @id={{selectId}}
      {{on "change" (pick "target.value" (set this "select2"))}}
    >
      <:prepend as |classes|>
        <EuiFormLabel class={{classes}} for={{selectId}}>
          Here's a label
        </EuiFormLabel>
      </:prepend>
    </EuiSelect>
  </EuiFormRow>
{{/let}}
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EuiTextFieldDemo1 extends Component {
  @tracked select1 = '';
  @tracked select2 = '';
}
```
