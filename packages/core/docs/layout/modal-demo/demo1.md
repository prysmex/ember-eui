# Demo

```hbs template
<EuiTitle>
  Basic Modal
</EuiTitle>
<EuiButton
  @color='primary'
  {{on 'click' (fn this.activateModal 'basicModalActive')}}
>
  Activate Modal
</EuiButton>
{{#if this.basicModalActive}}

  <EuiModal
    @onClose={{fn this.deactivateModal 'basicModalActive'}}
    @initialFocus='#focusee'
    @maxWidth='90%'
  >
    <EuiModalHeader>
      <EuiTitle @size='m'>
        Basic Modal
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
        {{on 'click' (fn this.deactivateModal 'basicModalActive')}}
      >
        Cancel
      </EuiButtonEmpty>
      <EuiButton
        {{on 'click' (fn this.deactivateModal 'basicModalActive')}}
        @color='primary'
        @fill={{true}}
      >
        Submit
      </EuiButton>
    </EuiModalFooter>
  </EuiModal>
{{/if}}
<EuiSpacer />
<EuiTitle>
  Overflow Test
</EuiTitle>
<EuiButton
  @color='primary'
  {{on 'click' (fn this.activateModal 'overflowModalActive')}}
>
  Show Modal
</EuiButton>
{{#if this.overflowModalActive}}

  <EuiModal
    @initialFocus='#donebutton'
    @onClose={{fn this.deactivateModal 'overflowModalActive'}}
  >
    <EuiModalHeader>
      <EuiTitle @size='l'>
        Overflow Test
      </EuiTitle>
    </EuiModalHeader>
    <EuiModalBody>
      <EuiText>
        <p>
          <strong>
            Palpatine
          </strong>
          : Did you ever hear the tragedy of Darth Plagueis The Wise?
        </p>
        <p>
          <strong>
            Anakin
          </strong>
          : No.
        </p>
        <p>
          <strong>
            Palpatine
          </strong>
          : I thought not. It's not a story the Jedi would tell you. It's a Sith
          legend. Darth Plagueis was a Dark Lord of the Sith, so powerful and so
          wise he could use the Force to influence the midichlorians to create
          life… He had such a knowledge of the dark side, he could even keep the
          ones he cared about from dying.
        </p>
        <p>
          <strong>
            Anakin
          </strong>
          : He could actually save people from death?
        </p>
        <p>
          Palpatine: The dark side of the Force is a pathway to many abilities
          some consider to be unnatural.
        </p>
        <p>
          <strong>
            Anakin
          </strong>
          : What happened to him?
        </p>
        <p>
          <strong>
            Palpatine
          </strong>
          : He became so powerful… the only thing he was afraid of was losing
          his power, which eventually, of course, he did. Unfortunately, he
          taught his apprentice everything he knew, then his apprentice killed
          him in his sleep. Ironic. He could save others from death, but not
          himself.
        </p>
        <p>
          <strong>
            Anakin
          </strong>
          : Is it possible to learn this power?
        </p>
        <p>
          <strong>
            Palpatine
          </strong>
          : Not from a Jedi.
        </p>
      </EuiText>
    </EuiModalBody>
    <EuiModalFooter>
      <EuiButton
        @color='primary'
        {{on 'click' (fn this.deactivateModal 'overflowModalActive')}}
        id='donebutton'
      >
        Done
      </EuiButton>
    </EuiModalFooter>
  </EuiModal>
{{/if}}
<EuiSpacer />
<EuiTitle>
  Confirm Modal
</EuiTitle>
<EuiButton
  @color='primary'
  {{on 'click' (fn this.activateModal 'confirmModalActive')}}
>
  Show Confirm Modal
</EuiButton>
{{#if this.confirmModalActive}}
  <EuiConfirmModal
    @title='Refresh the page?'
    @onConfirm={{this.reloadPage}}
    @buttonColor='primary'
    @confirmButtonText='Refresh'
    @cancelButtonText='Cancel'
    @onCancel={{fn this.deactivateModal 'confirmModalActive'}}
  >
    <EuiText>
      This action will trash all unsaved changes
    </EuiText>
  </EuiConfirmModal>

{{/if}}
<EuiSpacer />
<EuiTitle>
  Loading Modal
</EuiTitle>
<EuiButton
  @color='primary'
  {{on 'click' (fn this.activateModal 'loadingModalActive')}}
>
  Activate Loading Modal
</EuiButton>
{{#if this.loadingModalActive}}

  <EuiConfirmModal
    @title='Refresh the page?'
    @onConfirm={{this.reloadPage}}
    @buttonColor='primary'
    @confirmButtonText='Refresh'
    @cancelButtonText='Cancel'
    @isLoading={{true}}
    @onCancel={{fn this.deactivateModal 'loadingModalActive'}}
  >
    <EuiText>
      Eui Modal with isLoading true
    </EuiText>
  </EuiConfirmModal>
{{/if}}
<EuiSpacer />
<EuiTitle>
  Widths
</EuiTitle>
<EuiButton
  @color='primary'
  {{on 'click' (fn this.activateModal 'widthModalActive')}}
>
  Show Confirm Modal
</EuiButton>
<EuiSpacer />
<EuiText>
  Modals start with a minimum width of 400px, just enough to display form rows.
  They will grow to fit the contents until it reaches the specified maxWidth,
  the default of which is set to the medium breakpoint. If the modal is not
  growing wide enough to fit your contents, you can pass a specific style.width,
  just remember that modals will always shrink to fit the window width.
</EuiText>
{{#if this.widthModalActive}}

  <EuiModal
    @onClose={{fn this.deactivateModal 'widthModalActive'}}
    @initialFocus='#focusee'
    style='width: 800px'
  >
    <EuiModalHeader>
      <EuiTitle @size='m'>
        Basic Modal
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
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoModalComponent extends Component {
  @tracked basicModalActive = false;
  @tracked overflowModalActive = false;
  @tracked confirmModalActive = false;
  @tracked widthModalActive = false;
  @tracked loadingModalActive = false;

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
