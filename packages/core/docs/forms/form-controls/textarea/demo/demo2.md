---
order: 2
---

# Invalid textarea

```hbs template
<EuiTextArea
  @value={{this.text}}
  @rows={{10}}
  @resize='both'
  @isInvalid={{true}}
  {{on 'input' (pick 'target.value' (set this 'text'))}}
/>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class extends Component {
  @tracked text = '';
}
```
