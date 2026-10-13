---
order: 4
---

# Truncation position

<EuiText>

The `startEnd` truncation type supports a `@truncationPosition` argument. By default, `startEnd` anchors the displayed text to the middle of the string. However, you may prefer to display a specific subsection of the full text closer to the start or end, which this argument allows.

This behavior will intelligently detect when positions are near enough to the start or end of the text to omit leading or trailing ellipses when necessary.

Increase or decrease the number control below to see the argument in action.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiFieldNumber, EuiFormRow, EuiPanel, EuiSpacer, EuiText, EuiTextTruncate } from '@ember-eui/core/components';
import { on } from '@ember/modifier';

export default class extends Component {
  @tracked truncationPosition = 45;

  @action
  setPosition(event) {
    this.truncationPosition = Number(event.target.value);
  }

  <template>
    <EuiText>
      <EuiFormRow @label='Truncation position'>
        <EuiFieldNumber
          @compressed={{true}}
          @value={{this.truncationPosition}}
          {{on 'input' this.setPosition}}
        />
      </EuiFormRow>
      <EuiSpacer />
      <EuiPanel style='inline-size: 40ch; max-inline-size: 100%;'>
        <EuiTextTruncate
          @text='But the dog wasn’t lazy, it was just practicing mindfulness, so it had a greater sense of life-satisfaction than that fox with all its silly jumping.'
          @truncation='startEnd'
          @truncationPosition={{this.truncationPosition}}
        />
      </EuiPanel>
    </EuiText>
  </template>
}
```

