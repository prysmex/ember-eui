---
order: 9
---

# Attaching to (Ember EUI extension)

<EuiText>
<p>
  If you want to attach and control the ToolTip to something programatically you
  can optionally pass an attachTo string or element and use the content named
  block, also you can pass isShown as true to show the tooltip without user
  interaction
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import { EuiButton, EuiSpacer, EuiToolTip } from '@ember-eui/core/components';
import { on } from '@ember/modifier';
import { set } from 'ember-set-helper';
import { not } from 'ember-truth-helpers';

export default class ToolTipDemo1 extends Component {
  @tracked attachTo = '#attachTo1';
  @tracked isShown = false;

  @action
  updateAttachTo(ele) {
    if (ele.target !== this.attachTo) {
      this.attachTo = ele.target;
    }
  }

  <template>
    <EuiButton
      @color='danger'
      id='attachTo1'
      {{on 'mouseenter' this.updateAttachTo}}
    >
      You can hover me, attach to 1
    </EuiButton>
    <EuiSpacer />
    <EuiButton
      @color='primary'
      id='attachTo2'
      {{on 'mouseenter' this.updateAttachTo}}
    >
      You can hover me, attach to 2
    </EuiButton>
    <EuiSpacer />
    <EuiButton
      @color='warning'
      id='attachTo3'
      {{on 'mouseenter' this.updateAttachTo}}
    >
      You can hover me, attach to 3
    </EuiButton>
    <EuiSpacer @size='xl' />
    <EuiButton {{on 'click' (set this 'isShown' (not this.isShown))}}>
      {{if this.isShown 'isShown true' 'isShown false'}}
    </EuiButton>
    <EuiSpacer />
    <EuiToolTip
      @position='top'
      @attachTo={{this.attachTo}}
      @isShown={{this.isShown}}
    >
      <:content>
        <p>
          Works on any kind of element — buttons, inputs, you name it!
        </p>
      </:content>
    </EuiToolTip>
  </template>
}
```

