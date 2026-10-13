---
order: 7
---

# Checkable cards as a radio group

<EuiCallOut @color="primary" @iconType="accessibility" @size="s" @title="Accessibility requirement">
  <p>When used as a radio group, you must provide a <code>EuiFormFieldset</code> with a legend for accessibility.</p>
</EuiCallOut>
<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiCheckableCard, EuiFormFieldset, EuiRadioGroup, EuiSpacer, EuiTitle } from '@ember-eui/core/components';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { eq, not } from 'ember-truth-helpers';

export default class CardRadioGroupDemo extends Component {
  @tracked radio = 'radio2';
  @tracked nestedRadio = 'nestedRadio1';

  nestedRadios = [
    { id: 'nestedRadio1', label: 'Nested option one' },
    { id: 'nestedRadio2', label: 'Nested option two' },
    { id: 'nestedRadio3', label: 'Nested option three' },
  ];

  @action setRadio(value) {
    this.radio = value;
  }

  @action setNestedRadio(id) {
    this.nestedRadio = id;
  }

  <template>
    <EuiFormFieldset>
      <:legend>
        <EuiTitle @size="xs"><span>Checkable card radio group with legend</span></EuiTitle>
      </:legend>

      <:fieldset>
      <EuiCheckableCard
        @label="Option one"
        name="checkableCardRadioGroup"
        value="radio1"
        @checked={{eq this.radio "radio1"}}
        {{on "change" (fn this.setRadio "radio1")}}
      />

      <EuiSpacer @size="m" />

      <EuiCheckableCard
        @label="Option two"
        name="checkableCardRadioGroup"
        value="radio2"
        @checked={{eq this.radio "radio2"}}
        {{on "change" (fn this.setRadio "radio2")}}
      >
        <:content>
          <EuiRadioGroup
            @options={{this.nestedRadios}}
            @idSelected={{this.nestedRadio}}
            @onChange={{this.setNestedRadio}}
            @disabled={{not (eq this.radio "radio2")}}
          />
        </:content>
      </EuiCheckableCard>

      <EuiSpacer @size="m" />

      <EuiCheckableCard
        @label="Option three (disabled)"
        name="checkableCardRadioGroup"
        value="radio3"
        @checked={{eq this.radio "radio3"}}
        @disabled={{true}}
        {{on "change" (fn this.setRadio "radio3")}}
      />
      </:fieldset>
    </EuiFormFieldset>
  </template>
}
```

