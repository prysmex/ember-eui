---
order: 1
---

# File picker

<EuiText>

`EuiFilePicker` is a stylized, but generic HTML `<input type="file">` tag. It supports drag and drop as well as on click style selection of files. The example below shows how to grab the files using the [FileList API](https://developer.mozilla.org/en-US/docs/Web/API/FileList). Like other form elements, you can wrap it in an `EuiFormRow` to apply a label.

The switches above the picker are docs-only helpers that toggle its display arguments.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { fn, get } from '@ember/helper';
import {
  EuiFilePicker,
  EuiFlexGroup,
  EuiFlexItem,
  EuiSpacer,
  EuiSwitch,
  EuiText,
} from '@ember-eui/core/components';

export default class FilePickerDemo extends Component {
  toggles = [
    { key: 'fullWidth', label: 'fullWidth' },
    { key: 'compressed', label: 'compressed' },
    { key: 'isInvalid', label: 'isInvalid' },
    { key: 'isLoading', label: 'isLoading' },
    { key: 'disabled', label: 'disabled' },
    { key: 'large', label: 'large' },
  ];

  @tracked flags = { large: true };
  @tracked files = [];

  get display() {
    return this.flags.large ? 'large' : 'default';
  }

  @action
  toggle(key, event) {
    this.flags = { ...this.flags, [key]: event.target.checked };
  }

  @action
  onChange(files) {
    this.files = files && files.length > 0 ? Array.from(files) : [];
  }

  <template>
    <EuiFlexGroup>
      <EuiFlexItem @grow={{2}}>
        <EuiFlexGroup @wrap={{true}} @gutterSize="m" @responsive={{false}}>
          {{#each this.toggles as |toggle|}}
            <EuiFlexItem @grow={{false}}>
              <EuiSwitch
                @label={{toggle.label}}
                @compressed={{true}}
                @checked={{get this.flags toggle.key}}
                @onChange={{fn this.toggle toggle.key}}
              />
            </EuiFlexItem>
          {{/each}}
        </EuiFlexGroup>
        <EuiSpacer @size="m" />
        <EuiFilePicker
          @multiple={{true}}
          @initialPromptText="Select or drag and drop multiple files"
          @onChange={{this.onChange}}
          @display={{this.display}}
          @fullWidth={{this.flags.fullWidth}}
          @compressed={{this.flags.compressed}}
          @isInvalid={{this.flags.isInvalid}}
          @isLoading={{this.flags.isLoading}}
          @disabled={{this.flags.disabled}}
          aria-label="Use aria labels when no actual label is in use"
        />
        <EuiSpacer />
      </EuiFlexItem>
      <EuiFlexItem>
        <EuiText>
          <h3>Files attached</h3>
          {{#if this.files.length}}
            <ul>
              {{#each this.files as |file|}}
                <li><strong>{{file.name}}</strong> ({{file.size}} bytes)</li>
              {{/each}}
            </ul>
          {{else}}
            <p>Add some files to see a demo of retrieving from the FileList</p>
          {{/if}}
        </EuiText>
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```
