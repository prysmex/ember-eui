---
order: 7
---

# Loading state

Use `isLoading` to start or stop loading. While loading, the spinner replaces
extra actions in the trigger. `isLoadingMessage` separately controls whether the
expanded content shows a default or custom loading message; setting that message
to `false` keeps the content visible while the trigger still shows loading.

```hbs template
<EuiFlexGroup @alignItems="center">
  <EuiFlexItem><EuiText>isLoading:</EuiText></EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiButtonEmpty {{on 'click' (fn (mut this.isLoading) false)}}>
      False
    </EuiButtonEmpty>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiButtonEmpty {{on 'click' (fn (mut this.isLoading) true)}}>
      True
    </EuiButtonEmpty>
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer @size="s" />
<EuiFlexGroup>
  <EuiFlexItem>
    <EuiText>
      isLoadingMessage:
    </EuiText>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiButtonEmpty {{on 'click' (fn (mut this.isLoadingMessage) false)}}>
      None
    </EuiButtonEmpty>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiButtonEmpty {{on 'click' (fn (mut this.isLoadingMessage) true)}}>
      Default
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
  @isLoading={{this.isLoading}}
  @isLoadingMessage={{this.isLoadingMessage}}
  @extraAction={{true}}
>
  <:buttonContent>
    {{if this.isLoading "Loading" "Ready"}} — click to toggle
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
  @tracked isLoading = true;
  @tracked isLoadingMessage = false;
}
```
