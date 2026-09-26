---
order: 3
---

# Compressed and column layouts

<EuiText>

For dense forms, such as settings in a side panel, use
`@display="rowCompressed"` (smaller rows) or `@display="columnCompressed"`
(label beside the control), and `@compressed={{true}}` on the controls.
`columnCompressedSwitch` aligns an `EuiSwitch` in a column layout.

</EuiText>

```hbs template
<EuiPanel @hasBorder={{true}} style="max-width: 400px;">
  <EuiForm>
    <EuiFormRow @label="Title" @display="columnCompressed">
      <EuiFieldText @compressed={{true}} @value="Revenue" />
    </EuiFormRow>
    <EuiFormRow @label="Chart" @display="columnCompressed">
      <EuiSelect
        @compressed={{true}}
        @options={{this.charts}}
        @value="bar"
      />
    </EuiFormRow>
    <EuiFormRow @label="Opacity" @display="columnCompressed">
      <EuiRange @compressed={{true}} @value={{80}} @showInput={{true}} />
    </EuiFormRow>
    <EuiFormRow @label="Show legend" @display="columnCompressedSwitch">
      <EuiSwitch
        @label="Show legend"
        @showLabel={{false}}
        @compressed={{true}}
        @checked={{this.legend}}
        @onChange={{this.toggleLegend}}
      />
    </EuiFormRow>
  </EuiForm>
</EuiPanel>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class CompressedFormDemo extends Component {
  @tracked legend = true;

  charts = [
    { value: 'bar', text: 'Bar' },
    { value: 'line', text: 'Line' },
    { value: 'area', text: 'Area' },
  ];

  @action
  toggleLegend(event) {
    this.legend = event.target.checked;
  }
}
```
