---
order: 8
---

# Interactive content in the trigger

<EuiText>
  <p>
  Passing interactive content like links, buttons, or form elements as the
  <EuiCode>buttonContent</EuiCode>, will cause issues with the wrapping button
  element. To fix this, you can change this wrapping element to a div using
  <EuiCode>buttonElement="div"</EuiCode>.
  </p>
  <p>
  If you don't want the interactive content to trigger the accordion expansion,
  you will have to apply
  <EuiCode>e.stopPropagation</EuiCode>
  to your element manually.
  </p>
</EuiText>

```hbs template
<EuiCallOut @iconType='accessibility' @color='warning'>
  <:body>
    <EuiText>
      Accordions need a focusable button for accessibility, so changing the
      element to anything other than a button will enforce the display of the
      arrow.
    </EuiText>
  </:body>
</EuiCallOut>
<EuiSpacer />
<EuiAccordion @paddingSize='s' @buttonElement="div">
  <:buttonContent>
    <EuiText
      onClick={{this.onClick}}
      href='#/layout/accordion#interactive-content-in-the-trigger'
    >
      This is a nested link
    </EuiText>
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
import { action } from '@ember/object';

export default class AccordionDemo8Component extends Component {

  @action
  onClick(e) {
    e.stopPropagation();
  }
}
```
