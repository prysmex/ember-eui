---
order: 6
---

# Actions

<EuiText>

Use the `<:actions>` block to add up to two actions to a callout: a primary `EuiButton` and a secondary `EuiButtonEmpty` (both `@size="s"`, with the `@color` of the callout). Upstream configures these through an `actionProps` argument, which Ember EUI replaces with the block.

A secondary action can be provided on its own, but most commonly is paired with a primary action.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiButton, EuiButtonEmpty, EuiCallOut, EuiSpacer } from '@ember-eui/core/components';
import { on } from '@ember/modifier';

export default class CallOutActionsDemo extends Component {
  noop = () => {};

  <template>
    <EuiCallOut
      @title="Your index needs to be updated"
      @color="warning"
      @text="This operation may take a few minutes. You can continue using the app while it runs."
    >
      <:actions>
        <EuiButton @size="s" @color="warning" @fill={{true}} {{on "click" this.noop}}>
          Update now
        </EuiButton>
        <EuiButtonEmpty @size="s" @color="warning" @href="#">Learn more</EuiButtonEmpty>
      </:actions>
    </EuiCallOut>

    <EuiSpacer />

    <EuiCallOut @title="Your session is about to expire" @color="danger">
      <:actions>
        <EuiButton @size="s" @color="danger" @fill={{true}} {{on "click" this.noop}}>
          Stay signed in
        </EuiButton>
      </:actions>
    </EuiCallOut>
  </template>
}
```

