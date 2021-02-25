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
<h1>
  Accordion with
  <b>
    forceState
  </b>
</h1>
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
<h1>
  Accordion with
  <b>
    isLoading = true
  </b>
</h1>
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
<h1>
  Accordion with
  <b>
    arrowDisplay = left
  </b>
</h1>
<EuiAccordion @arrowDisplay="right">
  <:buttonContent>
    Clickable Title
  </:buttonContent>
  <:content>
    My content
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
