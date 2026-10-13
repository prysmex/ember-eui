---
order: 1
---

# Delay render

<EuiText>

<strong>EuiDelayRender</strong> is a component for conditionally toggling the visibility of a child component. It will ensure that the child is hidden for at least 500ms (default). This allows delay UI rendering. That is helpful when you need to update aria live region(s) repeatedly.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiCheckbox, EuiDelayRender, EuiFieldNumber, EuiFlexItem, EuiFormRow, EuiLoadingSpinner } from '@ember-eui/core/components';
import { on } from '@ember/modifier';

export default class DelayRender extends Component {
  @tracked minimumDelay = 3000;
  @tracked render = false;

  @action
  onChangeMinimumDelay(event) {
    this.minimumDelay = parseInt(event.target.value, 10);
  }

  @action
  onChangeRender(event) {
    this.render = event.target.checked;
  }

  <template>
    <EuiFlexItem>
      <EuiFormRow>
        <EuiCheckbox
          @id='delay-render-checkbox'
          @checked={{this.render}}
          @label='Show child'
          {{on 'change' this.onChangeRender}}
        />
      </EuiFormRow>
      <EuiFormRow @label='Minimum delay'>
        <EuiFieldNumber
          @value={{this.minimumDelay}}
          {{on 'input' this.onChangeMinimumDelay}}
        />
      </EuiFormRow>
      <EuiFormRow @label='Child ({{if this.render "showing" "hidden"}})'>
        <div>
          {{#if this.render}}
            <EuiDelayRender @delay={{this.minimumDelay}}>
              <EuiLoadingSpinner @size='m' />
            </EuiDelayRender>
          {{/if}}
        </div>
      </EuiFormRow>
    </EuiFlexItem>
  </template>
}
```

