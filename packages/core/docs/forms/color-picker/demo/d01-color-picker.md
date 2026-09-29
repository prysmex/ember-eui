---
order: 1
---

# Color picker

<EuiText>

Type a color or pick one. `isValid` is false while the text is not a
color: the row shows an error then.

</EuiText>

```hbs template
<EuiFormRow
  @label="Pick a color"
  @isInvalid={{this.isInvalid}}
  @error="Not a valid color"
>
  <EuiColorPicker
    @color={{this.color}}
    @onChange={{this.setColor}}
    @isInvalid={{this.isInvalid}}
  />
</EuiFormRow>
<EuiSpacer />
<EuiBadge @color={{if this.isInvalid "hollow" this.color}}>{{this.color}}</EuiBadge>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class ColorPickerDemo extends Component {
  @tracked color = '#D36086';
  @tracked isInvalid = false;

  @action
  setColor(text, { isValid }) {
    this.color = text;
    this.isInvalid = Boolean(text) && !isValid;
  }
}
```
