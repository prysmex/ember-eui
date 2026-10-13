---
order: 3
---

# Quick select panels

<EuiText>

`EuiSuperDatePicker`'s quick select menu provides the user with single-click options for quick selection with the following panels:

- `@commonlyUsedRanges`: A default set of common date ranges is automatically provided but can be overridden with this argument.
- `@recentlyUsedRanges`: Store the user's previously submitted time ranges and pass them back to the date picker with this argument. It's best to limit this list to around 10 items.

You can also reduce the `EuiSuperDatePicker` to display **just** the quick select button and dropdown by passing `@isQuickSelectOnly={{true}}`. Be sure you display the rendered time period elsewhere in your interface.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import {
  EuiFlexGroup,
  EuiFlexItem,
  EuiSpacer,
  EuiSuperDatePicker,
  EuiSwitch,
} from '@ember-eui/core/components';

export default class QuickSelectPanelsDemo extends Component {
  @tracked showRecentlyUsed = true;
  @tracked showQuickSelectOnly = false;
  @tracked recentlyUsedRanges = [];
  @tracked isLoading = false;
  @tracked start = 'now-30m';
  @tracked end = 'now';

  get recentRanges() {
    return this.showRecentlyUsed ? this.recentlyUsedRanges : undefined;
  }

  @action
  toggleShowRecentlyUsed() {
    this.showRecentlyUsed = !this.showRecentlyUsed;
  }

  @action
  toggleShowQuickSelectOnly() {
    this.showQuickSelectOnly = !this.showQuickSelectOnly;
  }

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

  <template>
    <EuiFlexGroup @gutterSize="xl" @responsive={{false}}>
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch
          @label="Show recently used"
          @onChange={{this.toggleShowRecentlyUsed}}
          @checked={{this.showRecentlyUsed}}
        />
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch
          @label="Show quick select only"
          @onChange={{this.toggleShowQuickSelectOnly}}
          @checked={{this.showQuickSelectOnly}}
        />
      </EuiFlexItem>
    </EuiFlexGroup>
    <EuiSpacer />
    <EuiSuperDatePicker
      @isLoading={{this.isLoading}}
      @start={{this.start}}
      @end={{this.end}}
      @onTimeChange={{this.onTimeChange}}
      @onRefresh={{this.onRefresh}}
      @recentlyUsedRanges={{this.recentRanges}}
      @isQuickSelectOnly={{this.showQuickSelectOnly}}
    />
    <EuiSpacer />
  </template>
}
```
