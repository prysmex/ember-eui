---
order: 7
---

# Checkable cards as a radio group

<EuiCallOut @color="primary" @iconType="accessibility" @size="s" @title="Accessibility requirement">
  <p>When used as a radio group, you must provide a <code>EuiFormFieldset</code> with a legend for accessibility.</p>
</EuiCallOut>
<EuiSpacer />

```hbs template
<EuiFormFieldset>
  <:legend>
    <EuiTitle @size="xs"><span>Checkable card radio group with legend</span></EuiTitle>
  </:legend>

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
</EuiFormFieldset>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

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
}
```
