---
order: 2
---

# Guided tour

<EuiText>

Users proceed through tour steps without needing to complete actions on the underlying page. In this scenario, consider showing both **Close tour** and **Next** buttons in the step's `<:footerAction>` block.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiButton, EuiButtonEmpty, EuiButtonIcon, EuiFlexGroup, EuiFlexItem, EuiPanel, EuiSpacer, EuiToolTip, EuiTour } from '@ember-eui/core/components';
import { on } from '@ember/modifier';

export default class extends Component {
  initialState = {
    currentTourStep: 1,
    isTourActive: false,
    tourPopoverWidth: 360,
    tourSubtitle: 'Demo tour',
  };

  steps = [
    { step: 1, title: 'Preview mode', content: 'See what your project looks like.', iconType: 'eye' },
    { step: 2, title: 'Build Mode', content: 'Build your project.', iconType: 'code' },
    { step: 3, title: 'Comment mode', content: 'Collaborate with your colleagues.', iconType: 'comment' },
    { step: 4, title: 'Share', content: 'Share your project.', iconType: 'share', isLast: true },
  ];

  <template>
    <EuiTour @initialState={{this.initialState}} @steps={{this.steps}} as |tour|>
      <EuiButtonEmpty @size='s' @iconType='refresh' @flush='left' {{on 'click' tour.actions.resetTour}}>
        Begin tour
      </EuiButtonEmpty>
      <EuiSpacer @size='m' />
      <EuiPanel @hasBorder={{true}} style='width: max-content'>
        <EuiFlexGroup @gutterSize='s' @responsive={{false}}>
          {{#each this.steps as |step|}}
            <EuiFlexItem @grow={{false}}>
              <tour.Step @step={{step.step}} @anchorPosition='downLeft'>
                <:default>
                  <EuiToolTip @content={{step.title}} @disableScreenReaderOutput={{true}}>
                    <EuiButtonIcon
                      @size='m'
                      @iconType={{step.iconType}}
                      @color='text'
                      aria-label={{step.title}}
                    />
                  </EuiToolTip>
                </:default>
                <:footerAction>
                  {{#if step.isLast}}
                    <EuiButton @color='success' @size='s' {{on 'click' tour.actions.finishTour}}>
                      Finish tour
                    </EuiButton>
                  {{else}}
                    <EuiButtonEmpty @size='s' @color='text' {{on 'click' tour.actions.finishTour}}>
                      Close tour
                    </EuiButtonEmpty>
                    <EuiButton @color='success' @size='s' {{on 'click' tour.actions.incrementStep}}>
                      Next
                    </EuiButton>
                  {{/if}}
                </:footerAction>
              </tour.Step>
            </EuiFlexItem>
          {{/each}}
        </EuiFlexGroup>
      </EuiPanel>
    </EuiTour>
  </template>
}
```

