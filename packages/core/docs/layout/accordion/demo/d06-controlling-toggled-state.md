---
order: 6
---

# Controlling toggled state

<EuiText>
  <p>
    Typically, the open and closed state of <strong>EuiAccordion</strong> is
    maintained by the component's internal state. Though, you can manually
    control it with:
  </p>
  <ul>
    <li><EuiCode>@forceState</EuiCode>: Accepts either
      <EuiCode>'open'</EuiCode> or <EuiCode>'closed'</EuiCode>.</li>
    <li><EuiCode>@onToggle</EuiCode>: A callback function receiving
      <EuiCode>true</EuiCode> if the accordion is open.</li>
  </ul>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiAccordion, EuiButtonGroup, EuiPanel, EuiSpacer } from '@ember-eui/core/components';

export default class AccordionControlledComponent extends Component {
  @tracked trigger = 'closed';
  @tracked toggleIdSelected = 'forced--closed';

  toggleButtons = [
    { id: 'forced--open', label: 'Open' },
    { id: 'forced--closed', label: 'Closed' }
  ];

  @action
  onChange(id) {
    this.trigger = id === 'forced--open' ? 'open' : 'closed';
    this.toggleIdSelected = id;
  }

  @action
  onToggle(isOpen) {
    const newState = isOpen ? 'open' : 'closed';
    this.trigger = newState;
    this.toggleIdSelected = `forced--${newState}`;
  }

  <template>
  <EuiButtonGroup
    @legend="This is a basic group"
    @options={{this.toggleButtons}}
    @idSelected={{this.toggleIdSelected}}
    @onChange={{this.onChange}}
  />
  <EuiSpacer />
  <EuiAccordion
    @id="forcedStateAccordion"
    @forceState={{this.trigger}}
    @onToggle={{this.onToggle}}
    @paddingSize="l"
  >
    <:buttonContent>
      I am a controlled accordion
    </:buttonContent>
    <:content>
      <EuiPanel @color="subdued">
        Any content inside of <strong>EuiAccordion</strong> will appear here.
      </EuiPanel>
    </:content>
  </EuiAccordion>
  </template>
}
```
