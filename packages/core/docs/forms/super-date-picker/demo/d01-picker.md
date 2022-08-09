---
order: 1
---

```hbs template
<EuiText size="s">
  EuiSuperDatePicker should be resilient to invalid date values. You can try to break it with unexpected values here.
</EuiText>

<EuiSpacer />

<EuiFormControlLayoutDelimited>
  <:prepend as |classes|>
    <EuiFormLabel class={{classes}}>Dates</EuiFormLabel>
  </:prepend>

  <:startControl as |classes|>
    <input
      class={{concat classes " euiFieldText"}}
      type="text"
      placeholder="start"
      value={{this.start}}
      {{on "change" this.onStartInputChange}}
    />
  </:startControl>

  <:endControl as |classes|>
    <input
      class={{concat classes " euiFieldText"}}
      type="text"
      placeholder="end"
      value={{this.end}}
      {{on "change" this.onEndInputChange}}
    />
  </:endControl>
</EuiFormControlLayoutDelimited>

<EuiSpacer />

<EuiSuperDatePicker
  @onTimeChange={{this.onTimeChange}}
  @start={{this.start}}
  @end={{this.end}}
  @isLoading={{this.isLoading}}
  @onRefresh={{this.onRefresh}}
/>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class extends Component {
  @tracked start = 'now-30m';
  @tracked end = 'now';
  @tracked isLoading = false;

  @action onTimeChange({ start, end }) {
    this.start = start;
    this.end = end;
    this.isLoading = true;
    this.startLoading();
  }

  @action onRefresh({ start, end, refreshInterval }) {
    return new Promise((resolve) => {
      setTimeout(resolve, 100);
    }).then(() => {
      console.log(start, end, refreshInterval);
    });
  };

  @action onStartInputChange(e) {
    this.start = e.target.value;
  };

  @action onEndInputChange(e) {
    this.end = e.target.value;
  };

  @action startLoading() {
    setTimeout(this.stopLoading, 1000);
  };

  @action stopLoading() {
    this.isLoading = false;
  };
}
```
