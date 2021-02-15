---
order: 1
---

# Demo

```hbs template
<EuiForm>
  {{#let (unique-id) as |inputId|}}
    <EuiFormRow @label="Some Input" @helpText="here's some help text" @id={{inputId}}>
      <EuiFieldText
        @value={{this.num}}
        @clear={{set this.num ""}}
        @id={{inputId}}
        {{on "input" (pick "target.value" (set this.num))}}
      >
        <:prepend as |classes|>
          <EuiButtonIcon
            class={{classes}}
            @size="xs"
            @iconType="faceHappy"
            {{on "click" this.salute}}
          />
        </:prepend>
        <:append as |classes|>
          <EuiFormLabel class={{classes}} for={{inputId}}>
            Salute
          </EuiFormLabel>
          <EuiButtonIcon
            class={{classes}}
            @size="xs"
            @iconType="faceHappy"
            {{on "click" this.salute}}
          />
        </:append>
      </EuiFieldText>
    </EuiFormRow>
  {{/let}}
  <EuiHorizontalRule />
  <EuiTitle>
    With Errors
  </EuiTitle>
  {{#let (unique-id) as |inputId|}}
    <EuiFormRow
      @label="Some Input"
      @helpText="here's some help text"
      @error={{array "error"}}
      @isInvalid={{true}}
      @id={{inputId}}
    >
      <EuiFieldText
        @value={{this.num2}}
        @id={{inputId}}
        {{on "input" (pick "target.value" (set this.num2))}}
      />
    </EuiFormRow>
  {{/let}}
</EuiForm>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EuiTextFieldDemo1 extends Component {
  @tracked num = 1;
  @tracked num2 = 1;

  salute() {
    alert('hello');
  }
}
```
