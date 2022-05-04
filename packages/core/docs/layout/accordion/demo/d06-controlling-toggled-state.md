---
order: 6
---

# Controlling toggled state

<EuiText>
  Typically, the open and closed state of
  <strong>EuiAccordion</strong>
  is maintained by the component's internal state. Though, you can manually
  control it.
  <ul>
    <li><EuiCode>forceState</EuiCode>: Accepts either
      <EuiCode>'open'</EuiCode>
      or
      <EuiCode>'closed'</EuiCode>.</li>
    <li><EuiCode>onToggle</EuiCode>: A callback function returning
      <EuiCode>true</EuiCode>
      if the accordion is open</li>
  </ul>
</EuiText>

```hbs template
<EuiFlexGroup>
  <EuiFlexItem>
    <EuiButton {{on 'click' (fn (mut this.accordionState) 'open')}}>
      Open
    </EuiButton>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiButton {{on 'click' (fn (mut this.accordionState) 'closed')}}>
      Close
    </EuiButton>
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer />
<EuiAccordion
  @forceState={{this.accordionState}}
  @onToggle={{if
    (eq this.accordionState 'open')
    (fn (mut this.accordionState) 'closed')
    (fn (mut this.accordionState) 'open')
  }}
>
  <:buttonContent>
    I am a controlled accordion
  </:buttonContent>
  <:content>
    <EuiPanel @color='subdued'>
      Any content inside of
      <strong>EuiAccordion</strong>
      will appear here.
    </EuiPanel>
  </:content>
</EuiAccordion>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class AccordionDemo1Component extends Component {
  @tracked accordionState = false;
}
```
