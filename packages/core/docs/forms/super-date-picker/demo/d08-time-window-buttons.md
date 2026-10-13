---
order: 8
---

# Time window buttons

<EuiText>

A button group for modifying the time range can be displayed next to the main control using the `@showTimeWindowButtons` argument. The buttons allow the time window to be shifted forward or backward and zoomed in or out.

Zooming expands or shrinks the time window by 50% by default. This can be customized by passing a configuration object with a `zoomFactor` property, e.g. `@showTimeWindowButtons={{hash zoomFactor=0.25}}`.

The "Zoom in" button is hidden by default. To enable it, set `showZoomIn` to `true` in the configuration object, e.g. `@showTimeWindowButtons={{hash showZoomIn=true}}`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import {
  EuiFlexGroup,
  EuiSpacer,
  EuiSuperDatePicker,
  EuiSwitch,
} from '@ember-eui/core/components';

export default class TimeWindowButtonsDemo extends Component {
  @tracked showButtons = true;
  @tracked start = 'now-15m';
  @tracked end = 'now';

  @action
  toggleButtons(event) {
    this.showButtons = event.target.checked;
  }

  @action
  onTimeChange({ start, end }) {
    this.start = start;
    this.end = end;
  }

  <template>
    <EuiFlexGroup @alignItems="center">
      <EuiSwitch
        @checked={{this.showButtons}}
        @onChange={{this.toggleButtons}}
        @label="Show time window buttons"
      />
    </EuiFlexGroup>
    <EuiSpacer />
    <EuiSuperDatePicker
      @start={{this.start}}
      @end={{this.end}}
      @onTimeChange={{this.onTimeChange}}
      @showTimeWindowButtons={{this.showButtons}}
      @showUpdateButton={{false}}
      @width="auto"
    />
  </template>
}
```
