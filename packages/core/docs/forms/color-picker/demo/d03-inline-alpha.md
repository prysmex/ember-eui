---
order: 3
---

# Inline, with opacity

<EuiText>

`@display="inline"` renders the picker without a field or popover.
`@showAlpha` adds the opacity slider; with an `r, g, b` color the output
stays in that format (with the alpha channel when below 100%), and
`@secondaryInputDisplay="bottom"` shows the value in a field below.

</EuiText>

```hbs template
<EuiFlexGroup @alignItems="flexStart">
  <EuiFlexItem @grow={{false}}>
    <EuiColorPicker
      @display="inline"
      @showAlpha={{true}}
      @secondaryInputDisplay="bottom"
      @isClearable={{true}}
      @color={{this.color}}
      @onChange={{this.setColor}}
    />
  </EuiFlexItem>
  <EuiFlexItem>
    <div style="height: 120px; border-radius: 6px; background: rgba({{this.color}});"></div>
    <EuiSpacer @size="s" />
    <EuiText @size="s"><code>rgba({{this.color}})</code></EuiText>
  </EuiFlexItem>
</EuiFlexGroup>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class InlineColorPicker extends Component {
  @tracked color = '96, 146, 192, 0.8';

  @action
  setColor(text) {
    this.color = text;
  }
}
```
