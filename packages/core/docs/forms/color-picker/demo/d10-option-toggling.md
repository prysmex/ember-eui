---
order: 10
---

# Option toggling

<EuiText>

The switches above the color picker are docs-only helpers that toggle its display arguments.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiColorPicker, EuiFlexGroup, EuiFlexItem, EuiSwitch, EuiSpacer } from '@ember-eui/core/components';
import { fn, get } from '@ember/helper';

export default class ColorPickerTogglesDemo extends Component {
  toggles = [
    { key: 'fullWidth', label: 'fullWidth' },
    { key: 'compressed', label: 'compressed' },
    { key: 'isInvalid', label: 'isInvalid' },
    { key: 'readOnly', label: 'readOnly' },
    { key: 'disabled', label: 'disabled' },
    { key: 'isClearable', label: 'clear' },
  ];

  @tracked flags = {};
  @tracked color = '#D36086';

  @action
  toggle(key, event) {
    this.flags = { ...this.flags, [key]: event.target.checked };
  }

  @action
  setColor(text) {
    this.color = text;
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
    <EuiColorPicker
      @color={{this.color}}
      @onChange={{this.setColor}}
      @fullWidth={{this.flags.fullWidth}}
      @compressed={{this.flags.compressed}}
      @isInvalid={{this.flags.isInvalid}}
      @readOnly={{this.flags.readOnly}}
      @disabled={{this.flags.disabled}}
      @isClearable={{this.flags.isClearable}}
    />
  </template>
}
```
