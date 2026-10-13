---
order: 19
---

# Collapsing to the quick select

<EuiText>

`@quickSelectButtonProps` are spread over the quick select button, like upstream's `quickSelectButtonProps`: `aria-label`, `data-test-subj`, `label`, `iconLeft`, `iconRight`, `className`, and `on*` handlers such as `onClick` or `onMouseDown` (they run as event listeners; `onClick` runs after the popover toggles).

This example, from upstream's stories, collapses the picker to the quick select while the field has the focus, and expands it again from the quick select button's `onClick`. The quick select popover stays open while the picker expands.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import {
  EuiFieldText,
  EuiFlexGroup,
  EuiFlexItem,
  EuiSuperDatePicker,
} from '@ember-eui/core/components';

export default class SuperDatePickerQuickSelectOnlyDemo extends Component {
  @tracked isCollapsed = false;
  @tracked start = '2025-01-01T00:00:00.000Z';
  @tracked end = 'now';

  quickSelectButtonProps = {
    onClick: () => {
      this.isCollapsed = false;
    },
  };

  @action
  collapse() {
    this.isCollapsed = true;
  }

  @action
  expand() {
    this.isCollapsed = false;
  }

  @action
  onTimeChange({ start, end }) {
    this.start = start;
    this.end = end;
  }

  <template>
    <EuiFlexGroup>
      <EuiFlexItem>
        <EuiFieldText
          aria-label="Search"
          placeholder="Focus me to collapse the picker"
          {{on "focus" this.collapse}}
          {{on "blur" this.expand}}
        />
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiSuperDatePicker
          @start={{this.start}}
          @end={{this.end}}
          @onTimeChange={{this.onTimeChange}}
          @isQuickSelectOnly={{this.isCollapsed}}
          @quickSelectButtonProps={{this.quickSelectButtonProps}}
        />
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```
