---
order: 7
---

# Kitchen sink

<EuiText>

Other alterations you can add to the range are `@fullWidth` and `@disabled`. The switches above each range are docs-only helpers that toggle the display arguments.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { fn, get } from '@ember/helper';
import {
  EuiDualRange,
  EuiFlexGroup,
  EuiFlexItem,
  EuiRange,
  EuiSpacer,
  EuiSwitch,
} from '@ember-eui/core/components';

export default class RangeKitchenSinkDemo extends Component {
  toggles = [
    { key: 'fullWidth', label: 'fullWidth' },
    { key: 'compressed', label: 'compressed' },
    { key: 'isInvalid', label: 'isInvalid' },
    { key: 'disabled', label: 'disabled' },
  ];

  levels = [
    { min: 0, max: 20, color: 'danger' },
    { min: 20, max: 100, color: 'success' },
  ];

  ticks = [
    { label: '20kb', value: 20 },
    { label: '100kb', value: 100 },
  ];

  @tracked flags = {};
  @tracked dualFlags = {};
  @tracked value = '20';
  @tracked dualValue = [20, 100];

  @action
  toggle(key, event) {
    this.flags = { ...this.flags, [key]: event.target.checked };
  }

  @action
  toggleDual(key, event) {
    this.dualFlags = { ...this.dualFlags, [key]: event.target.checked };
  }

  @action
  onChange(event) {
    this.value = event.target.value;
  }

  @action
  onDualChange(value) {
    this.dualValue = value;
  }

  <template>
    <EuiFlexGroup @wrap={{true}} @gutterSize="m" @responsive={{false}}>
      {{#each this.toggles as |toggle|}}
        <EuiFlexItem @grow={{false}}>
          <EuiSwitch
            @label={{toggle.label}}
            @compressed={{true}}
            @checked={{get this.flags toggle.key}}
            @onChange={{fn this.toggle toggle.key}}
          />
        </EuiFlexItem>
      {{/each}}
    </EuiFlexGroup>
    <EuiSpacer @size="m" />
    <EuiRange
      aria-label="An example of EuiRange"
      @min={{0}}
      @max={{100}}
      @value={{this.value}}
      @onChange={{this.onChange}}
      @showTicks={{true}}
      @showInput={{true}}
      @showLabels={{true}}
      @showValue={{true}}
      @showRange={{true}}
      @tickInterval={{20}}
      @levels={{this.levels}}
      @fullWidth={{this.flags.fullWidth}}
      @compressed={{this.flags.compressed}}
      @isInvalid={{this.flags.isInvalid}}
      @disabled={{this.flags.disabled}}
    />

    <EuiSpacer @size="xl" />

    <EuiFlexGroup @wrap={{true}} @gutterSize="m" @responsive={{false}}>
      {{#each this.toggles as |toggle|}}
        <EuiFlexItem @grow={{false}}>
          <EuiSwitch
            @label={{toggle.label}}
            @compressed={{true}}
            @checked={{get this.dualFlags toggle.key}}
            @onChange={{fn this.toggleDual toggle.key}}
          />
        </EuiFlexItem>
      {{/each}}
    </EuiFlexGroup>
    <EuiSpacer @size="m" />
    <EuiDualRange
      aria-label="An example of EuiDualRange"
      @min={{0}}
      @max={{100}}
      @value={{this.dualValue}}
      @onChange={{this.onDualChange}}
      @showLabels={{true}}
      @showInput={{true}}
      @showTicks={{true}}
      @ticks={{this.ticks}}
      @levels={{this.levels}}
      @fullWidth={{this.dualFlags.fullWidth}}
      @compressed={{this.dualFlags.compressed}}
      @isInvalid={{this.dualFlags.isInvalid}}
      @disabled={{this.dualFlags.disabled}}
    />
  </template>
}
```
