---
order: 1
---

# Wrap target element

<EuiText>

The `EuiTourStep` component is the base for building a feature tour or an individual popover for onboarding.

All content and actions including titles, headings, and buttons are customizable via arguments and blocks.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiButtonEmpty, EuiFieldText, EuiSpacer, EuiText, EuiTourStep } from '@ember-eui/core/components';
import { on } from '@ember/modifier';

export default class extends Component {
  @tracked isOpen = false;

  @action
  beginTour() {
    this.isOpen = true;
  }

  @action
  finish() {
    this.isOpen = false;
  }

  <template>
    <div>
      <EuiButtonEmpty @size='s' @flush='left' @iconType='refresh' {{on 'click' this.beginTour}}>
        Begin tour
      </EuiButtonEmpty>
      <EuiSpacer @size='m' />
      <EuiTourStep
        @isStepOpen={{this.isOpen}}
        @minWidth={{300}}
        @onFinish={{this.finish}}
        @closePopover={{this.finish}}
        @step={{1}}
        @stepsTotal={{1}}
        @title='Title of the current step'
        @subtitle='Title of the full tour (optional)'
        @anchorPosition='rightCenter'
      >
        <:default>
          <EuiFieldText @placeholder='Placeholder text' />
        </:default>
        <:content>
          <EuiText @size='s'>
            <p>The tour step content.</p>
          </EuiText>
        </:content>
      </EuiTourStep>
    </div>
  </template>
}
```

