---
order: 1
---

# Demo

```hbs template
<EuiForm>
  {{#let (unique-id) as |inputId|}}
    <EuiFormRow @label="Some Input" @helpText="here's some help text" @id={{inputId}}>
      <EuiFieldSearch @clear={{set this.text ""}} @id={{inputId}} @onSearch={{set this.text}} />
      {{this.text}}
    </EuiFormRow>
  {{/let}}
</EuiForm>
```
