---
order: 4
---

# Delay hide with a simulated save (Ember EUI extra)

<EuiText>

Saving takes 100ms, but the message stays for at least a second so it
can be read.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiButton, EuiCallOut, EuiDelayHide, EuiSpacer } from '@ember-eui/core/components';
import { on } from '@ember/modifier';
import { not } from 'ember-truth-helpers';

export default class DelayHideDemo extends Component {
  @tracked isSaving = false;

  @action
  async save() {
    this.isSaving = true;
    await new Promise((resolve) => setTimeout(resolve, 100));
    this.isSaving = false;
  }

  <template>
    <EuiButton {{on "click" this.save}}>Save</EuiButton>
    <EuiSpacer />
    <EuiDelayHide @hide={{not this.isSaving}} @minimumDuration={{1000}}>
      <EuiCallOut @title="Saving…" @iconType="clock" @size="s" />
    </EuiDelayHide>
  </template>
}
```

