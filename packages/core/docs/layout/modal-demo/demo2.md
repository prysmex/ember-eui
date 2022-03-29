---
order: 2
---

# Overflow test

```hbs template
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
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoModalComponent extends Component {
  @tracked overflowModalActive = false;

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
