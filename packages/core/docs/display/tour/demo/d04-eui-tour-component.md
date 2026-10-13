---
order: 4
---

# EuiTour component

<EuiText>

The `EuiTour` component provides minimal state management. It yields `Step` (an `EuiTourStep` wired to the tour), `actions` (`finishTour`, `resetTour`, `incrementStep`, `decrementStep`, `goToStep`) and the current `state`. Upstream's `useEuiTour` hook and `EuiTour` render prop component are both covered by this one component.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiButton, EuiButtonEmpty, EuiCodeBlock, EuiForm, EuiFormRow, EuiSpacer, EuiText, EuiTextArea, EuiTour } from '@ember-eui/core/components';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';

export default class extends Component {
  @tracked queryValue = '';

  initialState = {
    currentTourStep: 1,
    isTourActive: false,
    tourPopoverWidth: 360,
    tourSubtitle: 'Demo tour',
  };

  steps = [
    { step: 1, title: 'Step 1' },
    { step: 2, title: 'Step 2', content: 'Save your changes.' },
  ];

  @action
  resetTour(tour) {
    tour.actions.resetTour();
    this.queryValue = '';
  }

  @action
  onChange(tour, event) {
    this.queryValue = event.target.value;

    if (tour.state.currentTourStep < 2) {
      tour.actions.incrementStep();
    }
  }

  <template>
    <EuiTour @steps={{this.steps}} @initialState={{this.initialState}} as |tour|>
      <EuiButtonEmpty @size='s' @iconType='refresh' @flush='left' {{on 'click' (fn this.resetTour tour)}}>
        Begin tour
      </EuiButtonEmpty>
      <EuiSpacer @size='m' />
      <EuiForm @component='form'>
        <EuiFormRow @label='Query'>
          <tour.Step @step={{1}} @anchorPosition='rightUp'>
            <:default>
              <EuiTextArea
                @value={{this.queryValue}}
                placeholder='Placeholder text'
                aria-label='Query'
                style='width: 400px'
                {{on 'input' (fn this.onChange tour)}}
              />
            </:default>
            <:content>
              <EuiText @size='s'>
                <p>Copy and paste this sample query.</p>
                <EuiCodeBlock @language='html' @paddingSize='s' @isCopyable={{true}}>SELECT email FROM "kibana_sample_data_ecommerce"</EuiCodeBlock>
              </EuiText>
            </:content>
          </tour.Step>
        </EuiFormRow>

        <EuiSpacer @size='m' />

        <tour.Step @step={{2}} @anchorPosition='rightUp'>
          <EuiButton @fill={{true}} @size='s' {{on 'click' tour.actions.finishTour}}>Save</EuiButton>
        </tour.Step>
      </EuiForm>
    </EuiTour>
  </template>
}
```

