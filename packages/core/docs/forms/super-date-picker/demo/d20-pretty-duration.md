---
order: 20
---

# Pretty duration (opt-in)

<EuiText>

With `@showPrettyDuration={{true}}`, a commonly used or relative range ("Last 15 minutes") shows as one summary button until it is clicked; clicking it shows the start and end dates with the start popover open. Quick selections show as a summary again. Upstream EUI always does this; in Ember EUI it is opt-in.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiSuperDatePicker } from '@ember-eui/core/components';

export default class SuperDatePickerPrettyDurationDemo extends Component {
  @tracked start = 'now-15m';
  @tracked end = 'now';

  @action
  onTimeChange({ start, end }) {
    this.start = start;
    this.end = end;
  }

  <template>
    <EuiSuperDatePicker
      @start={{this.start}}
      @end={{this.end}}
      @onTimeChange={{this.onTimeChange}}
      @showPrettyDuration={{true}}
    />
  </template>
}
```
