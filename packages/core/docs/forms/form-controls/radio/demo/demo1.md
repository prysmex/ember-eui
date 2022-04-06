---
order: 1
---

```hbs template
<EuiForm>
  <EuiRadio
    @id='131'
    @label='I am a radio'
    checked={{this.radio1}}
    {{on 'change' (pick 'target.checked' (set this 'radio1'))}}
  />
  <EuiRadio
    @disabled={{true}}
    @id='disabled-checkbox'
    @label='I am a radio'
    @checked={{this.radio1}}
    {{on 'change' (pick 'target.checked' (set this 'radio1'))}}
  />
  <EuiRadio
    @id='131'
    checked={{this.radio1}}
    {{on 'change' (pick 'target.checked' (set this 'radio1'))}}
  >
    <:label>
      Using the
      <strong>:label</strong>
      block
    </:label>
  </EuiRadio>
</EuiForm>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class extends Component {
  @tracked radio1 = true;
  @tracked radio2 = false;
}
```
