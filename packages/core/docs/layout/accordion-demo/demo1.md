```hbs template
<EuiAccordion>
  <:buttonContent>
    Clickable title
  </:buttonContent>
  <:content>
    My content
  </:content>
</EuiAccordion>
<br />
<EuiTitle @size="xs">
  Accordion with
  <b>
    forceState
  </b>
</EuiTitle>
The accordion is
{{this.accordionState}}
<br />
<button type="button" {{on "click" (fn (mut this.accordionState) "open")}}>
  Open
</button>
<button type="button" {{on "click" (fn (mut this.accordionState) "closed")}}>
  Close
</button>
<EuiAccordion
  @forceState={{this.accordionState}}
  @onToggle={{if
    (eq this.accordionState "open")
    (fn (mut this.accordionState) "closed")
    (fn (mut this.accordionState) "open")
  }}
>
  <:buttonContent>
    Clickable title
  </:buttonContent>
  <:content>
    My Content
  </:content>
</EuiAccordion>
<br />
<EuiTitle @size="xs">
  Accordion with
  <b>
    isLoading = true
  </b>
</EuiTitle>
<EuiAccordion @isLoading={{true}}>
  <:buttonContent>
    "You spin my head right round"
  </:buttonContent>
  <:content>
    My content
  </:content>
</EuiAccordion>
<EuiAccordion @isLoading={{true}} @isLoadingMessage="What what">
  <:buttonContent>
    You spin my head right round also in content
  </:buttonContent>
  <:content>
    My content
  </:content>
</EuiAccordion>
<br />
<EuiTitle @size="xs">
  Accordion with
  <b>
    arrowDisplay = right
  </b>
</EuiTitle>
<EuiAccordion @arrowDisplay="right">
  <:buttonContent>
    Clickable Title
  </:buttonContent>
  <:content>
    My content
  </:content>
</EuiAccordion>
<br />

<EuiTitle @size="xs">
  Accordion with
  <b>
    arrowDisplay = left
  </b>
</EuiTitle>
<EuiAccordion @arrowDisplay="left">
  <:buttonContent>
    Clickable Title
  </:buttonContent>
  <:content>
    My content
  </:content>
</EuiAccordion>
<br />

<EuiTitle @size="xs">
  Accordion with
  <b>
    arrowDisplay = none
  </b>
</EuiTitle>
<EuiAccordion @arrowDisplay="none">
  <:buttonContent>
    Clickable Title
  </:buttonContent>
  <:content>
    My content
  </:content>
</EuiAccordion>
<br />

<EuiTitle @size="xs">Nested accordions</EuiTitle>
<EuiAccordion>
  <:buttonContent>
    Parent accordion
  </:buttonContent>
  <:content>
    Parent content
    <EuiAccordion>
      <:buttonContent>
        Child accordion
      </:buttonContent>
      <:content>
        Child content
        <EuiAccordion>
          <:buttonContent>
            Grandchild accordion
          </:buttonContent>
          <:content>
            Grandchild content
          </:content>
        </EuiAccordion>
      </:content>
    </EuiAccordion>
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
