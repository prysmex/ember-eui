---
order: 1
---

# Tracking mouse position

<EuiText>

Toggle the switch to track the mouse position. When it is off the listener is removed.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import {
  EuiDescriptionList,
  EuiSpacer,
  EuiSwitch,
  EuiWindowEvent
} from '@ember-eui/core/components';

export default class WindowEventDemo extends Component {
  @tracked tracking = false;
  @tracked clientX = null;
  @tracked clientY = null;

  @action
  onSwitchChange() {
    this.tracking = !this.tracking;
  }

  @action
  onMouseMove({ clientX, clientY }) {
    this.clientX = clientX;
    this.clientY = clientY;
  }

  get listItems() {
    return [
      { title: 'Position X', description: this.clientX ?? '??' },
      { title: 'Position Y', description: this.clientY ?? '??' }
    ];
  }

  <template>
    <div>
      <EuiSwitch
        @label='Track mouse position'
        @checked={{this.tracking}}
        @onChange={{this.onSwitchChange}}
      />
      {{#if this.tracking}}
        <EuiWindowEvent @event='mousemove' @handler={{this.onMouseMove}} />
      {{/if}}
      <EuiSpacer @size='l' />
      <EuiDescriptionList @listItems={{this.listItems}} />
    </div>
  </template>
}
```
