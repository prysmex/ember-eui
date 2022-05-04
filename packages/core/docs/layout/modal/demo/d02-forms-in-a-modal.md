---
order: 2
---

# Forms in a modal

```hbs template
<EuiButton
  @color='primary'
  {{on 'click' this.activateModal}}
>
  Show form modal
</EuiButton>

{{#if this.isActive}}

  <EuiModal
    @onClose={{this.deactivateModal}}
  >
    <EuiModalHeader>
      <EuiTitle @size='m'>
        Modal title
      </EuiTitle>
    </EuiModalHeader>
    <EuiModalBody>
      <EuiForm>
        {{#let
          (unique-id)
          (unique-id)
          (unique-id)
          (unique-id)
        as |switchId textId rangeId selectId|}}
          <EuiFormRow @id={{switchId}}>
            <EuiSwitch
              @id={{switchId}}
              @label='Cool modal form'
              @checked={{this.switchValue}}
              @onChange={{pick 'target.checked' (set this 'switchValue')}}
            />
          </EuiFormRow>
          <EuiFormRow @label='A text field' @id={{textId}}>
            <EuiFieldText
              @value={{this.textValue}}
              @id={{textId}}
              {{on 'input' (pick 'target.value' (set this 'textValue'))}}
            />
          </EuiFormRow>
          <EuiFormRow @label='Range' @id={{textId}}>
            <EuiRange
              @min={{0}}
              @max={{10}}
              @step={{1}}
              @value={{this.rangeValue}}
              @onChange={{pick 'target.value' (set this 'rangeValue')}}
              @showLabels={{false}}
              aria-describedby={{rangeId}}
            />
            <EuiFormHelpText id={{rangeId}}>
              Some help text for the range
            </EuiFormHelpText>

          </EuiFormRow>
          <EuiFormRow @label='An EuiSuperSelect' @id={{textId}}>
            <TodoText @text='missing eui-super-select'/>
          </EuiFormRow>
        {{/let}}
      </EuiForm>
    </EuiModalBody>
    <EuiModalFooter>
      <EuiButton
        {{on 'click' this.deactivateModal}}
        @color='primary'
      >
        Cancel
      </EuiButton>
      <EuiButton
        {{on 'click' this.deactivateModal}}
        @color='primary'
        @fill={{true}}
      >
        Save
      </EuiButton>
    </EuiModalFooter>
  </EuiModal>
{{/if}}
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoModalComponent extends Component {
  @tracked isActive = false;

  @action
  activateModal(modal) {
    this.isActive = true;
  }

  @action
  deactivateModal(modal) {
    this.isActive = false;
  }

}
```
