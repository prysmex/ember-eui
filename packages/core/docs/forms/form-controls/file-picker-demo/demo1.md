---
order: 1
---

# Basic

<EuiText>
  <p>
    <strong>EuiFilePicker</strong> is a stylized, but generic HTML <EuiCode>input type="file"</EuiCode> tag. The example below shows how to grab the files using the <a href="https://developer.mozilla.org/en-US/docs/Web/API/FileList" target="_blank">FileList API</a>(opens in a new tab or window). Like other form elements, you can wrap it in a <strong>EuiFormRow</strong> to apply a label.
  </p>
</EuiText>

```hbs template
<EuiForm>
  {{#let (unique-id) as |inputId|}}
    <EuiFormRow
      @label='Some Input'
      @helpText="here's some help text"
      @id={{inputId}}
    >
      <EuiFilePicker @onChange={{set this 'files'}} multiple />
    </EuiFormRow>
  {{/let}}
  {{#each this.files as |file|}}
    {{file.name}}
  {{/each}}
</EuiForm>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EuiTextFieldDemo1 extends Component {
  @tracked files = [];
}
```
