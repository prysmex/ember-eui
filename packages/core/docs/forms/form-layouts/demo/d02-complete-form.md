---
order: 2
---

# A complete form

<EuiText>

`EuiForm @tagName="form"` renders a `<form>`, so the submit button and the
Enter key submit it. On submit, check the values and set `@isInvalid` and
`@error` on the form (listed in a callout above it) and on each row.

</EuiText>

```hbs template
<EuiForm
  @tagName="form"
  @isInvalid={{this.showErrors}}
  @error={{this.errors}}
  @errorTitle="Please fix the following"
  {{on "submit" this.submit}}
>
  <EuiFormRow
    @label="Name"
    @isInvalid={{this.nameError}}
    @error={{this.nameError}}
  >
    <EuiFieldText
      @value={{this.name}}
      @isInvalid={{this.nameError}}
      {{on "input" (fn this.update "name")}}
    />
  </EuiFormRow>

  <EuiFormRow @label="Role">
    <EuiSelect
      @options={{this.roles}}
      @value={{this.role}}
      {{on "change" (fn this.update "role")}}
    />
  </EuiFormRow>

  <EuiFormRow @label="Bio" @helpText="Optional.">
    <EuiTextArea
      @value={{this.bio}}
      @rows={{3}}
      {{on "input" (fn this.update "bio")}}
    />
  </EuiFormRow>

  <EuiFormRow @hasChildLabel={{false}}>
    <EuiSwitch
      @label="Send me a weekly summary"
      @checked={{this.newsletter}}
      @onChange={{this.toggleNewsletter}}
    />
  </EuiFormRow>

  <EuiSpacer />
  <EuiButton @type="submit" @fill={{true}}>Save</EuiButton>
</EuiForm>

{{#if this.saved}}
  <EuiSpacer />
  <EuiCallOut @title="Saved" @color="success" @iconType="check" />
{{/if}}
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class CompleteFormDemo extends Component {
  @tracked name = '';
  @tracked role = 'viewer';
  @tracked bio = '';
  @tracked newsletter = true;
  @tracked showErrors = false;
  @tracked saved = false;

  roles = [
    { value: 'viewer', text: 'Viewer' },
    { value: 'editor', text: 'Editor' },
    { value: 'admin', text: 'Admin' },
  ];

  get nameError() {
    return this.showErrors && !this.name.trim() ? 'Enter a name.' : undefined;
  }

  get errors() {
    return [this.nameError].filter(Boolean);
  }

  @action
  update(field, event) {
    this[field] = event.target.value;
    this.saved = false;
  }

  @action
  toggleNewsletter(event) {
    this.newsletter = event.target.checked;
  }

  @action
  submit(event) {
    event.preventDefault();
    this.showErrors = true;
    this.saved = this.errors.length === 0;
  }
}
```
