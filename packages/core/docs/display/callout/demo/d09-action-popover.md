---
order: 9
---

# Action with a popover

<EuiText>

An action opens a popover with its `popoverProps`: the arguments of **EuiPopover** (`isOpen`, `closePopover`, `anchorPosition`, ...) and `children`, the popover's content as text or a component (upstream passes a React node). You control `isOpen` yourself, usually from the action's `onClick`.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiCallOut, EuiText } from '@ember-eui/core/components';

const Details = <template>
  <EuiText @size="s"><p>Reindexing takes a few minutes and does not block searches.</p></EuiText>
</template>;

export default class CallOutPopoverDemo extends Component {
  @tracked isOpen = true;

  @action
  toggle() {
    this.isOpen = !this.isOpen;
  }

  @action
  close() {
    this.isOpen = false;
  }

  get actionProps() {
    return {
      primary: {
        children: 'What happens next?',
        onClick: this.toggle,
        popoverProps: {
          isOpen: this.isOpen,
          closePopover: this.close,
          anchorPosition: 'downLeft',
          children: Details,
        },
      },
    };
  }

  <template>
    <EuiCallOut
      @title="Your index needs to be updated"
      @color="warning"
      @actionProps={{this.actionProps}}
    />
  </template>
}
```
