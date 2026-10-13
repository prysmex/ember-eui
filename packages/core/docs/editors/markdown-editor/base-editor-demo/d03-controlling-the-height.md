---
order: 3
---

# Controlling the height

<EuiText>

The <EuiCode>@height</EuiCode> argument allows you to control the height of the <strong>EuiMarkdownEditor</strong>. You can set the <EuiCode>@height</EuiCode> in pixels or pass <EuiCode>"full"</EuiCode> to allow the <strong>EuiMarkdownEditor</strong> to fill the height of its container. By default, the <EuiCode>@autoExpandPreview</EuiCode> argument is set to <EuiCode>true</EuiCode>. This means that the preview height is automatically adjusted to fit all the content and avoid a scrollbar.

You can also control the <EuiCode>@maxHeight</EuiCode> of the editor/preview area. This argument only works when the <EuiCode>@height</EuiCode> is not set to <EuiCode>"full"</EuiCode>.

</EuiText>

<EuiSpacer />

```hbs template
<EuiFlexGroup>
  <EuiFlexItem>
    <EuiPanel @color='primary'>
      <EuiMarkdownEditor
        @ariaLabel='EUI markdown editor with fixed height'
        @placeholder='Your markdown here...'
        @initialViewMode='viewing'
        @value={{this.value1}}
        @onChange={{set this 'value1'}}
        @height={{200}}
      />
    </EuiPanel>
  </EuiFlexItem>
  <EuiFlexItem style='height: 600px'>
    <EuiPanel @color='primary'>
      <EuiMarkdownEditor
        @ariaLabel='EUI markdown editor with full height'
        @initialViewMode='viewing'
        @value={{this.value2}}
        @onChange={{set this 'value2'}}
        @height='full'
      />
    </EuiPanel>
  </EuiFlexItem>
</EuiFlexGroup>

<EuiSpacer />

<EuiFlexGroup>
  <EuiFlexItem>
    <EuiPanel @color='primary'>
      <EuiMarkdownEditor
        @ariaLabel='EUI markdown editor with no auto expand'
        @placeholder='Your markdown here...'
        @initialViewMode='viewing'
        @value={{this.value3}}
        @onChange={{set this 'value3'}}
        @height={{200}}
        @autoExpandPreview={{false}}
      />
    </EuiPanel>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiPanel @color='primary'>
      <EuiMarkdownEditor
        @ariaLabel='EUI markdown editor with fixed and max height'
        @placeholder='Your markdown here...'
        @initialViewMode='viewing'
        @value={{this.value4}}
        @onChange={{set this 'value4'}}
        @height={{200}}
        @maxHeight={{300}}
      />
    </EuiPanel>
  </EuiFlexItem>
</EuiFlexGroup>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class EditorHeight extends Component {
  @tracked value1 = `## 👋 Hello there!

I'm a **EuiMarkdownEditor** with:

- a \`height\` set to \`200\`
- my parent container is a flex item

### Things you should know

When my content is very long 😅

The preview height is automatically adjusted 😉

To avoid a scrollbar 😌

### That's why I look good 😍

`;

  @tracked value2 = `## 👋 Hello again!

I'm a **EuiMarkdownEditor** with:
- a \`height\` set to \`"full"\`
- my parent container is a flex item with a \`height\` set to \`600\`
`;

  @tracked value3 = `## 👋 Hi!

I'm a **EuiMarkdownEditor** with:
- a \`height\` set to \`200\`
- my parent container is a flex item.
- the \`autoExpandPreview\` is set to \`false\`

### Things you should know

When the content grows the preview height is not automatically adjusted. Just because the \`autoExpandPreview\` is set to \`false\` 😉
`;

  @tracked value4 = `## 👋 Hello again!

I'm just a **EuiMarkdownEditor** with:
- a \`height\` set to \`200\`
- a \`maxHeight\` set to \`300\`
`;
}
```
