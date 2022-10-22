---
order: 11
---

# Icon only button groups

```hbs template
<EuiButtonGroup
  @legend='Text align'
  @options={{this.toggleButtonsIcons}}
  @idSelected={{this.toggleIconIdSelected}}
  @onChange={{set this 'toggleIconIdSelected'}}
  @isIconOnly={{true}}
/>
<EuiButtonGroup
  @legend='Text style'
  @options={{this.toggleButtonsIconsMulti}}
  @idToSelectedMap={{this.toggleIdToSelectedMap}}
  @onChange={{this.onChangeMulti}}
  @type='multi'
  @isIconOnly={{true}}
/>
```

```js component
import Component from '@glimmer/component';
import { guidFor } from '@ember/object/internals';
import { tracked } from '@glimmer/tracking';

const idPrefix3 = guidFor({});
export default class extends Component {
  @tracked toggleIconIdSelected = `${idPrefix3}1`;
  @tracked toggleIdToSelectedMap = {};

  toggleButtonsIcons = [
    {
      id: `${idPrefix3}0`,
      label: 'Align left',
      iconType: 'editorAlignLeft'
    },
    {
      id: `${idPrefix3}1`,
      label: 'Align center',
      iconType: 'editorAlignCenter'
    },
    {
      id: `${idPrefix3}2`,
      label: 'Align right',
      iconType: 'editorAlignRight',
      isDisabled: true
    }
  ];

  toggleButtonsIconsMulti = [
    {
      id: `${idPrefix3}3`,
      label: 'Bold',
      name: 'bold',
      iconType: 'editorBold'
    },
    {
      id: `${idPrefix3}4`,
      label: 'Italic',
      name: 'italic',
      iconType: 'editorItalic',
      isDisabled: true
    },
    {
      id: `${idPrefix3}5`,
      label: 'Underline',
      name: 'underline',
      iconType: 'editorUnderline'
    },
    {
      id: `${idPrefix3}6`,
      label: 'Strikethrough',
      name: 'strikethrough',
      iconType: 'editorStrike'
    }
  ];

  onChangeMulti = (optionId) => {
    const newToggleIdToSelectedMap = {
      ...this.toggleIdToSelectedMap,
      ...{
        [optionId]: !this.toggleIdToSelectedMap[optionId]
      }
    };
    this.toggleIdToSelectedMap = newToggleIdToSelectedMap;
  };
}
```
