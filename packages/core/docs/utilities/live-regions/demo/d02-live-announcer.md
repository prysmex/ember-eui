---
order: 2
---

# Announcing feedback once

<EuiText>

Saving inserts an `EuiLiveAnnouncer`, which announces "Changes saved" and
clears itself after two seconds; saving again changes its text, so it is
announced again. The visible text is separate.

</EuiText>

```hbs template
<EuiButton @size="s" {{on "click" this.save}}>Save</EuiButton>
{{#if this.savedCount}}
  <EuiLiveAnnouncer>Changes saved ({{this.savedCount}})</EuiLiveAnnouncer>
  <EuiSpacer @size="s" />
  <EuiText @size="s" @color="subdued"><p>Saved {{this.savedCount}} times.</p></EuiText>
{{/if}}
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class LiveAnnouncerDemo extends Component {
  @tracked savedCount = 0;

  @action save() {
    this.savedCount++;
  }
}
```
