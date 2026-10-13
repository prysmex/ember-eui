---
order: 1
---

# Super date picker

<EuiText>

`EuiSuperDatePicker` is a complex date picker that supports relative and absolute dates. It offers a convenient **Quick select menu** which includes **Commonly used dates**, **Recently used date ranges** and **Auto refresh** (see below).

Pass `@start` and `@end` date times as strings in either datemath format (e.g.: `now`, `now-15m`, `now-15m/m`) or as absolute date in the format `YYYY-MM-DDTHH:mm:ss.SSSZ`. Use [@elastic/datemath](https://github.com/elastic/datemath-js) to convert these strings into moment objects:

```js
import dateMath from '@elastic/datemath';

const startMoment = dateMath.parse(start);
// dateMath.parse is inconsistent with unparsable strings.
// Sometimes undefined is returned, other times an invalid moment is returned
if (!startMoment || !startMoment.isValid()) {
  throw new Error('Unable to parse start string');
}

// Pass roundUp when parsing end string
const endMoment = dateMath.parse(end, { roundUp: true });
if (!endMoment || !endMoment.isValid()) {
  throw new Error('Unable to parse end string');
}
```

`EuiSuperDatePicker` should be resilient to invalid date values. You can try to break it with unexpected values in the inputs of the example.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import {
  EuiFieldText,
  EuiFormControlLayoutDelimited,
  EuiFormPrepend,
  EuiPanel,
  EuiSpacer,
  EuiSuperDatePicker,
  EuiText,
} from '@ember-eui/core/components';

export default class SuperDatePickerDemo extends Component {
  @tracked isLoading = false;
  @tracked start = 'now-30m';
  @tracked end = 'now';

  @action
  onTimeChange({ start, end }) {
    this.start = start;
    this.end = end;
    this.isLoading = true;
    setTimeout(this.stopLoading, 1000);
  }

  @action
  onRefresh({ start, end, refreshInterval }) {
    return new Promise((resolve) => {
      setTimeout(resolve, 100);
    }).then(() => {
      console.log(start, end, refreshInterval);
    });
  }

  @action
  onStartInputChange(event) {
    this.start = event.target.value;
  }

  @action
  onEndInputChange(event) {
    this.end = event.target.value;
  }

  @action
  stopLoading() {
    this.isLoading = false;
  }

  <template>
    <EuiPanel @color="subdued" @paddingSize="m">
      <EuiText @size="s">
        EuiSuperDatePicker should be resilient to invalid date values. You can
        try to break it with unexpected values here.
      </EuiText>
      <EuiSpacer />
      <EuiFormControlLayoutDelimited>
        <:prepend><EuiFormPrepend @label="Dates" /></:prepend>
        <:startControl as |classes|>
          <EuiFieldText
            @controlOnly={{true}}
            @value={{this.start}}
            class={{classes}}
            placeholder="start"
            aria-label="Start"
            {{on "input" this.onStartInputChange}}
          />
        </:startControl>
        <:endControl as |classes|>
          <EuiFieldText
            @controlOnly={{true}}
            @value={{this.end}}
            class={{classes}}
            placeholder="end"
            aria-label="End"
            {{on "input" this.onEndInputChange}}
          />
        </:endControl>
      </EuiFormControlLayoutDelimited>
    </EuiPanel>
    <EuiSpacer />
    <EuiSuperDatePicker
      @isLoading={{this.isLoading}}
      @start={{this.start}}
      @end={{this.end}}
      @onTimeChange={{this.onTimeChange}}
      @onRefresh={{this.onRefresh}}
    />
  </template>
}
```
