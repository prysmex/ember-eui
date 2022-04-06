---
order: 2
---

# Form Demo

```hbs template
<EuiForm>
  {{#let (unique-id) as |inputId|}}
    <EuiFormRow
      @label='Some Input'
      @id={{inputId}}
      @helpText="here's some help text"
    >
      <EuiFieldNumber
        @value={{this.num}}
        @id={{inputId}}
        {{on 'input' (pick 'target.value' (set this 'num'))}}
      />
    </EuiFormRow>
  {{/let}}
  {{#let (unique-id) as |inputId|}}
    <EuiFormRow
      @label='Some Input'
      @id={{inputId}}
      @helpText="here's some help text"
    >
      <EuiFieldNumber
        @value={{this.num}}
        @id={{inputId}}
        {{on 'input' (pick 'target.value' (set this 'num'))}}
      >
        <:prepend as |classes|>
          <EuiButtonIcon
            @iconType='faceHappy'
            class={{classes}}
            {{on 'click' this.salute}}
          />
        </:prepend>
      </EuiFieldNumber>
    </EuiFormRow>
  {{/let}}
  <EuiHorizontalRule />
  <EuiTitle>
    With Errors
  </EuiTitle>
  {{#let (unique-id) as |inputId|}}
    <EuiFormRow
      @label='Some Input'
      @isInvalid={{true}}
      @id={{inputId}}
      @error={{array 'error one' 'error two'}}
      @helpText="here's some help text"
    >
      <EuiFieldNumber
        @value={{this.num2}}
        @id={{inputId}}
        {{on 'input' (pick 'target.value' (set this 'num2'))}}
      />
    </EuiFormRow>
  {{/let}}
</EuiForm>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class extends Component {
  @tracked num = 1;
  @tracked num2 = 1;

  salute() {
    alert('hey');
  }
}
```
