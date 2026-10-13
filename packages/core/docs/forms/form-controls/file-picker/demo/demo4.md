---
order: 4
---

# Remove files programatically

<EuiText>
  <p>
    The current file selection can be cleared programmatically by calling the <EuiCode>removeFiles</EuiCode> method on the <strong>EuiFilePicker ref</strong>.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiFlexGroup, EuiFlexItem, EuiFilePicker, EuiButton, EuiSpacer, EuiText } from '@ember-eui/core/components';
import { set } from 'ember-set-helper';
import { eq, gt } from 'ember-truth-helpers';
import { on } from '@ember/modifier';

export default class 4Demo extends Component {
  @tracked files = [];
  @tracked filePickerRef;

  onChange = (fileList) => {
    this.files = fileList;
  };

  <template>
    <EuiFlexGroup>
      <EuiFlexItem>
        <EuiFilePicker
          @ref={{set this 'filePickerRef'}}
          @multiple={{true}}
          @initialPromptText='Select or drag and drop multiple files'
          @onChange={{this.onChange}}
          @display='large'
          aria-label='Use aria labels when no actual label is in use'
        />
      </EuiFlexItem>
      <EuiFlexItem>
        <div>
          <EuiButton
            @color='danger'
            @iconType='trash'
            @disabled={{eq this.files.length 0}}
            {{on 'click' this.filePickerRef.removeFiles}}
          >
            Remove files
          </EuiButton>
        </div>
      </EuiFlexItem>
    </EuiFlexGroup>

    {{#if (gt this.files.length 0)}}
      <EuiSpacer />
      <EuiText @size="s">
        <p><strong>Files attached:</strong></p>
        <ul>
          {{#each this.files as |file|}}
            <li>{{file.name}} ({{file.size}} bytes)</li>
          {{/each}}
        </ul>
      </EuiText>
    {{/if}}
  </template>
}
```
