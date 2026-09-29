---
order: 2
---

# A single step

<EuiText>

`EuiTourStep` on its own, for one hint: open it with `@isStepOpen` and
close it in `@onFinish`. `@decoration="none"` removes the beacon.

</EuiText>

```hbs template
<EuiTourStep
  @isStepOpen={{this.isOpen}}
  @title="New: dark mode"
  @anchorPosition="rightCenter"
  @decoration="none"
  @onFinish={{this.close}}
  @closePopover={{this.close}}
>
  <:default>
    <EuiButton @size="s" {{on "click" this.open}}>Show the hint</EuiButton>
  </:default>
  <:content>
    <EuiText @size="s"><p>Switch the theme from the header menu.</p></EuiText>
  </:content>
</EuiTourStep>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class StandaloneStep extends Component {
  @tracked isOpen = false;

  @action
  open() {
    this.isOpen = true;
  }

  @action
  close() {
    this.isOpen = false;
  }
}
```
