---
order: 8
---

# Inline

<EuiText>

Available only in `EuiColorPicker`. Set the `@display` argument to `inline` to display the color picker without an input or popover. Note that the `<:button>` block will be ignored in this case.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiColorPicker } from '@ember-eui/core/components';

export default class ColorPickerInlineDemo extends Component {
  @tracked color = '#D36086';
  @tracked colorErrors = null;

  @action
  setColor(text, { isValid }) {
    this.color = text;
    this.colorErrors = isValid || text === '' ? null : 'Enter a valid color';
  }

  <template>
    <EuiColorPicker
      @onChange={{this.setColor}}
      @color={{this.color}}
      @isInvalid={{this.colorErrors}}
      @display="inline"
    />
  </template>
}
```
