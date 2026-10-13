---
order: 14
---

# Button group in forms

<EuiText>

When using button groups within compressed forms, match the form elements by adding `@buttonSize="compressed"`. Compressed groups should always be `@isFullWidth` so they line up nicely in their small container unless they are icon only.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { guidFor } from '@ember/object/internals';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiButtonGroup, EuiPanel, EuiSpacer } from '@ember-eui/core/components';

const compressedToggleButtonGroupPrefix = guidFor({});
const multiSelectButtonGroupPrefix = guidFor({});

export default class DemoComponent extends Component {
  @tracked toggleCompressedIdSelected = `${compressedToggleButtonGroupPrefix}__1`;
  @tracked toggleIconIdToSelectedMapIcon = {};

  toggleButtonsCompressed = [
    { id: `${compressedToggleButtonGroupPrefix}__0`, label: 'fine' },
    { id: `${compressedToggleButtonGroupPrefix}__1`, label: 'rough' },
    { id: `${compressedToggleButtonGroupPrefix}__2`, label: 'coarse' }
  ];

  toggleButtonsIconsMulti = [
    { id: `${multiSelectButtonGroupPrefix}__0`, label: 'Bold', name: 'bold', iconType: 'textBold' },
    { id: `${multiSelectButtonGroupPrefix}__1`, label: 'Italic', name: 'italic', iconType: 'textItalic', isDisabled: true },
    { id: `${multiSelectButtonGroupPrefix}__2`, label: 'Underline', name: 'underline', iconType: 'textUnderline' },
    { id: `${multiSelectButtonGroupPrefix}__3`, label: 'Strikethrough', name: 'strikethrough', iconType: 'textStrike' }
  ];

  @action
  onChangeCompressed(optionId) {
    this.toggleCompressedIdSelected = optionId;
  }

  @action
  onChangeIconsMultiIcons(optionId) {
    this.toggleIconIdToSelectedMapIcon = {
      ...this.toggleIconIdToSelectedMapIcon,
      [optionId]: !this.toggleIconIdToSelectedMapIcon[optionId]
    };
  }

  <template>
    <EuiPanel @hasBorder={{true}} style="max-width: 300px">
      <EuiButtonGroup
        @name="coarsness"
        @legend="This is a basic group"
        @options={{this.toggleButtonsCompressed}}
        @idSelected={{this.toggleCompressedIdSelected}}
        @onChange={{this.onChangeCompressed}}
        @buttonSize="compressed"
        @isFullWidth={{true}}
      />
      <EuiSpacer />
      <EuiButtonGroup
        @legend="Text style"
        class="eui-displayInlineBlock"
        @options={{this.toggleButtonsIconsMulti}}
        @idToSelectedMap={{this.toggleIconIdToSelectedMapIcon}}
        @onChange={{this.onChangeIconsMultiIcons}}
        @type="multi"
        @buttonSize="compressed"
        @isIconOnly={{true}}
      />
    </EuiPanel>
  </template>
}
```
