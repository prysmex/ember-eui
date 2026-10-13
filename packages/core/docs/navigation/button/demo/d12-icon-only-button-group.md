---
order: 12
---

# Icon only button group

<EuiText>

Use the `@isIconOnly` argument when displaying a group of icon-only buttons. The option labels are still read by screen readers, so keep them descriptive.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { guidFor } from '@ember/object/internals';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiButtonGroup } from '@ember-eui/core/components';

const idPrefix3 = guidFor({});

export default class DemoComponent extends Component {
  @tracked toggleIconIdSelected = `${idPrefix3}1`;
  @tracked toggleIconIdToSelectedMap = {};

  toggleButtonsIcons = [
    { id: `${idPrefix3}0`, label: 'Align left', iconType: 'textAlignLeft' },
    { id: `${idPrefix3}1`, label: 'Align center', iconType: 'textAlignCenter' },
    { id: `${idPrefix3}2`, label: 'Align right', iconType: 'textAlignRight', isDisabled: true }
  ];

  toggleButtonsIconsMulti = [
    { id: `${idPrefix3}3`, label: 'Bold', name: 'bold', iconType: 'textBold' },
    { id: `${idPrefix3}4`, label: 'Italic', name: 'italic', iconType: 'textItalic', isDisabled: true },
    { id: `${idPrefix3}5`, label: 'Underline', name: 'underline', iconType: 'textUnderline' },
    { id: `${idPrefix3}6`, label: 'Strikethrough', name: 'strikethrough', iconType: 'textStrike' }
  ];

  @action
  onChangeIcons(optionId) {
    this.toggleIconIdSelected = optionId;
  }

  @action
  onChangeIconsMulti(optionId) {
    this.toggleIconIdToSelectedMap = {
      ...this.toggleIconIdToSelectedMap,
      [optionId]: !this.toggleIconIdToSelectedMap[optionId]
    };
  }

  <template>
    <EuiButtonGroup
      @legend="Text align"
      @options={{this.toggleButtonsIcons}}
      @idSelected={{this.toggleIconIdSelected}}
      @onChange={{this.onChangeIcons}}
      @isIconOnly={{true}}
    />
    &nbsp;&nbsp;
    <EuiButtonGroup
      @legend="Text style"
      @options={{this.toggleButtonsIconsMulti}}
      @idToSelectedMap={{this.toggleIconIdToSelectedMap}}
      @onChange={{this.onChangeIconsMulti}}
      @type="multi"
      @isIconOnly={{true}}
    />
  </template>
}
```
