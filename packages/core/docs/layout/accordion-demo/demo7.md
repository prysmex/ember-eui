---
order: 7
---

```hbs template
<EuiTitle>
  Loading state
</EuiTitle>
<EuiSpacer />
<EuiText>
  Use the
  <EuiCode>isLoading</EuiCode>
  prop when not all of the accordion's content is ready yet. When using
  <EuiCode>isLoading</EuiCode>, the content of
  <EuiCode>extraAction</EuiCode>
  is replaced with a loading spinner.<br /><br />
  Manage the content of the accordion using
  <EuiCode>isLoadingMessage</EuiCode>. By default, it is set to
  <EuiCode>false</EuiCode>
  and the content will remain unaltered. Set it to
  <EuiCode>true</EuiCode>
  to show a default loading message or pass a node to show a custom loading
  message.
</EuiText>
<EuiSpacer />
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
    <EuiButton size='s'>Extra action!</EuiButton>
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
