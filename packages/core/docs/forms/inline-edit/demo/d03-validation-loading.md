---
order: 3
---

# Validation and loading

<EuiText>

`@onSave` gets the edited text. Returning `false` keeps edit mode open:
here an empty value is invalid. A returned promise keeps it open until it
resolves; `@isLoading` shows the field spinner and skeleton buttons
meanwhile.

</EuiText>

```hbs template
<EuiInlineEditText
  @inputAriaLabel="Edit the project name"
  @defaultValue="My project"
  @isInvalid={{this.isInvalid}}
  @isLoading={{this.isLoading}}
  @onSave={{this.save}}
  @onChange={{this.clearError}}
  @editModeProps={{this.editModeProps}}
/>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class InlineEditValidation extends Component {
  @tracked isInvalid = false;
  @tracked isLoading = false;

  editModeProps = {
    formRowProps: { error: 'Please enter a name' }
  };

  @action
  clearError() {
    this.isInvalid = false;
  }

  @action
  async save(value) {
    if (!value.trim()) {
      this.isInvalid = true;
      return false;
    }
    this.isLoading = true;
    await new Promise((resolve) => setTimeout(resolve, 1000));
    this.isLoading = false;
    return true;
  }
}
```
