---
order: 5
---

# Countdown animation

<EuiText>

To show a countdown animation on top of the toast to indicate the remaining time until it dismisses, use `@animationMs`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiButton, EuiFlexGroup, EuiToast } from '@ember-eui/core/components';
import { on } from '@ember/modifier';

const ANIMATION_MS = 6000;

export default class extends Component {
  @tracked animationMs = ANIMATION_MS;

  noop = () => {};

  get buttonLabel() {
    return this.animationMs != null ? 'Reset animation' : 'Start animation';
  }

  @action
  toggleAnimation() {
    this.animationMs = this.animationMs != null ? undefined : ANIMATION_MS;
  }

  <template>
    <div style='max-width: 320px'>
      <EuiFlexGroup @direction='column' @gutterSize='m'>
        <EuiButton style='max-inline-size: max-content' {{on 'click' this.toggleAnimation}}>
          {{this.buttonLabel}}
        </EuiButton>
        <EuiToast
          @title='Your report is complete'
          @color='success'
          @body='A short toast text'
          @animationMs={{this.animationMs}}
          @onClose={{this.noop}}
        />
      </EuiFlexGroup>
    </div>
  </template>
}
```

