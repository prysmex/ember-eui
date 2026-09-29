---
order: 1
---

# A three-step tour

<EuiText>

Start the tour, then use "Next" in each step (or "Skip tour"). The
current step is saved in the tour's state.

</EuiText>

```hbs template
<EuiTour @initialState={{this.initialState}} @steps={{this.steps}} as |tour|>
  <EuiButton @size="s" {{on "click" tour.actions.resetTour}}>Start the tour</EuiButton>
  <EuiSpacer />
  <EuiFlexGroup @alignItems="center" @responsive={{false}}>
    <EuiFlexItem @grow={{false}}>
      <tour.Step @step={{1}} @anchorPosition="downLeft">
        <:default><EuiFieldSearch @placeholder="Search" aria-label="Search" /></:default>
        <:footerAction>
          <EuiButton @size="s" @color="success" {{on "click" tour.actions.incrementStep}}>Next</EuiButton>
        </:footerAction>
      </tour.Step>
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <tour.Step @step={{2}} @anchorPosition="downCenter">
        <:default><EuiButtonEmpty @iconType="filter">Filters</EuiButtonEmpty></:default>
        <:footerAction>
          <EuiButton @size="s" @color="success" {{on "click" tour.actions.incrementStep}}>Next</EuiButton>
        </:footerAction>
      </tour.Step>
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <tour.Step @step={{3}} @anchorPosition="rightUp">
        <EuiButton @fill={{true}} @size="s">Save</EuiButton>
      </tour.Step>
    </EuiFlexItem>
  </EuiFlexGroup>
  <EuiSpacer />
  <EuiText @size="s">
    <p>
      Step {{tour.state.currentTourStep}},
      {{if tour.state.isTourActive "running" "not running"}}
    </p>
  </EuiText>
</EuiTour>
```

```js component
import Component from '@glimmer/component';

export default class TourDemo extends Component {
  initialState = {
    currentTourStep: 1,
    isTourActive: false,
    tourPopoverWidth: 300,
    tourSubtitle: 'Demo tour',
  };

  steps = [
    { step: 1, title: 'Search', content: 'Type here to find documents by any field.' },
    { step: 2, title: 'Filters', content: 'Narrow the results down by status, owner or date.' },
    { step: 3, title: 'Save', content: 'Keep this search to come back to it later.' },
  ];
}
```
