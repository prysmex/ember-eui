---
order: 2
---

# Fixed to the window

<EuiText>

The default position: the bar sits at the bottom of the window until
closed. Screen readers are told a new region appeared.

</EuiText>

```hbs template
<EuiButton {{on "click" this.toggle}}>
  {{if this.isShown "Hide" "Show"}} the control bar
</EuiButton>
{{#if this.isShown}}
  <EuiControlBar @controls={{this.controls}} @landmarkHeading="Demo controls" />
{{/if}}
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class FixedControlBar extends Component {
  @tracked isShown = false;

  get controls() {
    return [
      { controlType: 'icon', id: 'logo', iconType: 'logoElastic', 'aria-label': 'Elastic' },
      { controlType: 'text', id: 'title', text: 'Fixed control bar' },
      { controlType: 'spacer' },
      {
        controlType: 'icon',
        id: 'close',
        iconType: 'cross',
        'aria-label': 'Close the control bar',
        onClick: () => (this.isShown = false),
      },
    ];
  }

  @action
  toggle() {
    this.isShown = !this.isShown;
  }
}
```
