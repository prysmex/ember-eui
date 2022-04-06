---
order: 1
---

```hbs template
<EuiFieldNumber
  @value={{this.num}}
  {{on 'input' (pick 'target.value' (set this 'num2'))}}
/>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class extends Component {
  @tracked num = 1;
}
```
