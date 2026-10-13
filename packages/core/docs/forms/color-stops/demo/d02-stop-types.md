---
order: 2
---

# Stop types

<EuiText>

The same stops as `'fixed'` blocks and as 5 `'stepped'` colors. The
first one has no `@min` / `@max`, so its track follows the stops.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiFormRow, EuiColorStops } from '@ember-eui/core/components';

export default class ColorStopTypes extends Component {
  @tracked stops = [
    { stop: 10, color: '#6092C0' },
    { stop: 50, color: '#EBEFF5' },
    { stop: 90, color: '#E7664C' },
  ];

  @action
  setStops(stops) {
    this.stops = stops;
  }

  <template>
    <EuiFormRow @label="Fixed">
      <EuiColorStops
        @label="Fixed colors"
        @colorStops={{this.stops}}
        @onChange={{this.setStops}}
        @stopType="fixed"
      />
    </EuiFormRow>
    <EuiFormRow @label="Stepped">
      <EuiColorStops
        @label="Stepped colors"
        @colorStops={{this.stops}}
        @onChange={{this.setStops}}
        @stopType="stepped"
        @stepNumber={{5}}
        @min={{0}}
        @max={{100}}
      />
    </EuiFormRow>
  </template>
}
```
