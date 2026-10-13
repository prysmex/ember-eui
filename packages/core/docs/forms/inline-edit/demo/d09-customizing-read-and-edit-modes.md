---
order: 9
---

# Customizing read and edit modes

<EuiText>

Customize the read mode by passing `@readModeProps`, which accepts `onClick`, `buttonRef`, `title`, `aria-describedby`, `data-test-subj`, `color` and `iconSide` for the read mode button.

Customize the edit mode by passing `@editModeProps`. This argument contains nested object properties that are applied to various child components in edit mode:

- `formRowProps` accepts `error`, `helpText` and `data-test-subj` for the `EuiFormRow`
- `inputProps` accepts `onChange`, `onKeyDown`, `inputRef`, `aria-describedby`, `name`, `maxLength`, `readOnly`, `prepend`, `append` and `data-test-subj` for the `EuiFieldText`. `prepend` and `append` take text (shown in an `EuiFormLabel`) or a component
- `saveButtonProps` accepts `onClick`, `aria-label`, `title`, `color`, `display`, `iconType`, `isDisabled` and `data-test-subj` for the save `EuiButtonIcon`
- `cancelButtonProps` accepts the same for the cancel `EuiButtonIcon`

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiInlineEditText } from '@ember-eui/core/components';

export default class InlineEditCustomizeDemo extends Component {
  readModeProps = {
    title: 'Click to edit',
    color: 'primary',
    iconSide: 'left',
  };

  editModeProps = {
    inputProps: {
      prepend: 'Prepend example',
    },
    formRowProps: {
      helpText: 'Example help text',
    },
    saveButtonProps: {
      color: 'primary',
    },
    cancelButtonProps: {
      display: 'empty',
    },
  };

  <template>
    <EuiInlineEditText
      @inputAriaLabel="Edit text inline for readMode and editMode props"
      @defaultValue="This inline edit component has been customized!"
      @readModeProps={{this.readModeProps}}
      @editModeProps={{this.editModeProps}}
    />
  </template>
}
```
