---
order: 4
---

# Sizing

<EuiText>

By default the `@width` of the `EuiSuperDatePicker` is set to `'restricted'` which sets the size to a reasonable max-width necessary to display full start and end date strings.

You can adjust the `@width` by passing:

- `'full'` to expand the width to 100% of the parent
- `'auto'` to grow and shrink as the contents does

The `EuiSuperDatePicker` also supports the `@compressed` form control option.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import {
  EuiFlexGroup,
  EuiFlexItem,
  EuiSelect,
  EuiSpacer,
  EuiSuperDatePicker,
  EuiSwitch,
} from '@ember-eui/core/components';

export default class SuperDatePickerSizingDemo extends Component {
  widthOptions = [
    { value: 'restricted', text: 'restricted' },
    { value: 'full', text: 'full' },
    { value: 'auto', text: 'auto' },
  ];

  @tracked compressed = false;
  @tracked width = 'restricted';
  @tracked start = 'now-30m';
  @tracked end = 'now';

  @action
  onTimeChange({ start, end }) {
    this.start = start;
    this.end = end;
  }

  @action
  setWidth(event) {
    this.width = event.target.value;
  }

  @action
  setCompressed(event) {
    this.compressed = event.target.checked;
  }

  <template>
    <EuiFlexGroup @alignItems="center">
      <EuiFlexItem @grow={{false}}>
        <EuiSelect
          @fullWidth={{true}}
          @compressed={{true}}
          @value={{this.width}}
          @options={{this.widthOptions}}
          aria-label="Super date picker width"
          {{on "change" this.setWidth}}
        >
          <:prepend as |classes|>
            <span class={{classes}}>Width</span>
          </:prepend>
        </EuiSelect>
      </EuiFlexItem>
      <EuiSwitch
        @checked={{this.compressed}}
        @onChange={{this.setCompressed}}
        @label="Compressed"
      />
    </EuiFlexGroup>
    <EuiSpacer />
    <EuiSuperDatePicker
      @start={{this.start}}
      @end={{this.end}}
      @onTimeChange={{this.onTimeChange}}
      @width={{this.width}}
      @compressed={{this.compressed}}
    />
  </template>
}
```
