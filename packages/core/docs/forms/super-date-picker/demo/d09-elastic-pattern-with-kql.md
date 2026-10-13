---
order: 9
---

# Elastic pattern with KQL

<EuiText>

The following is a demo pattern of how to layout the `EuiSuperDatePicker` alongside Elastic's KQL search bar using `EuiSearchBar` and shrinking to fit when the search bar is in focus.

**Ember EUI difference:** `EuiSearchBar`'s `@box` has no `prepend`, `append` or focus callbacks, so the saved searches and KQL buttons are left out and the focus is tracked with `focusin` / `focusout` on a wrapper.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import {
  EuiFlexGroup,
  EuiFlexItem,
  EuiSearchBar,
  EuiSuperDatePicker,
} from '@ember-eui/core/components';

export default class SuperDatePickerKqlDemo extends Component {
  box = {
    'aria-label': 'Filter using KQL',
    placeholder: 'type:visualization -dashboard',
  };

  @tracked recentlyUsedRanges = [];
  @tracked isLoading = false;
  @tracked refreshInterval = 1000;
  @tracked isPaused = true;
  @tracked start = 'now-30m';
  @tracked end = 'now';
  @tracked showQuickSelectOnly = false;

  @action
  onTimeChange({ start, end }) {
    const recentlyUsedRange = this.recentlyUsedRanges.filter(
      (range) => !(range.start === start && range.end === end)
    );

    recentlyUsedRange.unshift({ start, end });
    this.start = start;
    this.end = end;
    this.recentlyUsedRanges =
      recentlyUsedRange.length > 10 ? recentlyUsedRange.slice(0, 9) : recentlyUsedRange;
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
  stopLoading() {
    this.isLoading = false;
  }

  @action
  onRefreshChange({ isPaused, refreshInterval }) {
    this.isPaused = isPaused;
    this.refreshInterval = refreshInterval;
  }

  @action
  focusIn() {
    this.showQuickSelectOnly = true;
  }

  @action
  focusOut() {
    this.showQuickSelectOnly = false;
  }

  noop = () => {};

  <template>
    <EuiFlexGroup @gutterSize="s">
      <EuiFlexItem style="min-width: 50%">
        <div {{on "focusin" this.focusIn}} {{on "focusout" this.focusOut}}>
          <EuiSearchBar @box={{this.box}} @onChange={{this.noop}} />
        </div>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <div>
          <EuiSuperDatePicker
            @start={{this.start}}
            @end={{this.end}}
            @onTimeChange={{this.onTimeChange}}
            @onRefresh={{this.onRefresh}}
            @isPaused={{this.isPaused}}
            @isLoading={{this.isLoading}}
            @refreshInterval={{this.refreshInterval}}
            @onRefreshChange={{this.onRefreshChange}}
            @recentlyUsedRanges={{this.recentlyUsedRanges}}
            @width="auto"
            @isQuickSelectOnly={{this.showQuickSelectOnly}}
          />
        </div>
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```
