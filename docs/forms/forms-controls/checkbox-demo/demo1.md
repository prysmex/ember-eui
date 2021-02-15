---
order: 1
---

# Demo

```hbs template
<EuiForm>
  <EuiCheckbox
    @id="131"
    @label="I am a checkbox"
    @checked={{this.checkbox1}}
    {{on "change" (pick "target.checked" (set this.checkbox1))}}
  />
  <EuiCheckbox
    @id="131d"
    @label="I am an indeterminate checkbox"
    @indeterminate={{this.indeterminate}}
    {{on "change" (pick "target.checked" (set this.indeterminate))}}
  />
  <EuiCheckbox
    @disabled={{true}}
    @id="disabled-checkbox"
    @label="I am a checkbox"
    @checked={{this.checkbox1}}
    {{on "change" (pick "target.checked" (set this.checkbox1))}}
  />
</EuiForm>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EuiTextFieldDemo1 extends Component {
  @tracked checkbox1 = true;
  @tracked indeterminate = true;
}
```
