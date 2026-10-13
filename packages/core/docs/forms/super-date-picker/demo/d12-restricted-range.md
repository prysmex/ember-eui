---
order: 12
---

# Restricted range

<EuiText>

To limit the range from which users can choose a date, you can use `@minDate` and `@maxDate` (moment objects). Days outside them are disabled in the calendar, and a range starting before `@minDate` or ending after `@maxDate` is invalid. By updating the date input values for start and end, users get immediate feedback on what range values are allowed.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import moment from 'moment';
import { EuiSuperDatePicker } from '@ember-eui/core/components';

export default class RestrictedRangeDemo extends Component {
  @tracked start = 'now-30m';
  @tracked end = 'now';

  minDate = moment().subtract(1, 'M');
  maxDate = moment().add(1, 'M');

  @action
  onTimeChange({ start, end }) {
    this.start = start;
    this.end = end;
  }

  <template>
    <EuiSuperDatePicker
      @start={{this.start}}
      @end={{this.end}}
      @minDate={{this.minDate}}
      @maxDate={{this.maxDate}}
      @onTimeChange={{this.onTimeChange}}
    />
  </template>
}
```
