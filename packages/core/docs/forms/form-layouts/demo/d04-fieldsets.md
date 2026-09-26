---
order: 4
---

# Fieldsets

<EuiText>

Group controls that answer one question, like a set of radios, in an
`EuiFormFieldset` with a `@legend`: screen readers announce the legend with
each option. Inside an `EuiFormRow`, use `@labelType="legend"` and
`@legendType="legend"` to get the same structure.

</EuiText>

```hbs template
<EuiFormFieldset @legend="Notifications">
  <EuiRadioGroup
    @options={{this.options}}
    @idSelected={{this.selected}}
    @name="notifications"
    @onChange={{this.select}}
  />
</EuiFormFieldset>

<EuiSpacer />

<EuiFormRow @label="Theme" @labelType="legend" @legendType="legend">
  <EuiRadioGroup
    @options={{this.themes}}
    @idSelected={{this.theme}}
    @name="theme"
    @onChange={{this.selectTheme}}
  />
</EuiFormRow>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class FieldsetDemo extends Component {
  @tracked selected = 'mentions';
  @tracked theme = 'light';

  options = [
    { id: 'all', label: 'Every activity' },
    { id: 'mentions', label: 'Mentions only' },
    { id: 'none', label: 'Nothing' },
  ];

  themes = [
    { id: 'light', label: 'Light' },
    { id: 'dark', label: 'Dark' },
  ];

  @action
  select(id) {
    this.selected = id;
  }

  @action
  selectTheme(id) {
    this.theme = id;
  }
}
```
