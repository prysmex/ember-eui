---
order: 2
---

# Editable with a popover

<EuiText>

Clicking the expression opens a popover to change its value. `@isActive`
keeps the solid underline while it is open; an empty value is marked
`@isInvalid`.

</EuiText>

```hbs template
<EuiPopover
  @isOpen={{this.isOpen}}
  @closePopover={{this.close}}
  @anchorPosition="downLeft"
  @ownFocus={{true}}
>
  <:button>
    <EuiExpression
      @description="is above"
      @value={{if this.threshold this.threshold "?"}}
      @isActive={{this.isOpen}}
      @isInvalid={{not this.threshold}}
      @onClick={{this.toggle}}
    />
  </:button>
  <:content>
    <EuiPopoverTitle>Is above</EuiPopoverTitle>
    <EuiFieldNumber
      @value={{this.threshold}}
      @compressed={{true}}
      aria-label="Threshold"
      {{on "input" this.setThreshold}}
    />
  </:content>
</EuiPopover>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EditableExpression extends Component {
  @tracked isOpen = false;
  @tracked threshold = '100';

  @action
  toggle() {
    this.isOpen = !this.isOpen;
  }

  @action
  close() {
    this.isOpen = false;
  }

  @action
  setThreshold(event) {
    this.threshold = event.target.value;
  }
}
```
