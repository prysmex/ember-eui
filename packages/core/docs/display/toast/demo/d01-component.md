---
order: 1
---

# Component

```gjs component
import Component from '@glimmer/component';
import { EuiToast } from '@ember-eui/core/components';

export default class extends Component {
  noop = () => {};

  <template>
    <div style='max-width: 320px'>
      <EuiToast
        @title='Example of a good toast'
        @body='A good toast message is short and to the point. It should very rarely span multiple lines.'
        @onClose={{this.noop}}
      />
    </div>
  </template>
}
```

