---
order: 1
---

# Demo

```hbs template
<EuiTitle>
  Search Text:
  <EuiTextColor @color="secondary">
    {{this.searchText}}
  </EuiTextColor>
</EuiTitle>
<EuiForm>
  {{#let (unique-id) as |inputId|}}
    <EuiFormRow @label="Some Input" @helpText="here's some help text" @id={{inputId}}>
      <EuiFieldSearch @clear={{set this.text ""}} @id={{inputId}} @onSearch={{set this.searchText}} />
    </EuiFormRow>
  {{/let}}
</EuiForm>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EuiSearchFieldDemo1 extends Component {
  @tracked searchText = '';
}
```
