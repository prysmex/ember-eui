---
order: 7
---

# Loading state

<EuiText>

`@isLoading` replaces the `<:extraAction>` block with a spinner while the
content isn't ready. `@isLoadingMessage` replaces the content too: `true`
shows "Loading...", a string shows your own message.

</EuiText>

```hbs template
<TodoText @text="missing EuiButtonGroup component"/>
<EuiFlexGroup>
  <EuiFlexItem>
    <EuiText>
      isLoadingMessage:
    </EuiText>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiButtonEmpty {{on 'click' (fn (mut this.isLoadingMessage) false)}}>
      False
    </EuiButtonEmpty>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiButtonEmpty {{on 'click' (fn (mut this.isLoadingMessage) true)}}>
      True
    </EuiButtonEmpty>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiButtonEmpty
      {{on
        'click'
        (fn (mut this.isLoadingMessage) 'This is a custom loading message')
      }}
    >
      Custom
    </EuiButtonEmpty>
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer />
<EuiAccordion
  @isLoading={{true}}
  @isLoadingMessage={{this.isLoadingMessage}}
  @extraAction={{true}}
>
  <:buttonContent>
    Accordion is loading, click to toggle
  </:buttonContent>
  <:content>
    <EuiPanel @color='subdued'>
      Opened content
    </EuiPanel>
  </:content>
  <:extraAction>
    <EuiButton @size='s'>Extra action!</EuiButton>
  </:extraAction>
</EuiAccordion>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class AccordionDemo1Component extends Component {
  @tracked isLoadingMessage = false;
}
```
