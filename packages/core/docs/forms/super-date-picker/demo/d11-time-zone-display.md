---
order: 11
---

# Time zone display

<EuiText>

Time zone information can be made visible in the date picker popovers. To do that, pass the time zone name in `@timeZoneDisplayProps`, e.g. `@timeZoneDisplayProps={{hash timeZone="America/Los_Angeles"}}`.

Additionally, custom content can be added to the time zone information with a `customRender` component in `@timeZoneDisplayProps`. It gets `@nameDisplay` (a component rendering the default icon and name), `@utcOffset` and `@timeZoneName`.

This is informational only, it **will not** affect how dates are handled internally by the component.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import {
  EuiButtonIcon,
  EuiSuperDatePicker,
  EuiToolTip,
} from '@ember-eui/core/components';

const TIME_ZONE_NAME = 'Browser';
const timeZonesDatabaseLabel = 'Time zones database';

const CustomTimeZoneDisplay = <template>
  <@nameDisplay />
  <EuiToolTip @content={{timeZonesDatabaseLabel}} @disableScreenReaderOutput={{true}}>
    <EuiButtonIcon
      aria-label={{timeZonesDatabaseLabel}}
      @href="https://en.wikipedia.org/wiki/List_of_tz_database_time_zones"
      @target="_blank"
      rel="noopener noreferrer"
      @iconType="documentation"
    />
  </EuiToolTip>
</template>;

export default class TimeZoneDisplayDemo extends Component {
  @tracked start = 'now-15m';
  @tracked end = 'now';

  timeZoneDisplayProps = {
    timeZone: TIME_ZONE_NAME,
    customRender: CustomTimeZoneDisplay,
  };

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
      @showUpdateButton={{false}}
      @timeZoneDisplayProps={{this.timeZoneDisplayProps}}
    />
  </template>
}
```
