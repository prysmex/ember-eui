---
order: 2
---

# Error handling and feedback

<EuiText>

The <EuiCode>@errors</EuiCode> argument allows you to pass an array of errors if syntax is malformed. The below example starts with an incomplete tooltip tag, showing this error message by default. These errors are meant to be ephemeral and part of the editing experience. They should not be a substitute for form validation.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { guidFor } from '@ember/object/internals';
import { EuiButton, EuiCodeBlock, EuiFormErrorText, EuiMarkdownEditor, EuiSpacer } from '@ember-eui/core/components';
import { on } from '@ember/modifier';

export default class EditorErrors extends Component {
  errorElementId = `${guidFor(this)}-errors`;

  @tracked value = `## Errors

The tooltip is empty and will error

!{tooltip[]()}
`;
  @tracked messages = [];
  @tracked ast = '';
  @tracked isAstShowing = false;

  @action setValue(value) {
    this.value = value;
  }

  @action onParse(err, { messages, ast }) {
    this.messages = err ? [err] : messages;
    this.ast = JSON.stringify(ast, null, 2);
  }

  @action toggleAst() {
    this.isAstShowing = !this.isAstShowing;
  }

  <template>
    <EuiMarkdownEditor
      @ariaLabel='EUI markdown editor demo'
      @ariaDescribedBy={{this.errorElementId}}
      @placeholder='Your markdown here...'
      @value={{this.value}}
      @onChange={{this.setValue}}
      @height={{400}}
      @onParse={{this.onParse}}
      @errors={{this.messages}}
    />
    <EuiSpacer @size='s' />
    <EuiFormErrorText id={{this.errorElementId}}>
      Utilize error text or
      <strong>EuiFormRow</strong>
      for more permanent error feedback
    </EuiFormErrorText>
    <div class='eui-textRight'>
      <EuiButton
        @size='s'
        @iconType={{if this.isAstShowing 'eyeClosed' 'eye'}}
        @fill={{this.isAstShowing}}
        {{on 'click' this.toggleAst}}
      >
        {{if this.isAstShowing 'Hide editor AST' 'Show editor AST'}}
      </EuiButton>
    </div>
    {{#if this.isAstShowing}}
      <EuiCodeBlock @language='json'>{{this.ast}}</EuiCodeBlock>
    {{/if}}
  </template>
}
```

