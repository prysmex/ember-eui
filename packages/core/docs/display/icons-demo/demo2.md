---
order: 2
---

# Editor controls

<EuiText>
 <p>Editor icons relate to the visual styling of elements and are commonly used within <strong>EuiButtonGroup</strong> components.</p>
</EuiText>

```hbs template
<EuiFlexGrid @columns={{3}}>
  {{#each this.editor as |icon|}}
    <EuiFlexItem>
      <EuiCopy
        @textToCopy={{icon}}
        @beforeMessage='Click to Copy'
        @afterMessage='Copied'
        as |copy|
      >
        <EuiPanel
          @paddingSize='s'
          @hasShadow={{false}}
          @onClick={{copy}}
        >
          <EuiIcon @type='{{icon}}' />
          <small>
            {{icon}}
          </small>
        </EuiPanel>
      </EuiCopy>
    </EuiFlexItem>
  {{/each}}
</EuiFlexGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { typeToPathMap } from '@ember-eui/core/utils/css-mappings/eui-icon';

const iconKeys = Object.keys(typeToPathMap);

export default class DemoIconComponent extends Component {
  @tracked editor = [
    'editorAlignCenter',
    'editorAlignLeft',
    'editorAlignRight',
    'editorBold',
    'editorCodeBlock',
    'editorComment',
    'editorDistributeHorizontal',
    'editorDistributeVertical',
    'editorHeading',
    'editorItalic',
    'editorItemAlignBottom',
    'editorItemAlignCenter',
    'editorItemAlignLeft',
    'editorItemAlignMiddle',
    'editorItemAlignRight',
    'editorItemAlignTop',
    'editorLink',
    'editorOrderedList',
    'editorPositionBottomLeft',
    'editorPositionBottomRight',
    'editorPositionTopLeft',
    'editorPositionTopRight',
    'editorRedo',
    'editorStrike',
    'editorTable',
    'editorUnderline',
    'editorUndo',
    'editorUnorderedList'
  ];
}
```
