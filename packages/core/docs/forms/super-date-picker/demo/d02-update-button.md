---
order: 2
---

# Update button

<EuiText>

When `@start` and `@end` change from interactions with **Quick select**, **Commonly used**, or **Recently used date ranges**, `@onTimeChange` will be immediately invoked. This is because these interactions set both `@start` and `@end` at the same time and are considered to be a complete change.

When `@start` and `@end` change from interactions with the **Absolute**, **Relative**, and **Now** tabs, `@onTimeChange` will **not** be invoked. In these cases, `@onTimeChange` will be invoked when the user clicks the **Update** button. This gives users the ability to set both `@start` and `@end` before triggering `@onTimeChange`. Set `@showUpdateButton={{false}}` to immediately invoke `@onTimeChange` for all `@start` and `@end` changes.

### More configurations

Instead of hiding completely, you can reduce the footprint of the update button to just an icon with `@showUpdateButton="iconOnly"`. You can further configure the button using `@updateButtonProps`, like setting the `fill` to `false`.

On small screens (`'xs'` and `'s'`) the button collapses to its icon, keeping its label for screen readers; change the sizes with `@updateButtonProps={{hash responsive=(array "xs")}}` or turn it off with `responsive=false`. After a change, once the date popover closes, the button shows a "Click to apply" tooltip for two seconds (`showTooltip`); `toolTipProps` configures that tooltip.

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

export default class UpdateButtonDemo extends Component {
  @tracked showUpdateButton = true;
  @tracked showIconOnly = false;
  @tracked showFill = true;
  @tracked isLoading = false;
  @tracked start = 'now-30m';
  @tracked end = 'now';

  get updateButtonProps() {
    return { fill: this.showFill };
  }

  get updateButtonHidden() {
    return !this.showUpdateButton;
  }

  get showUpdateButtonValue() {
    return this.showUpdateButton && this.showIconOnly ? 'iconOnly' : this.showUpdateButton;
  }

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
  stopLoading() {
    this.isLoading = false;
  }

  @action
  toggleShowApplyButton() {
    this.showUpdateButton = !this.showUpdateButton;
  }

  @action
  toggleShowFill() {
    this.showFill = !this.showFill;
  }

  @action
  toggleShowIconOnly() {
    this.showIconOnly = !this.showIconOnly;
  }

  <template>
    <EuiFlexGroup @gutterSize="xl" @responsive={{false}}>
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch
          @label="Show update button"
          @onChange={{this.toggleShowApplyButton}}
          @checked={{this.showUpdateButton}}
        />
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch
          @label="Fill"
          @onChange={{this.toggleShowFill}}
          @checked={{this.showFill}}
          @disabled={{this.updateButtonHidden}}
        />
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch
          @label="Icon only"
          @onChange={{this.toggleShowIconOnly}}
          @checked={{this.showIconOnly}}
          @disabled={{this.updateButtonHidden}}
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
      @showUpdateButton={{this.showUpdateButtonValue}}
      @updateButtonProps={{this.updateButtonProps}}
    />
    <EuiSpacer />
  </template>
}
```
