---
order: 1
---

# Focus trap

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import {
  EuiBadge,
  EuiButton,
  EuiFieldText,
  EuiFocusTrap,
  EuiFormRow,
  EuiPanel,
  EuiSpacer,
  EuiText
} from '@ember-eui/core/components';

export default class FocusTrapDemo extends Component {
  @tracked isDisabled = true;

  @action
  toggleDisabled() {
    this.isDisabled = !this.isDisabled;
  }

  <template>
    <div>
      <EuiBadge>Trap is {{if this.isDisabled 'disabled' 'enabled'}}</EuiBadge>
      <EuiSpacer @size='s' />
      <EuiFocusTrap @disabled={{this.isDisabled}}>
        <EuiPanel>
          <EuiFormRow @label='First name'><EuiFieldText /></EuiFormRow>
          <EuiFormRow @label='Last name'><EuiFieldText /></EuiFormRow>
          <EuiSpacer @size='m' />
          <EuiButton {{on 'click' this.toggleDisabled}}>
            {{if this.isDisabled 'Enable' 'Disable'}}
            Focus Trap
          </EuiButton>
        </EuiPanel>
      </EuiFocusTrap>
      <EuiSpacer @size='l' />
      <EuiText>
        The button below is not focusable by keyboard as long as the focus trap is enabled.
      </EuiText>
      <EuiButton>External Focusable Element</EuiButton>
    </div>
  </template>
}
```
