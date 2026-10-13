---
order: 10
---

# Interactive content in the trigger

<EuiText>
  <p>
  Passing interactive content like links, buttons, or form elements as the
  <EuiCode>@buttonContent</EuiCode>, will cause issues with the wrapping button
  element. To fix this, you can change this wrapping element to a div using
  <EuiCode>@buttonElement="div"</EuiCode>.
  </p>
  <p>
  If you don't want the interactive content to trigger the accordion expansion,
  you will have to apply
  <EuiCode>e.stopPropagation()</EuiCode>
  to your element manually.
  </p>
</EuiText>

<EuiCallOut @title="Accessibility requirement" @iconType="accessibility" @color="warning">
  Accordions need a focusable button for accessibility, so changing the
  element to anything other than a button will enforce the display of the
  arrow.
</EuiCallOut>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiAccordion, EuiLink, EuiPanel } from '@ember-eui/core/components';

export default class AccordionInteractiveTriggerComponent extends Component {

  @action
  onClick(e) {
    e.stopPropagation();
  }

  <template>
  <EuiAccordion @buttonElement="div">
    <:buttonContent>
      <EuiLink
        @href="#interactive-content-in-the-trigger"
        {{on "click" this.onClick}}
      >
        This is a nested link
      </EuiLink>
    </:buttonContent>
    <:content>
      <EuiPanel @color='subdued'>
        Any content inside of
        <strong>EuiAccordion</strong>
        will appear here.
      </EuiPanel>
    </:content>
  </EuiAccordion>
  </template>
}
```
