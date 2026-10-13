---
order: 9
---

# Tooltips

<EuiText>

If you have longer information that you need to make available to users outside of truncated text, one approach could be adding tooltip descriptions to individual options by passing `toolTipContent`.

You can additionally customize individual tooltip behavior by passing `toolTipProps`, which accepts most arguments that `EuiToolTip` accepts (`position`, `delay`, `title`, `offset`, …).

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiSelectable } from '@ember-eui/core/components';

export default class SelectableTooltipsDemo extends Component {
  @tracked options = [
    {
      label: 'Titan',
      toolTipContent: 'Titan is the largest moon of Saturn and the second-largest in the Solar System',
    },
    {
      label: 'Pandora',
      toolTipContent: "Pandora is one of Saturn's moons, named for a Titaness of Greek mythology",
    },
    {
      label: 'Iapetus',
      toolTipContent: "Iapetus is the outermost of Saturn's large moons",
      toolTipProps: { position: 'bottom' },
    },
  ];

  @action
  setOptions(options) {
    this.options = options;
  }

  <template>
    <EuiSelectable
      aria-label="Example with option tooltips"
      @options={{this.options}}
      @onChange={{this.setOptions}}
      as |parts|
    >
      <parts.list style="max-inline-size: 400px" />
    </EuiSelectable>
  </template>
}
```
