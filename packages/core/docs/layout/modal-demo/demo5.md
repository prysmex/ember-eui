---
order: 5
---
```hbs template
<EuiTitle>
  Widths
</EuiTitle>
<EuiSpacer />
<EuiText>
  Modals start with a minimum width of 400px, just enough to display form rows.
  They will grow to fit the contents until it reaches the specified maxWidth,
  the default of which is set to the medium breakpoint. If the modal is not
  growing wide enough to fit your contents, you can pass a specific style.width,
  just remember that modals will always shrink to fit the window width.
</EuiText>
<EuiSpacer />
<EuiButton
  @color='primary'
  {{on 'click' (fn this.activateModal 'widthModalActive')}}
>
  Show Width Modal
</EuiButton>
{{#if this.widthModalActive}}

  <EuiModal
    @onClose={{fn this.deactivateModal 'widthModalActive'}}
    @initialFocus='#focusee'
    style='width: 800px'
  >
    <EuiModalHeader>
      <EuiTitle @size='m'>
        Basic Modal width 800 px width
      </EuiTitle>
    </EuiModalHeader>
    <EuiModalBody>
      <EuiText>
        <p>
          Hello there!
        </p>
        <p>
          This modal has many
          <a id='focusee' href='#'>
            different
          </a>
          <a href='#'>
            focusable
          </a>
          <a href='#'>
            items
          </a>
          .
        </p>
      </EuiText>
    </EuiModalBody>
    <EuiModalFooter>
      <EuiButtonEmpty
        {{on 'click' (fn this.deactivateModal 'widthModalActive')}}
      >
        Cancel
      </EuiButtonEmpty>
      <EuiButton
        {{on 'click' (fn this.deactivateModal 'widthModalActive')}}
        @color='primary'
        @fill={{true}}
      >
        Submit
      </EuiButton>
    </EuiModalFooter>
  </EuiModal>
{{/if}}
<EuiSpacer />
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoModalComponent extends Component {
  @tracked widthModalActive = false;

  @action
  activateModal(modal) {
    this[modal] = true;
  }

  @action
  deactivateModal(modal) {
    this[modal] = false;
  }

  @action
  reloadPage() {
    location.reload();
  }
}
```
