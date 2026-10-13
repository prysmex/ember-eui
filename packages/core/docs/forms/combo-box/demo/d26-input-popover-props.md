---
order: 26
---

# Options list popover props

<EuiText>

`@inputPopoverProps` customizes the options list like upstream's
`inputPopoverProps`. The list closes when the page (or a container of the
combo box) scrolls, as upstream; pass `closeOnScroll=false` to keep it open.
`offset` moves it away from the input, `buffer` and `container` keep it
within bounds, `onPanelResize` reports its width, and other keys
(`className`, `data-test-subj`, …) go on the combo box root.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { hash } from '@ember/helper';
import { EuiCode, EuiComboBox, EuiSpacer, EuiText } from '@ember-eui/core/components';

const OPTIONS = [
  { label: 'Titan' },
  { label: 'Enceladus' },
  { label: 'Mimas' },
  { label: 'Dione' },
  { label: 'Iapetus' }
];

export default class ComboBoxInputPopoverPropsDemo extends Component {
  @tracked selectedOptions = [];
  @tracked panelWidth = 0;

  @action
  onChange(selectedOptions) {
    this.selectedOptions = selectedOptions;
  }

  @action
  onPanelResize(width) {
    this.panelWidth = width;
  }

  <template>
    <EuiComboBox
      @placeholder="Stays open on scroll, 8px below the input"
      @options={{OPTIONS}}
      @selectedOptions={{this.selectedOptions}}
      @onChange={{this.onChange}}
      @inputPopoverProps={{hash
        closeOnScroll=false
        offset=8
        panelMinWidth=320
        onPanelResize=this.onPanelResize
        data-test-subj="moonsComboBox"
      }}
      as |option|
    >
      {{option.label}}
    </EuiComboBox>
    <EuiSpacer @size="s" />
    <EuiText @size="s">
      List width: <EuiCode>{{this.panelWidth}}px</EuiCode>
    </EuiText>
  </template>
}
```
