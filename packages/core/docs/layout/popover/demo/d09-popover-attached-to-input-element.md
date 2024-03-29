---
order: 9
---

# Popover attached to input element

 <EuiText>
    <strong>EuiInputPopover</strong>
    is a specialized popover component intended to be used with form elements.
    Stylistically, the popover panel is"attached" to the input. Functionally,
    consumers have control over what events open and close the popover, and it
    can allow for natural tab order. Although some assumptions are made about
    keyboard behavior, consumers should provide specific key event handlers
    depending on the use case. For instance, a
    <EuiCode>type=text</EuiCode>
    input could use the down key to trigger popover opening, but this
    interaction would not be appropriate for
    <EuiCode>type=number</EuiCode>
    inputs as they natively bind to the down key.
  </EuiText>

```hbs template
<div>
  <EuiInputPopover
    @isOpen={{this.popover1}}
    @closePopover={{set this 'popover1' false}}
  >
    <:input>
      <EuiFieldText
        @value={{this.text1}}
        {{on 'input' (pick 'target.value' (set this 'text1'))}}
        {{on 'focus' (set this 'popover1' true)}}
      />
    </:input>
    <:content>
      Popover content
    </:content>
  </EuiInputPopover>

  <EuiSpacer @size='l' />

  <EuiInputPopover
    @isOpen={{this.popover2}}
    @closePopover={{set this 'popover2' false}}
  >
    <:input>
      <EuiFieldText
        @value={{this.text2}}
        style={{concat 'width: ' this.width 'px'}}
        {{on 'input' (pick 'target.value' (set this 'text2'))}}
        {{on
          'focus'
          (queue (set this 'popover2' true) (fn this.setInputWidth 400))
        }}
        {{on 'blur' (fn this.setInputWidth 200)}}
      />
    </:input>
    <:content>
      Popover will adjust in size as the input does
    </:content>
  </EuiInputPopover>
</div>
```

```javascript component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class PopoverDemo1 extends Component {
  @tracked popover1 = false;
  @tracked popover2 = false;
  @tracked width = 200;
  @tracked text1 = '';
  @tracked text2 = '';

  @action
  setInputWidth(width) {
    this.width = width;
  }
}
```
