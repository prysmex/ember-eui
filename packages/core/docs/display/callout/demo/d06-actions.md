---
order: 6
---

# Actions

<EuiText>

Use `@actionProps` to add up to two actions to a callout. The `primary` action renders as an **EuiButton** and the `secondary` action renders as an **EuiButtonEmpty**. Color and size are automatically matched to the callout and can't be customized. An action takes `children` (its text), `onClick`, `href`, `target`, `iconType`, `isDisabled`, `isLoading`, `className`, `data-test-subj`, `tooltipProps` (the arguments of **EuiToolTip**) and `popoverProps` (the arguments of **EuiPopover**, plus `children`, its content as text or a component). When both are set, the tooltip sits inside the popover, as upstream.

A secondary action can be provided on its own, but most commonly is paired with a primary action.

For other buttons, or anything custom, use the `<:actions>` block: it renders after the actions from `@actionProps`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiButton, EuiCallOut, EuiSpacer } from '@ember-eui/core/components';

export default class CallOutActionsDemo extends Component {
  noop = () => {};

  updateActions = {
    primary: { children: 'Update now', onClick: this.noop },
    secondary: { children: 'Learn more', href: '#' },
  };

  sessionActions = {
    primary: { children: 'Stay signed in', onClick: this.noop },
  };

  <template>
    <EuiCallOut
      @title="Your index needs to be updated"
      @color="warning"
      @text="This operation may take a few minutes. You can continue using the app while it runs."
      @actionProps={{this.updateActions}}
    />

    <EuiSpacer />

    <EuiCallOut
      @title="Your session is about to expire"
      @color="danger"
      @actionProps={{this.sessionActions}}
    />

    <EuiSpacer />

    <EuiCallOut @title="Custom actions through the block" @color="success">
      <:actions>
        <EuiButton @size="s" @color="success" @fill={{true}}>Continue</EuiButton>
      </:actions>
    </EuiCallOut>
  </template>
}
```
