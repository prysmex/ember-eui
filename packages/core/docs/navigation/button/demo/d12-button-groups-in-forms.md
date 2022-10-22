---
order: 12
---

# Button groups in forms

<EuiText>
<p>When using button groups within compressed forms, match the form elements by adding <EuiCode>buttonSize="compressed"</EuiCode>. Compressed groups should always be <EuiCode>fullWidth</EuiCode> so they line up nicely in their small container <strong>unless</strong> they are icon only.
</p>

</EuiText>

```hbs template
<EuiPanel @hasBorder={{true}} style='max-width: 300px'>
  <EuiButtonGroup
    @name='coarsness'
    @legend='This is a basic group'
    @options={{this.toggleButtonsCompressed}}
    @idSelected={{this.toggleCompressedIdSelected}}
    @onChange={{set this 'toggleCompressedIdSelected'}}
    @buttonSize='compressed'
    @isFullWidth={{true}}
  />
  <EuiSpacer />
  <EuiButtonGroup
    @legend='Text style'
    class='eui-displayInlineBlock'
    @options={{this.toggleButtonsIconsMulti}}
    @idToSelectedMap={{this.toggleIconIdToSelectedMapIcon}}
    @onChange={{this.onChangeMulti}}
    @type='multi'
    @buttonSize='compressed'
    @isIconOnly={{true}}
  />
</EuiPanel>
```

```js component
import Component from '@glimmer/component';
import { guidFor } from '@ember/object/internals';
import { tracked } from '@glimmer/tracking';

const idPrefix3 = guidFor({});
export default class extends Component {
  @tracked toggleCompressedIdSelected = `${idPrefix3}__1`;
  @tracked toggleIconIdToSelectedMapIcon = {};

  toggleButtonsCompressed = [
    {
      id: `${idPrefix3}__0`,
      label: 'fine'
    },
    {
      id: `${idPrefix3}__1`,
      label: 'rough'
    },
    {
      id: `${idPrefix3}__2`,
      label: 'coarse'
    }
  ];

  toggleButtonsIconsMulti = [
    {
      id: `${idPrefix3}__multi__0`,
      label: 'Bold',
      name: 'bold',
      iconType: 'editorBold'
    },
    {
      id: `${idPrefix3}__multi__1`,
      label: 'Italic',
      name: 'italic',
      iconType: 'editorItalic',
      isDisabled: true
    },
    {
      id: `${idPrefix3}__multi__2`,
      label: 'Underline',
      name: 'underline',
      iconType: 'editorUnderline'
    },
    {
      id: `${idPrefix3}__multi__3`,
      label: 'Strikethrough',
      name: 'strikethrough',
      iconType: 'editorStrike'
    }
  ];

  onChangeMulti = (optionId) => {
    const newtoggleIconIdToSelectedMapIcon = {
      ...this.toggleIconIdToSelectedMapIcon,
      ...{
        [optionId]: !this.toggleIconIdToSelectedMapIcon[optionId]
      }
    };
    this.toggleIconIdToSelectedMapIcon = newtoggleIconIdToSelectedMapIcon;
  };
}
```
