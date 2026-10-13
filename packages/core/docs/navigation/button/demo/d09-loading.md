---
order: 9
---

# Loading

<EuiText>

Always consider the button loading state due to potential **performance slowdowns**. Set `@isLoading={{true}}` to display a loading spinner. Not handling this state can lead to extra clicks and user frustration. Setting `@isLoading` adds a spinner or swaps an existing icon for one, and disables the button. Renaming the button to "Loading…" is good practice. All button types have the same loading state.

</EuiText>

```hbs template
<EuiSwitch @compressed={{true}} @label="Is loading" @checked={{this.loadingButton}} @onChange={{this.toggle}} />
<EuiSpacer />
<EuiButton @isLoading={{this.loadingButton}} @fill={{true}}>
  {{if this.loadingButton "Loading..." "Button"}}
</EuiButton>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoComponent extends Component {
  @tracked loadingButton = true;

  @action
  toggle() {
    this.loadingButton = !this.loadingButton;
  }
}
```
