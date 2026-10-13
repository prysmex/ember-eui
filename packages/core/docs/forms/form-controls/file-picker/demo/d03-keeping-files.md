---
order: 3
---

# Keeping the selected files

<EuiText>

Browsers don't let a file input be set programmatically. To keep showing the selection when the picker re-renders (e.g. in a multi-step form), store the files in your state and pass them back with <EuiCode>@files</EuiCode>: the prompt shows their name, or "N files selected". A new array replaces whatever the user picked since.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { EuiFilePicker, EuiButton, EuiSpacer } from '@ember-eui/core/components';

export default class KeepingFiles extends Component {
  @tracked files = [];
  @tracked step = 1;

  onChange = (fileList) => {
    this.files = fileList ? Array.from(fileList) : [];
  };

  toggleStep = () => {
    this.step = this.step === 1 ? 2 : 1;
  };

  <template>
    {{#if (this.isStep 1)}}
      <EuiFilePicker
        @multiple={{true}}
        @files={{this.files}}
        @onChange={{this.onChange}}
        @display="large"
        aria-label="Attachments"
      />
    {{else}}
      <p>Step 2: {{this.files.length}} file(s) kept in state.</p>
    {{/if}}
    <EuiSpacer />
    <EuiButton {{on "click" this.toggleStep}}>
      {{if (this.isStep 1) "Next step" "Back"}}
    </EuiButton>
  </template>

  isStep = (step) => this.step === step;
}
