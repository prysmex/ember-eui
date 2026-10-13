---
order: 1
---

# Copy

```gjs component
import GlimmerComponent from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiButton, EuiCopy, EuiFieldText, EuiFormRow, EuiSpacer } from '@ember-eui/core/components';
import { on } from '@ember/modifier';
import { pick } from '@nullvoxpopuli/ember-composable-helpers';
import { set } from 'ember-set-helper';

export default class OutsideClickDetectorComponentDemo1 extends GlimmerComponent {
  @tracked copyText = 'I am the text that will be copied';

  <template>
    <div>
      <EuiFormRow @label='Enter text that will be copied to clipboard'>
        <EuiFieldText
          @value={{this.copyText}}
          {{on 'input' (pick 'target.value' (set this 'copyText'))}}
        />
      </EuiFormRow>

      <EuiSpacer @size='m' />

      <EuiCopy @textToCopy={{this.copyText}} as |copy|>
        <EuiButton {{on 'click' copy}}>Click to copy input text</EuiButton>
      </EuiCopy>
    </div>
  </template>
}
```

