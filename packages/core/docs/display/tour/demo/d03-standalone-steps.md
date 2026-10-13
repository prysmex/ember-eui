---
order: 3
---

# Standalone steps

<EuiText>

Each `EuiTourStep` can be configured independently via arguments. In this case, each component is stateless and needs to be paired with some form of state management for navigation. The later examples showcase another way to handle state management via `EuiTour`.

</EuiText>

```hbs template
<div>
  <EuiButtonEmpty @size='s' @iconType='refresh' @flush='left' {{on 'click' this.resetTour}}>
    Begin tour
  </EuiButtonEmpty>
  <EuiSpacer @size='m' />
  <EuiForm @component='form'>
    <EuiFormRow @label='Query'>
      <EuiTourStep
        @isStepOpen={{this.isStepOneOpen}}
        @minWidth={{360}}
        @onFinish={{this.finishTour}}
        @closePopover={{this.finishTour}}
        @step={{1}}
        @stepsTotal={{2}}
        @subtitle='Demo tour'
        @title='Step 1'
        @anchorPosition='rightUp'
      >
        <:default>
          <EuiTextArea
            @value={{this.queryValue}}
            placeholder='Placeholder text'
            aria-label='Query'
            style='width: 400px'
            {{on 'input' this.onChange}}
          />
        </:default>
        <:content>
          <EuiText @size='s'>
            <p>Copy and paste this sample query.</p>
            <EuiCodeBlock @language='html' @paddingSize='s' @isCopyable={{true}}>SELECT email FROM "kibana_sample_data_ecommerce"</EuiCodeBlock>
          </EuiText>
        </:content>
      </EuiTourStep>
    </EuiFormRow>

    <EuiSpacer @size='m' />

    <EuiTourStep
      @isStepOpen={{this.isStepTwoOpen}}
      @minWidth={{360}}
      @onFinish={{this.finishTour}}
      @closePopover={{this.finishTour}}
      @step={{2}}
      @stepsTotal={{2}}
      @subtitle='Demo tour'
      @title='Step 2'
      @anchorPosition='rightUp'
    >
      <:default>
        <EuiButton @fill={{true}} @size='s' {{on 'click' this.save}}>Save</EuiButton>
      </:default>
      <:content>
        <EuiText @size='s'><p>Save your changes.</p></EuiText>
      </:content>
    </EuiTourStep>
  </EuiForm>
</div>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class extends Component {
  @tracked currentTourStep = 1;
  @tracked isTourActive = false;
  @tracked queryValue = '';

  get isStepOneOpen() {
    return this.currentTourStep === 1 && this.isTourActive;
  }

  get isStepTwoOpen() {
    return this.currentTourStep === 2 && this.isTourActive;
  }

  @action
  resetTour() {
    this.currentTourStep = 1;
    this.isTourActive = true;
    this.queryValue = '';
  }

  @action
  finishTour() {
    this.isTourActive = false;
  }

  @action
  save() {
    if (this.currentTourStep < 2) this.currentTourStep++;
  }

  @action
  onChange(event) {
    this.queryValue = event.target.value;

    if (this.currentTourStep < 2) this.currentTourStep++;
  }
}
```
