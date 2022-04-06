---
order: 1
---

```hbs template
<EuiFieldPassword
  @value={{this.password}}
  {{on 'input' (pick 'target.value' (set this 'password'))}}
/>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class extends Component {
  @tracked password = '';
}
```
