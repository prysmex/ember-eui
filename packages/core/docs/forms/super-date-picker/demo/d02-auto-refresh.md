---
order: 2
---

# Auto refresh

<EuiText>

Open the calendar menu: with `@onRefreshChange` it ends with "Refresh
every". Start the refresh and `@onRefresh` is called at that interval (the
counter below goes up); keep `@isPaused` and `@refreshInterval` in sync
from `@onRefreshChange`.

</EuiText>

```hbs template
<EuiSuperDatePicker
  @start={{this.start}}
  @end={{this.end}}
  @onTimeChange={{this.onTimeChange}}
  @isPaused={{this.isPaused}}
  @refreshInterval={{this.refreshInterval}}
  @onRefreshChange={{this.onRefreshChange}}
  @onRefresh={{this.onRefresh}}
/>
<EuiSpacer />
<EuiText @size="s">
  <p>
    {{if this.isPaused "Paused" "Refreshing"}}, every {{this.seconds}}s.
    Refreshed {{this.refreshes}} times.
  </p>
</EuiText>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class AutoRefreshDemo extends Component {
  @tracked start = 'now-15m';
  @tracked end = 'now';
  @tracked isPaused = true;
  @tracked refreshInterval = 5000;
  @tracked refreshes = 0;

  get seconds() {
    return this.refreshInterval / 1000;
  }

  @action
  onTimeChange({ start, end }) {
    this.start = start;
    this.end = end;
  }

  @action
  onRefreshChange({ refreshInterval, isPaused }) {
    this.refreshInterval = refreshInterval;
    this.isPaused = isPaused;
  }

  @action
  onRefresh() {
    this.refreshes++;
  }
}
```
