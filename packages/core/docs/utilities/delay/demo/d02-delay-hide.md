---
order: 2
---

# Delay hide

<EuiText>

Saving takes 100ms, but the message stays for at least a second so it
can be read.

</EuiText>

```hbs template
<EuiButton {{on "click" this.save}}>Save</EuiButton>
<EuiSpacer />
<EuiDelayHide @hide={{not this.isSaving}} @minimumDuration={{1000}}>
  <EuiCallOut @title="Saving…" @iconType="clock" @size="s" />
</EuiDelayHide>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DelayHideDemo extends Component {
  @tracked isSaving = false;

  @action
  async save() {
    this.isSaving = true;
    await new Promise((resolve) => setTimeout(resolve, 100));
    this.isSaving = false;
  }
}
```
