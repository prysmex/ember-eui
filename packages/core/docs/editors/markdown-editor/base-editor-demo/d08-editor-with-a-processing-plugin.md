---
order: 1
---

# Editor with a processing plugin

<EuiText>

The editor with the default plugins plus a processing plugin that opens
every link in a new tab: it visits the rendered tree and sets
`target="_blank"` on `<a>` elements. Switch to the preview to see the
result; the task list checkboxes are clickable there.

</EuiText>

```hbs template
<EuiMarkdownEditor
  @value={{this.value}}
  @onChange={{set this 'value'}}
  @processingPluginList={{this.processingPlugins}}
/>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { visit } from '@ember-eui/core/utils/markdown/plugins/markdown-add-components/processor';
import EuiAccordion from '@ember-eui/core/components/eui-accordion';
import { defaultProcessingPlugins } from '@ember-eui/core/utils/markdown/plugins/markdown-default-plugins/processing-plugins';

/*
 Quick example how you can extend plugins, this plugin adds _blank to `a` elements
*/
function TargetBlankProcessingPlugin() {
  return (tree) => {
    visit(tree, (node) => {
      if (node.type === 'element' && node.tagName === 'a') {
        node.properties.target = '_blank';
      }
      return node;
    });
  };
}

const processingPlugins = [
  ...defaultProcessingPlugins,
  [TargetBlankProcessingPlugin, {}]
];

export default class EuiMarkdownEditor1 extends Component {
  processingPlugins = processingPlugins;
  @tracked value = `## 👋 Hello there!

I'm a **EuiMarkdownEditor** with:

- a \`height\` set to \`200\`
- my parent container is a flex item


### Things you should know

When my content is very long 😅

The preview height is automatically adjusted 😉

To avoid a scrollbar 😌

### That's why I look good 😍

- [ ] First Checkbox
- [ ] Second Checkbox
- [x] Third Checkbox

\`\`\`ts
class Human {
   get fullName() {
     return \`${this.name} ${this.lastName}\`;
   }
}
\`\`\`

\`\`\`tsx
import Component from '@glimmer/component';
import { helper } from '@ember/component/helper';
import { tracked } from '@glimmer/tracking';

export default class SomeComponent extends Component {
	@tracked count = 0;

	add = helper(function([a, b]: [number, number]) {
		return a + b;
	});
}

\`\`\`

----

### You can also add tooltips if you want more explanation!

!{tooltip[You can also add tooltips](Some helpful description)}

### And links, check the demo source in how to tweak plugins!

[Access Google!](https://google.com)

`;
}
```
