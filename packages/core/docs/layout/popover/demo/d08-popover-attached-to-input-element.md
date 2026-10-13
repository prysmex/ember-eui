---
order: 8
---

# Popover attached to input element

<EuiText>
  <p>
    <strong>EuiInputPopover</strong> is a specialized popover component intended to be used with form elements. Stylistically, the popover panel is "attached" to the input. As a result, the popover will always try to set its width to match the width of the input, although this can be configured via <EuiCode>@panelMinWidth</EuiCode>.
  </p>
  <p>
    Functionally, consumers have control over what events open and close the popover, and it can allow for natural tab order. Although some assumptions are made about keyboard behavior, consumers should provide specific key event handlers depending on the use case. For instance, a <EuiCode>type=text</EuiCode> input could use the down key to trigger popover opening, but this interaction would not be appropriate for <EuiCode>type=number</EuiCode> inputs as they natively bind to the down key.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiButtonGroup, EuiFieldText, EuiFormRow, EuiInputPopover, EuiSpacer, EuiTextArea } from '@ember-eui/core/components';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

export default class PopoverDemo extends Component {
  @tracked isPopoverOpen = false;
  @tracked isResizablePopoverOpen = false;
  @tracked anchorPosition = 'downLeft';

  anchorOptions = [
    { id: 'downLeft', label: 'Left' },
    { id: 'downCenter', label: 'Center' },
    { id: 'downRight', label: 'Right' }
  ];

  @action
  openPopover() {
    this.isPopoverOpen = true;
  }

  @action
  closePopover() {
    this.isPopoverOpen = false;
  }

  @action
  closeResizablePopover() {
    this.isResizablePopoverOpen = false;
  }

  @action
  onTextAreaKeyDown(event) {
    if (event.key === 'ArrowDown') {
      event.preventDefault();
      this.isResizablePopoverOpen = true;
    }
  }

  @action
  setAnchorPosition(id) {
    this.anchorPosition = id;
  }

  <template>
    <EuiInputPopover
      @isOpen={{this.isPopoverOpen}}
      @closePopover={{this.closePopover}}
    >
      <:input>
        <EuiFieldText
          @placeholder='Focus me to toggle an input popover'
          aria-label='Popover attached to input element'
          {{on 'focus' this.openPopover}}
        />
      </:input>
      <:content>
        Popover content
      </:content>
    </EuiInputPopover>

    <EuiSpacer />

    <EuiInputPopover
      @display='inline-block'
      @isOpen={{this.isResizablePopoverOpen}}
      @closePopover={{this.closeResizablePopover}}
      @panelMinWidth={{300}}
      @anchorPosition={{this.anchorPosition}}
    >
      <:input>
        <EuiTextArea
          @placeholder='Focus me, press the down arrow key, then drag the resize handle'
          @rows={{2}}
          @resize='horizontal'
          aria-label='Press the down arrow key to toggle the popover attached to this textarea element.'
          {{on 'keydown' this.onTextAreaKeyDown}}
        />
      </:input>
      <:content>
        This popover has a minimum width of 300px, and will adjust in size as the textarea does.
        <EuiSpacer @size='s' />
        <EuiFormRow @label='Anchor position' @display='columnCompressed'>
          <EuiButtonGroup
            @buttonSize='compressed'
            @legend='Anchor position'
            @name='anchorPosition'
            @idSelected={{this.anchorPosition}}
            @onChange={{this.setAnchorPosition}}
            @options={{this.anchorOptions}}
          />
        </EuiFormRow>
      </:content>
    </EuiInputPopover>
  </template>
}
```
