---
order: 6
---

# Anchor to DOM element

<EuiText>

Instead of wrapping the target element, use the `@anchor` argument to specify a DOM node. Accepted values include an HTML element, a function returning an HTML element, or a CSS selector string such as `@anchor="#anchorTarget"`. The step appears once the element is found.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { on } from '@ember/modifier';
import { EuiButton, EuiButtonEmpty, EuiCode, EuiSpacer, EuiText, EuiTourStep } from '@ember-eui/core/components';

export default class extends Component {
  @tracked isOpenRef = false;
  @tracked isOpenSelector = false;
  anchorElement = null;

  @action
  setAnchor(element) {
    this.anchorElement = element;
  }

  @action
  getAnchor() {
    return this.anchorElement;
  }

  @action
  beginRef() {
    this.isOpenRef = true;
    this.isOpenSelector = false;
  }

  @action
  beginSelector() {
    this.isOpenSelector = true;
    this.isOpenRef = false;
  }

  @action
  finishRef() {
    this.isOpenRef = false;
  }

  @action
  finishSelector() {
    this.isOpenSelector = false;
  }

  <template>
    <div>
      <EuiButtonEmpty @size='s' @flush='left' @iconType='refresh' {{on 'click' this.beginRef}}>
        Begin tour
      </EuiButtonEmpty>
      <EuiSpacer @size='m' />
      <EuiTourStep
        @anchor={{this.getAnchor}}
        @isStepOpen={{this.isOpenRef}}
        @minWidth={{300}}
        @onFinish={{this.finishRef}}
        @step={{1}}
        @stepsTotal={{1}}
        @title='Element reference as anchor location'
        @anchorPosition='rightCenter'
        @zIndex={{1}}
      >
        <:content>
          <EuiText @size='s'>
            <p>Popover is attached to the <EuiCode @language='text'>anchorElement</EuiCode> button</p>
          </EuiText>
        </:content>
      </EuiTourStep>
      <span {{didInsert this.setAnchor}}>
        <EuiButton @color='text' aria-label='Anchor'>Anchor to <strong>an element</strong></EuiButton>
      </span>

      <EuiSpacer @size='xxl' />

      <EuiButtonEmpty @size='s' @flush='left' @iconType='refresh' {{on 'click' this.beginSelector}}>
        Begin tour
      </EuiButtonEmpty>
      <EuiSpacer @size='m' />
      <EuiTourStep
        @anchor='#anchorTarget'
        @isStepOpen={{this.isOpenSelector}}
        @minWidth={{300}}
        @onFinish={{this.finishSelector}}
        @step={{1}}
        @stepsTotal={{1}}
        @title='DOM selector as anchor location'
        @anchorPosition='rightDown'
        @zIndex={{1}}
      >
        <:content>
          <EuiText @size='s'>
            <p>Popover is attached to the <EuiCode @language='text'>#anchorTarget</EuiCode> button</p>
          </EuiText>
        </:content>
      </EuiTourStep>
      <EuiButton @color='text' aria-label='Anchor' id='anchorTarget'>Anchor to <strong>id</strong></EuiButton>
    </div>
  </template>
}
```
