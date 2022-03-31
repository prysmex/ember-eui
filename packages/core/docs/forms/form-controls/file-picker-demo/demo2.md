---
order: 2
---

# Remove files programatically

```hbs template
<EuiFlexGroup>
  <EuiFlexItem>
    <EuiFilePicker
      @ref={{set this 'filePickerRef'}}
      multiple
      @initialPromptText='Select or drag and drop multiple files'
      @onChange={{this.onChange}}
      @display='default'
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
        <h3>Remove files</h3>
      </EuiButton>
    </div>
  </EuiFlexItem>
</EuiFlexGroup>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EuiTextFieldDemo1 extends Component {
  @tracked files = [];
  @tracked filePickerRef;

  onChange = (fileList) => {
    this.files = fileList;
  };
}
```
