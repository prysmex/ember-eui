---
order: 8
---

# Clamp your own element (Ember EUI extension)

<EuiText>

With `@cloneElement={{true}}`, `EuiTextBlockTruncate` renders nothing itself and yields a modifier that applies the clamp to your own element instead (upstream's `cloneElement`), e.g. a paragraph inside `EuiText`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiText, EuiTextBlockTruncate } from '@ember-eui/core/components';

export default class extends Component {
  text =
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.';

  <template>
    <div style='max-width: 400px'>
      <EuiText>
        <EuiTextBlockTruncate @lines={{3}} @cloneElement={{true}} as |clamp|>
          <p {{clamp}}>{{this.text}}</p>
        </EuiTextBlockTruncate>
      </EuiText>
    </div>
  </template>
}
```

