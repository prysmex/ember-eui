---
order: 1
---

## Simple select

```hbs template
<EuiSelect
  @label='Simple select'
  @value={{this.select1}}
  @hasNoInitialSelection={{true}}
  @options={{array
    (hash value='1' text='hello')
    (hash value='2' text='goodbye')
  }}
  {{on 'change' (pick 'target.value' (set this 'select1'))}}
/>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class extends Component {
  @tracked select1 = '';
  @tracked select2 = '';
}
```
