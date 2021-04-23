---
order: 1
---

# Demo

```hbs template
<EuiForm>
  <EuiRadio
    @id="131"
    @label="I am a checkbox"
    checked={{this.radio1}}
    {{on "change" (pick "target.checked" (set this "radio1"))}}
  />
  <EuiRadio
    @id="131d"
    @label="I am an indeterminate checkbox"
    checked={{this.radio2}}
  />
  <EuiRadio
    @disabled={{true}}
    @id="disabled-checkbox"
    @label="I am a checkbox"
    @checked={{this.radio1}}
    {{on "change" (pick "target.checked" (set this "radio1"))}}
  />
</EuiForm>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EuiTextFieldDemo1 extends Component {
  @tracked radio1 = true;
  @tracked radio2 = false;
}
```
