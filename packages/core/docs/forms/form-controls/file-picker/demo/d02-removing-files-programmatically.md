---
order: 2
---

# Removing files programmatically

<EuiText>

The current file selection can be cleared programmatically by calling the `removeFiles` method. Pass `@ref` to receive the component instance: `this.filePickerRef.removeFiles()`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import {
  EuiButton,
  EuiFilePicker,
  EuiFlexGroup,
  EuiFlexItem,
} from '@ember-eui/core/components';

export default class FilePickerRemoveDemo extends Component {
  @tracked files = null;
  filePickerRef = null;

  @action
  setRef(picker) {
    this.filePickerRef = picker;
  }

  @action
  onChange(files) {
    this.files = files && files.length > 0 ? files : null;
  }

  @action
  removeFiles() {
    this.filePickerRef?.removeFiles();
  }

  <template>
    <EuiFlexGroup>
      <EuiFlexItem>
        <EuiFilePicker
          @ref={{this.setRef}}
          @multiple={{true}}
          @initialPromptText="Select or drag and drop multiple files"
          @onChange={{this.onChange}}
          @display="default"
          aria-label="Use aria labels when no actual label is in use"
        />
      </EuiFlexItem>
      <EuiFlexItem>
        <div>
          <EuiButton
            @color="danger"
            @iconType="trash"
            @disabled={{if this.files false true}}
            {{on "click" this.removeFiles}}
          >
            Remove files
          </EuiButton>
        </div>
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```
