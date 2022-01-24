---
order: 1
---

# Demo

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
import { visit } from '@ember-eui/core/utils/markdown/plugins/markdown-add-components';
import { defaultProcessingPlugins } from '@ember-eui/core/utils/markdown/plugins/markdown-default-plugins';


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

\`\`\`golang
package main

import \"fmt\"

func main() {

	// \`var\` declares 1 or more variables.
	var a = "initial"
	fmt.Println(a)

	// You can declare multiple variables at once.
	var b, c int = 1, 2
	fmt.Println(b, c)

	// Go will infer the type of initialized variables.
	var d = true
	fmt.Println(d)

	// Variables declared without a corresponding
	// initialization are _zero-valued_. For example, the
	// zero value for an \`int\` is \`0\`.
	var e int
	fmt.Println(e)

	// The \`:=\` syntax is shorthand for declaring and
	// initializing a variable, e.g. for
	// \`var f string = "apple"\` in this case.
	f := "apple"
	fmt.Println(f)
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
