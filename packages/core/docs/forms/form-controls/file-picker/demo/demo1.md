---
order: 1
---

# Basic file picker

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiFilePicker, EuiSpacer, EuiText } from '@ember-eui/core/components';
import { set } from 'ember-set-helper';
import { gt } from 'ember-truth-helpers';

export default class 1Demo extends Component {
  @tracked files = [];

  <template>
    <EuiFilePicker @onChange={{set this 'files'}} />

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
