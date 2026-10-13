---
order: 4
---

# Actions

<EuiText>

Use `@actionProps` to add a primary and an optional secondary action. A standalone secondary action without a primary is not supported.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiToast } from '@ember-eui/core/components';

export default class extends Component {
  actionProps = {
    primary: { children: 'Download' },
    secondary: { children: 'Dismiss' },
  };

  <template>
    <div style='max-width: 320px'>
      <EuiToast
        @title="Created report for dashboard 'Tuba Sales by Region'"
        @color='success'
        @body='Your export has finished processing.'
        @actionProps={{this.actionProps}}
      />
    </div>
  </template>
}
```

