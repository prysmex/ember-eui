---
order: 7
---

# Multi line

<EuiText>

`EuiTextBlockTruncate` allows truncating text after a set number of wrapping `@lines`.

Please note: this component is currently a quick shortcut for the CSS `line-clamp` property. This means that truncating at the end of the text is the default, and there are currently no plans to add JavaScript customization for this behavior.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiPanel, EuiText, EuiTextBlockTruncate } from '@ember-eui/core/components';

export default class extends Component {
  text =
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium.';

  <template>
    <EuiText>
      <EuiPanel style='overflow: auto; resize: inline; inline-size: 50ch; max-inline-size: 100%;'>
        <EuiTextBlockTruncate @lines={{3}}>
          {{this.text}}
        </EuiTextBlockTruncate>
      </EuiPanel>
    </EuiText>
  </template>
}
```

