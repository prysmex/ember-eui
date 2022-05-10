---
order: 10
---

# Setting an initial focus

```hbs template

<div>
  {{#let
    (unique-id)
  as |textId|}}
    <EuiPopover
      @ownFocus={{false}}
      @isOpen={{this.popover}}
      @anchorPosition='downLeft'
      @closePopover={{set this 'popover' false}}
      @initialFocus={{concat '#' textId}}
    >
      <:button>
        <EuiButton
          @iconType='arrowDown'
          @iconSide='right'
          {{on 'click' (set this 'popover' true)}}
        >
          Show popover
        </EuiButton>
      </:button>
      <:content>

        <EuiFormRow
          @label='Enter name'
          @id={{textId}}
          @hasChildLabel={{false}}
        >
          <EuiFieldText
            @value={{this.textValue}}
            @id={{textId}}
            id='hello'
            {{on 'input' (pick 'target.value' (set this 'textValue'))}}
          />
        </EuiFormRow>

        <EuiSpacer />

        <EuiButton @fill={{true}}>Submit</EuiButton>
      </:content>
    </EuiPopover>
  {{/let}}
</div>
```

```javascript component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class PopoverDemo1 extends Component {
  @tracked popover = false;
}
```
