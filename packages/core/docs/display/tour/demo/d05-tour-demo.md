---
order: 5
---

# Tour demo

<EuiText>

A complete tour set in a more realistic application UI. Unlike the upstream examples, none of the examples on this page persist their state in `localStorage`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiButton, EuiButtonEmpty, EuiColorPicker, EuiSpacer, EuiStat, EuiTab, EuiTabs, EuiText, EuiTextArea, EuiTour } from '@ember-eui/core/components';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { eq } from 'ember-truth-helpers';

export default class extends Component {
  @tracked color = '#000';
  @tracked selectedTabId = 'query';

  initialState = {
    currentTourStep: 1,
    isTourActive: true,
    tourPopoverWidth: 360,
    tourSubtitle: 'Demo tour',
  };

  steps = [
    { step: 1, title: 'Step 1' },
    { step: 2, title: 'Step 2', content: 'What is your favorite color?' },
    { step: 3, title: 'Step 3', content: 'Click here for more cool things.' },
    { step: 4, title: 'Step 4' },
  ];

  @action
  onSelectColor(tour, color) {
    this.color = color;
    if (tour.state.currentTourStep === 2) {
      tour.actions.goToStep(3);
    }
  }

  @action
  onTabClick(tour, id) {
    if (id === 'stat' && tour.state.currentTourStep === 3) {
      tour.actions.goToStep(4);
    }
    this.selectedTabId = id;
  }

  @action
  onReset(tour) {
    tour.actions.resetTour();
    this.selectedTabId = 'query';
  }

  <template>
    <EuiTour @steps={{this.steps}} @initialState={{this.initialState}} as |tour|>
      <EuiTabs>
        <EuiTab
          @isSelected={{eq this.selectedTabId 'query'}}
          {{on 'click' (fn this.onTabClick tour 'query')}}
        >
          Query
        </EuiTab>
        <EuiTab
          @isSelected={{eq this.selectedTabId 'stat'}}
          {{on 'click' (fn this.onTabClick tour 'stat')}}
        >
          <tour.Step @step={{3}} @anchorPosition='downRight'>
            <span>Stats</span>
          </tour.Step>
        </EuiTab>
      </EuiTabs>

      {{#if (eq this.selectedTabId 'query')}}
        <EuiSpacer />
        <tour.Step @step={{1}}>
          <:default>
            <EuiTextArea
              placeholder='Placeholder text'
              aria-label='Enter ES SQL query'
              style='width: 400px'
            />
          </:default>
          <:content>
            <EuiText @size='s'>
              <p>This is a neat thing. You enter queries here.</p>
              <EuiButton @color='primary' {{on 'click' tour.actions.incrementStep}}>
                Ok, got it.
              </EuiButton>
            </EuiText>
          </:content>
        </tour.Step>

        <EuiSpacer />

        <tour.Step @step={{2}} @anchorPosition='upCenter'>
          <:default>
            <EuiColorPicker
              @mode='swatch'
              @color={{this.color}}
              @onChange={{fn this.onSelectColor tour}}
            />
          </:default>
          <:footerAction>
            <EuiButtonEmpty
              @color='text'
              @flush='right'
              @size='xs'
              {{on 'click' tour.actions.incrementStep}}
            >
              I don't have a favorite color
            </EuiButtonEmpty>
          </:footerAction>
        </tour.Step>
      {{else}}
        <EuiSpacer />
        <tour.Step @step={{4}} @anchorPosition='downLeft' @decoration='none'>
          <:default>
            <div>
              <EuiStat @title='22,123' @description='Queries' />
            </div>
          </:default>
          <:content>
            <EuiText @size='s'>
              <p>That about does it.</p>
              <EuiButton @color='primary' {{on 'click' (fn this.onReset tour)}}>
                Take me to the start.
              </EuiButton>
            </EuiText>
          </:content>
        </tour.Step>
      {{/if}}
    </EuiTour>
  </template>
}
```

