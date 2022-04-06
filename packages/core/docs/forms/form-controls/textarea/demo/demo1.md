---
order: 1
---

# Simple textarea

```hbs template
<EuiTextArea
  @value={{this.text}}
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
